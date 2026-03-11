// ===== Claude API 请求 =====

export interface ChatRequest {
  model: string
  max_tokens: number
  system?: string
  messages: ClaudeMessage[]
  tools?: ClaudeToolDefinition[]
  stream: boolean
  temperature?: number
}

// Claude 消息
export interface ClaudeMessage {
  role: 'user' | 'assistant'
  content: string | ContentBlock[]
}

// 内容块类型
export type ContentBlock = TextBlock | ToolUseBlock | ToolResultBlock

export interface TextBlock {
  type: 'text'
  text: string
}

export interface ToolUseBlock {
  type: 'tool_use'
  id: string
  name: string
  input: object
}

export interface ToolResultBlock {
  type: 'tool_result'
  tool_use_id: string
  content: string
}

// Claude 工具定义
export interface ClaudeToolDefinition {
  name: string
  description: string
  input_schema: object
}

// ===== Claude SSE 流式事件 =====

export interface SSEEvent {
  type: string
}

export interface MessageStartEvent extends SSEEvent {
  type: 'message_start'
  message: {
    id: string
    role: string
    model: string
  }
}

export interface ContentBlockStartEvent extends SSEEvent {
  type: 'content_block_start'
  index: number
  content_block: {
    type: 'text' | 'tool_use'
    text?: string
    id?: string
    name?: string
    input?: object
  }
}

export interface ContentBlockDeltaEvent extends SSEEvent {
  type: 'content_block_delta'
  index: number
  delta: {
    type: 'text_delta' | 'input_json_delta'
    text?: string
    partial_json?: string
  }
}

export interface ContentBlockStopEvent extends SSEEvent {
  type: 'content_block_stop'
  index: number
}

export interface MessageDeltaEvent extends SSEEvent {
  type: 'message_delta'
  delta: {
    stop_reason: string | null
  }
}

// ===== 兼容层（DAO 存储用，保持不变） =====

// 工具调用（存储格式，兼容 DAO）
export interface ToolCall {
  id: string
  type: 'function'
  function: ToolCallFunction
}

export interface ToolCallFunction {
  name: string
  arguments: string
}

// 旧版工具定义格式（ToolRegistry 输出后转换）
export interface ToolDefinition {
  type: 'function'
  function: ToolFunction
}

export interface ToolFunction {
  name: string
  description: string
  parameters: object
}
