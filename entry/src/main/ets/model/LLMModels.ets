// ===== Claude API 请求 =====

export class ChatRequest {
  model: string
  max_tokens: number
  system: string
  messages: ClaudeMessage[]
  tools: ClaudeToolDefinition[] | undefined
  stream: boolean
  temperature: number

  constructor(
    model: string,
    maxTokens: number,
    system: string,
    messages: ClaudeMessage[],
    stream: boolean,
    temperature: number,
    tools?: ClaudeToolDefinition[]
  ) {
    this.model = model
    this.max_tokens = maxTokens
    this.system = system
    this.messages = messages
    this.stream = stream
    this.temperature = temperature
    this.tools = tools
  }
}

// Claude 消息
export class ClaudeMessage {
  role: string = 'user'
  content: string | ContentBlock[]

  constructor(role: string, content: string | ContentBlock[]) {
    this.role = role
    this.content = content
  }
}

// 内容块 — 用 class + type 判别字段代替 union type
export class ContentBlock {
  type: string = ''
  // TextBlock 字段
  text?: string
  // ToolUseBlock 字段
  id?: string
  name?: string
  input?: Record<string, Object>
  // ToolResultBlock 字段
  tool_use_id?: string
  content?: string

  constructor(type: string) {
    this.type = type
  }

  static text(text: string): ContentBlock {
    const block = new ContentBlock('text')
    block.text = text
    return block
  }

  static toolUse(id: string, name: string, input: Record<string, Object>): ContentBlock {
    const block = new ContentBlock('tool_use')
    block.id = id
    block.name = name
    block.input = input
    return block
  }

  static toolResult(toolUseId: string, content: string): ContentBlock {
    const block = new ContentBlock('tool_result')
    block.tool_use_id = toolUseId
    block.content = content
    return block
  }
}

// 具体子类，方便消费端按类型构造

export class TextBlock extends ContentBlock {
  constructor(textVal: string) {
    super('text')
    this.text = textVal
  }
}

export class ToolUseBlock extends ContentBlock {
  constructor(id: string, name: string, input: Record<string, Object>) {
    super('tool_use')
    this.id = id
    this.name = name
    this.input = input
  }
}

export class ToolResultBlock extends ContentBlock {
  constructor(toolUseId: string, contentVal: string) {
    super('tool_result')
    this.tool_use_id = toolUseId
    this.content = contentVal
  }
}

// Claude 工具定义
export class ClaudeToolDefinition {
  name: string = ''
  description: string = ''
  input_schema: Record<string, Object> = {}

  constructor(name?: string, description?: string, inputSchema?: Record<string, Object>) {
    if (name !== undefined) {
      this.name = name
    }
    if (description !== undefined) {
      this.description = description
    }
    if (inputSchema !== undefined) {
      this.input_schema = inputSchema
    }
  }
}

// ===== Claude SSE 流式事件 =====

export interface SSEEvent {
  type: string
}

export interface MessageStartEvent extends SSEEvent {
  type: 'message_start'
  message: MessageStartInfo
}

export interface MessageStartInfo {
  id: string
  role: string
  model: string
}

export interface ContentBlockStartEvent extends SSEEvent {
  type: 'content_block_start'
  index: number
  content_block: ContentBlockInfo
}

export interface ContentBlockInfo {
  type: 'text' | 'tool_use'
  text?: string
  id?: string
  name?: string
  input?: Record<string, Object>
}

export interface ContentBlockDeltaEvent extends SSEEvent {
  type: 'content_block_delta'
  index: number
  delta: ContentBlockDeltaInfo
}

export interface ContentBlockDeltaInfo {
  type: 'text_delta' | 'input_json_delta'
  text?: string
  partial_json?: string
}

export interface ContentBlockStopEvent extends SSEEvent {
  type: 'content_block_stop'
  index: number
}

export interface MessageDeltaEvent extends SSEEvent {
  type: 'message_delta'
  delta: MessageDeltaStopInfo
}

export interface MessageDeltaStopInfo {
  stop_reason: string | null
}

// ===== 兼容层（DAO 存储用，保持不变） =====

// 工具调用（存储格式，兼容 DAO）
export class ToolCall {
  id: string
  type: string = 'function'
  function: ToolCallFunction

  constructor(id: string, name: string, args: string) {
    this.id = id
    this.function = new ToolCallFunction(name, args)
  }
}

export class ToolCallFunction {
  name: string
  arguments: string

  constructor(name: string, args: string) {
    this.name = name
    this.arguments = args
  }
}

// 旧版工具定义格式（ToolRegistry 输出后转换）
export interface ToolDefinition {
  type: 'function'
  function: ToolFunction
}

export interface ToolFunction {
  name: string
  description: string
  parameters: Record<string, Object>
}
