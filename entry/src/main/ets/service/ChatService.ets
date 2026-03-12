import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { LLMClient, StreamCallback, ToolCallInfo } from './LLMClient'
import { ErgouPrompt } from './ErgouPrompt'
import { ToolRegistry } from '../tool/ToolRegistry'
import { GetDateTimeTool } from '../tool/GetDateTimeTool'
import { SimpleCalculateTool } from '../tool/SimpleCalculateTool'
import { SaveMemoryTool } from '../tool/SaveMemoryTool'
import { SearchMemoryTool } from '../tool/SearchMemoryTool'
import { AddExpenseTool } from '../tool/AddExpenseTool'
import { ExpenseSummaryTool } from '../tool/ExpenseSummaryTool'
import { SessionDao } from '../data/SessionDao'
import { MessageDao } from '../data/MessageDao'
import { MemoryDao } from '../data/MemoryDao'
import { ChatMessage, CreateMessageParams, CreateMemoryParams } from '../model/ChatModels'
import {
  ChatRequest,
  ClaudeMessage,
  ContentBlock,
  TextBlock,
  ToolUseBlock,
  ToolResultBlock,
  ToolCall
} from '../model/LLMModels'
import { PromptSanitizer } from '../common/PromptSanitizer'

const TAG = Constants.TAG_CHAT
const MAX_TOOL_ROUNDS = 5

// ChatService 回调
export class ChatCallback {
  onStreamContent: (content: string) => void
  onStreamDone: (fullContent: string) => void
  onToolExecuting: (toolName: string) => void
  onError: (error: string) => void

  constructor(
    onStreamContent: (content: string) => void,
    onStreamDone: (fullContent: string) => void,
    onToolExecuting: (toolName: string) => void,
    onError: (error: string) => void
  ) {
    this.onStreamContent = onStreamContent
    this.onStreamDone = onStreamDone
    this.onToolExecuting = onToolExecuting
    this.onError = onError
  }
}

export class ChatService {
  private llmClient: LLMClient = new LLMClient()
  private toolRegistry: ToolRegistry = new ToolRegistry()
  private sessionDao: SessionDao = new SessionDao()
  private messageDao: MessageDao = new MessageDao()
  private memoryDao: MemoryDao = new MemoryDao()
  private saveMemoryTool: SaveMemoryTool = new SaveMemoryTool()

  constructor() {
    this.toolRegistry.register(new GetDateTimeTool())
    this.toolRegistry.register(new SimpleCalculateTool())
    this.toolRegistry.register(this.saveMemoryTool)
    this.toolRegistry.register(new SearchMemoryTool())
    this.toolRegistry.register(new AddExpenseTool())
    this.toolRegistry.register(new ExpenseSummaryTool())
  }

  async sendMessage(sessionId: number, userContent: string, callback: ChatCallback): Promise<void> {
    this.saveMemoryTool.setSessionId(sessionId)

    // 1. 净化用户输入
    const sanitized = PromptSanitizer.sanitize(userContent)

    // 2. 保存用户消息
    await this.messageDao.create(new CreateMessageParams(sessionId, 'user', sanitized, Date.now()))
    await this.sessionDao.incrementMessageCount(sessionId)

    // 3. 加载历史消息
    const historyMessages = await this.messageDao.getBySessionId(sessionId, Constants.LLM_CONTEXT_MESSAGES)

    // 4. 检索相关记忆
    const memories = await this.memoryDao.getRecent(5)
    const memoryTexts = memories.map(m => m.content)

    // 5. 组装系统 prompt
    const systemPrompt = ErgouPrompt.buildSystemPrompt() + ErgouPrompt.buildMemoryContext(memoryTexts)

    // 6. 构建 Claude 消息
    const claudeMessages = this.buildClaudeMessages(historyMessages)

    // 7. 开始对话循环
    await this.chatLoop(sessionId, systemPrompt, claudeMessages, callback, 0)
  }

  async createSession(title?: string): Promise<number> {
    return await this.sessionDao.create(title || '新对话')
  }

  async updateSessionTitle(sessionId: number, firstMessage: string): Promise<void> {
    const title = firstMessage.length > 20 ? firstMessage.substring(0, 20) + '...' : firstMessage
    await this.sessionDao.updateTitle(sessionId, title)
  }

  abort(): void {
    this.llmClient.abort()
  }

  private async chatLoop(
    sessionId: number,
    systemPrompt: string,
    claudeMessages: ClaudeMessage[],
    callback: ChatCallback,
    round: number
  ): Promise<void> {
    if (round >= MAX_TOOL_ROUNDS) {
      Logger.warn(TAG, `工具调用轮次达到上限 round=${round}`)
      callback.onError('工具调用轮次过多')
      return
    }

    // 构建 Claude 工具定义（ToolRegistry 直接返回 ClaudeToolDefinition[]）
    const tools = this.toolRegistry.getAllDefinitions()

    const request = new ChatRequest(
      Constants.CLAUDE_MODEL,
      Constants.LLM_MAX_TOKENS,
      systemPrompt,
      claudeMessages,
      true,
      Constants.LLM_TEMPERATURE,
      tools.length > 0 ? tools : undefined
    )

    let fullContent = ''
    let pendingToolCalls: ToolCallInfo[] = []

    const streamCallback = new StreamCallback(
      (content: string) => {
        fullContent += content
        callback.onStreamContent(fullContent)
      },
      (toolCalls: ToolCallInfo[]) => {
        pendingToolCalls = toolCalls
      },
      async (stopReason: string) => {
        if (stopReason === 'tool_use' && pendingToolCalls.length > 0) {
          // 保存 assistant 消息（含工具调用）
          const toolCallsForStorage: ToolCall[] = pendingToolCalls.map(tc => new ToolCall(tc.id, tc.name, tc.inputJson))

          const assistantMsgParams = new CreateMessageParams(sessionId, 'assistant', fullContent || '', Date.now())
          assistantMsgParams.toolCalls = toolCallsForStorage
          await this.messageDao.create(assistantMsgParams)
          await this.sessionDao.incrementMessageCount(sessionId)

          // 构建 assistant 消息的 content blocks
          const assistantBlocks: ContentBlock[] = []
          if (fullContent.length > 0) {
            assistantBlocks.push(new TextBlock(fullContent))
          }
          for (const tc of pendingToolCalls) {
            let input: Record<string, Object> = {}
            try {
              input = JSON.parse(tc.inputJson) as Record<string, Object>
            } catch {
              // 忽略
            }
            assistantBlocks.push(new ToolUseBlock(tc.id, tc.name, input))
          }
          claudeMessages.push(new ClaudeMessage('assistant', assistantBlocks))

          // 执行工具，收集结果
          const toolResultBlocks: ContentBlock[] = []
          for (const tc of pendingToolCalls) {
            callback.onToolExecuting(tc.name)
            const result = await this.toolRegistry.executeTool(tc.id, tc.name, tc.inputJson)

            // 保存 tool 消息到数据库
            const toolMsgParams = new CreateMessageParams(sessionId, 'tool', result.content, Date.now())
            toolMsgParams.toolCallId = tc.id
            await this.messageDao.create(toolMsgParams)
            await this.sessionDao.incrementMessageCount(sessionId)

            toolResultBlocks.push(new ToolResultBlock(tc.id, result.content))
          }

          // Claude 格式：tool_result 放在 user 消息中
          claudeMessages.push(new ClaudeMessage('user', toolResultBlocks))

          // 继续下一轮
          fullContent = ''
          pendingToolCalls = []
          await this.chatLoop(sessionId, systemPrompt, claudeMessages, callback, round + 1)
        } else {
          // 最终回复
          if (fullContent.length > 0) {
            await this.messageDao.create(new CreateMessageParams(sessionId, 'assistant', fullContent, Date.now()))
            await this.sessionDao.incrementMessageCount(sessionId)
            this.extractMemoryMarks(fullContent, sessionId)
          }
          callback.onStreamDone(fullContent)
        }
      },
      (error: string) => {
        Logger.error(TAG, `流式错误 error=${error}`)
        callback.onError(error)
      }
    )

    await this.llmClient.chatStream(request, streamCallback)
  }

  private buildClaudeMessages(history: ChatMessage[]): ClaudeMessage[] {
    const messages: ClaudeMessage[] = []

    let i = 0
    while (i < history.length) {
      const msg = history[i]

      if (msg.role === 'user') {
        messages.push(new ClaudeMessage('user', msg.content))
      } else if (msg.role === 'assistant') {
        if (msg.toolCalls && msg.toolCalls.length > 0) {
          // assistant 带工具调用 → content blocks
          const blocks: ContentBlock[] = []
          if (msg.content.length > 0) {
            blocks.push(new TextBlock(msg.content))
          }
          for (const tc of msg.toolCalls) {
            let input: Record<string, Object> = {}
            try {
              input = JSON.parse(tc.function.arguments) as Record<string, Object>
            } catch {
              // 忽略
            }
            blocks.push(new ToolUseBlock(tc.id, tc.function.name, input))
          }
          messages.push(new ClaudeMessage('assistant', blocks))

          // 后续的 tool 消息收集为 tool_result blocks
          const resultBlocks: ContentBlock[] = []
          let j = i + 1
          while (j < history.length && history[j].role === 'tool') {
            resultBlocks.push(new ToolResultBlock(history[j].toolCallId || '', history[j].content))
            j++
          }
          if (resultBlocks.length > 0) {
            messages.push(new ClaudeMessage('user', resultBlocks))
          }
          i = j
          continue
        } else {
          messages.push(new ClaudeMessage('assistant', msg.content))
        }
      }
      // tool 消息如果没被上面的循环处理，跳过
      i++
    }

    return messages
  }

  private async extractMemoryMarks(content: string, sessionId: number): Promise<void> {
    const memoryRegex = /\[SAVE_MEMORY:(\w+):([^\]]+)\]/g
    let match = memoryRegex.exec(content)
    while (match !== null) {
      const category = match[1]
      const memoryContent = match[2]
      const now = Date.now()
      try {
        await this.memoryDao.create(new CreateMemoryParams(
          category,
          memoryContent,
          3,
          0,
          1.0,
          sessionId,
          0,
          now,
          now
        ))
        Logger.info(TAG, `提取记忆 category=${category}`)
      } catch (err) {
        Logger.error(TAG, `保存提取记忆失败 error=${JSON.stringify(err)}`)
      }
      match = memoryRegex.exec(content)
    }
  }
}
