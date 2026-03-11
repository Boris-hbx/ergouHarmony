import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { LLMClient, StreamCallback } from './LLMClient'
import { ErgouPrompt } from './ErgouPrompt'
import { ToolRegistry } from '../tool/ToolRegistry'
import { GetDateTimeTool } from '../tool/GetDateTimeTool'
import { SimpleCalculateTool } from '../tool/SimpleCalculateTool'
import { SaveMemoryTool } from '../tool/SaveMemoryTool'
import { SearchMemoryTool } from '../tool/SearchMemoryTool'
import { SessionDao } from '../data/SessionDao'
import { MessageDao } from '../data/MessageDao'
import { MemoryDao } from '../data/MemoryDao'
import { ChatMessage } from '../model/ChatModels'
import { ChatRequest, LLMMessage, ToolCall } from '../model/LLMModels'
import { PromptSanitizer } from '../common/PromptSanitizer'

const TAG = Constants.TAG_CHAT
const MAX_TOOL_ROUNDS = 5

// ChatService 回调
export interface ChatCallback {
  onStreamContent(content: string): void
  onStreamDone(fullContent: string): void
  onToolExecuting(toolName: string): void
  onError(error: string): void
}

export class ChatService {
  private llmClient: LLMClient = new LLMClient()
  private toolRegistry: ToolRegistry = new ToolRegistry()
  private sessionDao: SessionDao = new SessionDao()
  private messageDao: MessageDao = new MessageDao()
  private memoryDao: MemoryDao = new MemoryDao()
  private saveMemoryTool: SaveMemoryTool = new SaveMemoryTool()

  constructor() {
    // 注册首期工具
    this.toolRegistry.register(new GetDateTimeTool())
    this.toolRegistry.register(new SimpleCalculateTool())
    this.toolRegistry.register(this.saveMemoryTool)
    this.toolRegistry.register(new SearchMemoryTool())
  }

  async sendMessage(sessionId: number, userContent: string, callback: ChatCallback): Promise<void> {
    // 更新工具的 sessionId
    this.saveMemoryTool.setSessionId(sessionId)

    // 1. 净化用户输入
    const sanitized = PromptSanitizer.sanitize(userContent)

    // 2. 保存用户消息
    await this.messageDao.create({
      sessionId: sessionId,
      role: 'user',
      content: sanitized,
      createdAt: Date.now()
    })
    await this.sessionDao.incrementMessageCount(sessionId)

    // 3. 加载历史消息
    const historyMessages = await this.messageDao.getBySessionId(sessionId, Constants.LLM_CONTEXT_MESSAGES)

    // 4. 检索相关记忆
    const memories = await this.memoryDao.getRecent(5)
    const memoryTexts = memories.map(m => m.content)

    // 5. 组装 LLM 消息
    const systemPrompt = ErgouPrompt.buildSystemPrompt() + ErgouPrompt.buildMemoryContext(memoryTexts)
    const llmMessages = this.buildLLMMessages(systemPrompt, historyMessages)

    // 6. 开始对话循环（可能有多轮工具调用）
    await this.chatLoop(sessionId, llmMessages, callback, 0)
  }

  async createSession(title?: string): Promise<number> {
    const sessionTitle = title || '新对话'
    return await this.sessionDao.create(sessionTitle)
  }

  async updateSessionTitle(sessionId: number, firstMessage: string): Promise<void> {
    // 用第一条消息的前 20 个字符作为标题
    const title = firstMessage.length > 20 ? firstMessage.substring(0, 20) + '...' : firstMessage
    await this.sessionDao.updateTitle(sessionId, title)
  }

  abort(): void {
    this.llmClient.abort()
  }

  private async chatLoop(
    sessionId: number,
    llmMessages: LLMMessage[],
    callback: ChatCallback,
    round: number
  ): Promise<void> {
    if (round >= MAX_TOOL_ROUNDS) {
      Logger.warn(TAG, `工具调用轮次达到上限 round=${round}`)
      callback.onError('工具调用轮次过多')
      return
    }

    const request: ChatRequest = {
      model: Constants.DEEPSEEK_MODEL,
      messages: llmMessages,
      stream: true,
      temperature: Constants.LLM_TEMPERATURE,
      max_tokens: Constants.LLM_MAX_TOKENS,
      tools: this.toolRegistry.getAllDefinitions()
    }

    let fullContent = ''
    let pendingToolCalls: ToolCall[] = []

    const streamCallback: StreamCallback = {
      onContent: (content: string) => {
        fullContent += content
        callback.onStreamContent(fullContent)
      },
      onToolCalls: (toolCalls: ToolCall[]) => {
        pendingToolCalls = toolCalls
      },
      onDone: async (finishReason: string) => {
        if (finishReason === 'tool_calls' && pendingToolCalls.length > 0) {
          // 保存 assistant 消息（含 tool_calls）
          await this.messageDao.create({
            sessionId: sessionId,
            role: 'assistant',
            content: fullContent || '',
            createdAt: Date.now(),
            toolCalls: pendingToolCalls
          })
          await this.sessionDao.incrementMessageCount(sessionId)

          // 执行工具并追加 tool messages
          for (const tc of pendingToolCalls) {
            callback.onToolExecuting(tc.function.name)
            const result = await this.toolRegistry.executeTool(tc.id, tc.function.name, tc.function.arguments)
            await this.messageDao.create({
              sessionId: sessionId,
              role: 'tool',
              content: result.content,
              createdAt: Date.now(),
              toolCallId: tc.id
            })
            await this.sessionDao.incrementMessageCount(sessionId)

            llmMessages.push({
              role: 'assistant',
              content: fullContent || null,
              tool_calls: pendingToolCalls
            })
            llmMessages.push({
              role: 'tool',
              content: result.content,
              tool_call_id: tc.id
            })
          }

          // 继续下一轮对话
          fullContent = ''
          pendingToolCalls = []
          await this.chatLoop(sessionId, llmMessages, callback, round + 1)
        } else {
          // 最终回复，保存 assistant 消息
          if (fullContent.length > 0) {
            await this.messageDao.create({
              sessionId: sessionId,
              role: 'assistant',
              content: fullContent,
              createdAt: Date.now()
            })
            await this.sessionDao.incrementMessageCount(sessionId)

            // 提取记忆标记
            this.extractMemoryMarks(fullContent, sessionId)
          }
          callback.onStreamDone(fullContent)
        }
      },
      onError: (error: string) => {
        Logger.error(TAG, `流式错误 error=${error}`)
        callback.onError(error)
      }
    }

    await this.llmClient.chatStream(request, streamCallback)
  }

  private buildLLMMessages(systemPrompt: string, history: ChatMessage[]): LLMMessage[] {
    const messages: LLMMessage[] = [
      { role: 'system', content: systemPrompt }
    ]

    for (const msg of history) {
      const llmMsg: LLMMessage = {
        role: msg.role,
        content: msg.content
      }
      if (msg.toolCalls && msg.toolCalls.length > 0) {
        llmMsg.tool_calls = msg.toolCalls
      }
      if (msg.toolCallId) {
        llmMsg.tool_call_id = msg.toolCallId
      }
      messages.push(llmMsg)
    }

    return messages
  }

  private async extractMemoryMarks(content: string, sessionId: number): Promise<void> {
    // 提取 [SAVE_MEMORY:category:content] 标记
    const memoryRegex = /\[SAVE_MEMORY:(\w+):([^\]]+)\]/g
    let match = memoryRegex.exec(content)
    while (match !== null) {
      const category = match[1]
      const memoryContent = match[2]
      const now = Date.now()
      try {
        await this.memoryDao.create({
          category: category as 'fact' | 'habit' | 'personality' | 'intent',
          content: memoryContent,
          importance: 3,
          repeatCount: 0,
          emotionWeight: 1.0,
          sourceSessionId: sessionId,
          accessCount: 0,
          createdAt: now,
          updatedAt: now
        })
        Logger.info(TAG, `提取记忆 category=${category}`)
      } catch (err) {
        Logger.error(TAG, `保存提取记忆失败 error=${JSON.stringify(err)}`)
      }
      match = memoryRegex.exec(content)
    }
  }
}
