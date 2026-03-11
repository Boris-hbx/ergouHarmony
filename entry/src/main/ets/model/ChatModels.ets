import { ToolCall } from './LLMModels'

// 会话
export interface Session {
  id: number
  title: string
  createdAt: number
  updatedAt: number
  messageCount: number
}

// 聊天消息
export interface ChatMessage {
  id: number
  sessionId: number
  role: 'system' | 'user' | 'assistant' | 'tool'
  content: string
  createdAt: number
  toolCalls?: ToolCall[]
  toolCallId?: string
}

// 记忆
export interface Memory {
  id: number
  category: 'fact' | 'habit' | 'personality' | 'intent'
  content: string
  importance: number
  repeatCount: number
  emotionWeight: number
  sourceSessionId: number
  accessCount: number
  createdAt: number
  updatedAt: number
}
