import { Tool, ToolResult } from '../model/ToolModels'
import { ToolDefinition } from '../model/LLMModels'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_TOOL

export class ToolRegistry {
  private tools: Map<string, Tool> = new Map()

  register(tool: Tool): void {
    this.tools.set(tool.name, tool)
    Logger.info(TAG, `工具注册 name=${tool.name}`)
  }

  getTool(name: string): Tool | undefined {
    return this.tools.get(name)
  }

  getAllDefinitions(): ToolDefinition[] {
    const definitions: ToolDefinition[] = []
    this.tools.forEach((tool) => {
      definitions.push(tool.toDefinition())
    })
    return definitions
  }

  async executeTool(toolCallId: string, name: string, argsJson: string): Promise<ToolResult> {
    const tool = this.tools.get(name)
    if (!tool) {
      Logger.warn(TAG, `未知工具 name=${name}`)
      return {
        toolCallId: toolCallId,
        name: name,
        content: `未知工具: ${name}`,
        success: false
      }
    }

    try {
      const args: Record<string, Object> = JSON.parse(argsJson) as Record<string, Object>
      Logger.info(TAG, `执行工具 name=${name}`)
      const result = await tool.execute(args)
      return {
        toolCallId: toolCallId,
        name: name,
        content: result,
        success: true
      }
    } catch (err) {
      Logger.error(TAG, `工具执行失败 name=${name} error=${JSON.stringify(err)}`)
      return {
        toolCallId: toolCallId,
        name: name,
        content: `工具执行失败: ${(err as Error).message || String(err)}`,
        success: false
      }
    }
  }
}
