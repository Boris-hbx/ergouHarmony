import { ToolDefinition } from './LLMModels'

// 工具执行接口
export interface Tool {
  name: string
  description: string
  parameters: object
  execute(args: Record<string, Object>): Promise<string>
  toDefinition(): ToolDefinition
}

// 工具执行结果
export interface ToolResult {
  toolCallId: string
  name: string
  content: string
  success: boolean
}
