import { ChatService, ChatCallback } from '../service/ChatService'
import { SessionDao } from '../data/SessionDao'
import { MessageDao } from '../data/MessageDao'
import { ChatMessage, Session } from '../model/ChatModels'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_CHAT

@Observed
export class ChatViewModel {
  messages: ChatMessage[] = []
  streamingContent: string = ''
  isLoading: boolean = false
  isStreaming: boolean = false
  currentSessionId: number = -1
  errorMessage: string = ''
  executingTool: string = ''
  sessions: Session[] = []

  private chatService: ChatService = new ChatService()
  private sessionDao: SessionDao = new SessionDao()
  private messageDao: MessageDao = new MessageDao()
  private isFirstMessage: boolean = true

  async init(): Promise<void> {
    await this.loadSessions()
    // 创建默认会话
    if (this.currentSessionId === -1) {
      await this.createNewSession()
    }
  }

  async createNewSession(): Promise<void> {
    try {
      const sessionId = await this.chatService.createSession()
      this.currentSessionId = sessionId
      this.messages = []
      this.streamingContent = ''
      this.errorMessage = ''
      this.isFirstMessage = true
      await this.loadSessions()
      Logger.info(TAG, `新会话创建 id=${sessionId}`)
    } catch (err) {
      Logger.error(TAG, `创建会话失败 error=${JSON.stringify(err)}`)
    }
  }

  async sendMessage(content: string): Promise<void> {
    if (!content.trim() || this.isStreaming) {
      return
    }

    this.isLoading = true
    this.isStreaming = true
    this.errorMessage = ''
    this.executingTool = ''
    this.streamingContent = ''

    // 先添加用户消息到列表（乐观更新）
    const userMessage = new ChatMessage(
      Date.now(),
      this.currentSessionId,
      'user',
      content.trim(),
      Date.now()
    )
    this.messages = [...this.messages, userMessage]

    // 第一条消息时更新会话标题
    if (this.isFirstMessage) {
      this.isFirstMessage = false
      await this.chatService.updateSessionTitle(this.currentSessionId, content.trim())
      await this.loadSessions()
    }

    const callback = new ChatCallback(
      (streamContent: string) => {
        this.streamingContent = streamContent
      },
      async (fullContent: string) => {
        this.streamingContent = ''
        this.isStreaming = false
        this.isLoading = false
        this.executingTool = ''
        // 重新加载消息以获得正确的 ID
        await this.loadMessages()
      },
      (toolName: string) => {
        this.executingTool = toolName
      },
      (error: string) => {
        this.errorMessage = error
        this.isStreaming = false
        this.isLoading = false
        this.streamingContent = ''
        this.executingTool = ''
        Logger.error(TAG, `对话错误 error=${error}`)
      }
    )

    try {
      await this.chatService.sendMessage(this.currentSessionId, content.trim(), callback)
    } catch (err) {
      this.errorMessage = (err as Error).message || '发送失败'
      this.isStreaming = false
      this.isLoading = false
    }
  }

  stopGenerating(): void {
    this.chatService.abort()
    this.isStreaming = false
    this.isLoading = false
    this.streamingContent = ''
    this.executingTool = ''
  }

  async switchSession(sessionId: number): Promise<void> {
    this.currentSessionId = sessionId
    this.streamingContent = ''
    this.errorMessage = ''
    this.executingTool = ''
    this.isFirstMessage = false
    await this.loadMessages()
  }

  async deleteSession(sessionId: number): Promise<void> {
    await this.sessionDao.delete(sessionId)
    await this.loadSessions()
    if (sessionId === this.currentSessionId) {
      if (this.sessions.length > 0) {
        await this.switchSession(this.sessions[0].id)
      } else {
        await this.createNewSession()
      }
    }
  }

  async loadSessions(): Promise<void> {
    this.sessions = await this.sessionDao.getAll()
  }

  private async loadMessages(): Promise<void> {
    this.messages = await this.messageDao.getBySessionId(this.currentSessionId, 50)
  }
}
