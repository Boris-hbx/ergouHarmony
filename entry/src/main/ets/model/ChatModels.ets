import { ToolCall } from './LLMModels'

// 会话
export class Session {
  id: number
  title: string
  createdAt: number
  updatedAt: number
  messageCount: number

  constructor(id: number, title: string, createdAt: number, updatedAt: number, messageCount: number) {
    this.id = id
    this.title = title
    this.createdAt = createdAt
    this.updatedAt = updatedAt
    this.messageCount = messageCount
  }
}

// 创建会话参数（不含 id）
export class CreateSessionParams {
  title: string
  createdAt: number
  updatedAt: number
  messageCount: number

  constructor(title: string, createdAt: number, updatedAt: number, messageCount: number) {
    this.title = title
    this.createdAt = createdAt
    this.updatedAt = updatedAt
    this.messageCount = messageCount
  }
}

// 聊天消息
export class ChatMessage {
  id: number = 0
  sessionId: number = 0
  role: 'system' | 'user' | 'assistant' | 'tool' = 'user'
  content: string = ''
  createdAt: number = 0
  toolCalls?: ToolCall[]
  toolCallId?: string

  constructor(
    id: number,
    sessionId: number,
    role: 'system' | 'user' | 'assistant' | 'tool',
    content: string,
    createdAt: number,
    toolCalls?: ToolCall[],
    toolCallId?: string
  ) {
    this.id = id
    this.sessionId = sessionId
    this.role = role
    this.content = content
    this.createdAt = createdAt
    this.toolCalls = toolCalls
    this.toolCallId = toolCallId
  }
}

// 创建消息参数（不含 id）
export class CreateMessageParams {
  sessionId: number
  role: string
  content: string
  createdAt: number
  toolCalls?: ToolCall[]
  toolCallId?: string

  constructor(sessionId: number, role: string, content: string, createdAt: number) {
    this.sessionId = sessionId
    this.role = role
    this.content = content
    this.createdAt = createdAt
  }
}

// 记忆
export class Memory {
  id: number
  category: string
  content: string
  importance: number
  repeatCount: number
  emotionWeight: number
  sourceSessionId: number
  accessCount: number
  createdAt: number
  updatedAt: number

  constructor(
    id: number,
    category: string,
    content: string,
    importance: number,
    repeatCount: number,
    emotionWeight: number,
    sourceSessionId: number,
    accessCount: number,
    createdAt: number,
    updatedAt: number
  ) {
    this.id = id
    this.category = category
    this.content = content
    this.importance = importance
    this.repeatCount = repeatCount
    this.emotionWeight = emotionWeight
    this.sourceSessionId = sourceSessionId
    this.accessCount = accessCount
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }
}

// 创建记忆参数（不含 id）
export class CreateMemoryParams {
  category: string
  content: string
  importance: number
  repeatCount: number
  emotionWeight: number
  sourceSessionId: number
  accessCount: number
  createdAt: number
  updatedAt: number

  constructor(
    category: string,
    content: string,
    importance: number,
    repeatCount: number,
    emotionWeight: number,
    sourceSessionId: number,
    accessCount: number,
    createdAt: number,
    updatedAt: number
  ) {
    this.category = category
    this.content = content
    this.importance = importance
    this.repeatCount = repeatCount
    this.emotionWeight = emotionWeight
    this.sourceSessionId = sourceSessionId
    this.accessCount = accessCount
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }
}
