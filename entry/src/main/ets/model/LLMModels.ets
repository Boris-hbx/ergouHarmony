// LLM 请求
export interface ChatRequest {
  model: string
  messages: LLMMessage[]
  stream: boolean
  temperature: number
  max_tokens: number
  tools?: ToolDefinition[]
}

// LLM 消息
export interface LLMMessage {
  role: string
  content: string | null
  tool_calls?: ToolCall[]
  tool_call_id?: string
}

// 工具定义
export interface ToolDefinition {
  type: 'function'
  function: ToolFunction
}

export interface ToolFunction {
  name: string
  description: string
  parameters: object
}

// 工具调用
export interface ToolCall {
  id: string
  type: 'function'
  function: ToolCallFunction
}

export interface ToolCallFunction {
  name: string
  arguments: string
}

// SSE 流式响应 chunk
export interface ChatResponseChunk {
  id: string
  choices: ChatResponseChoice[]
}

export interface ChatResponseChoice {
  index: number
  delta: ChatResponseDelta
  finish_reason: string | null
}

export interface ChatResponseDelta {
  role?: string
  content?: string
  tool_calls?: ToolCall[]
}
