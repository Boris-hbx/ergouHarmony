// 工具执行接口
export interface Tool {
  name: string
  description: string
  parametersSchema: string
  execute(args: Record<string, Object>): Promise<string>
}

// 工具执行结果
export class ToolResult {
  toolCallId: string
  name: string
  content: string
  success: boolean

  constructor(toolCallId: string, name: string, content: string, success: boolean) {
    this.toolCallId = toolCallId
    this.name = name
    this.content = content
    this.success = success
  }
}
