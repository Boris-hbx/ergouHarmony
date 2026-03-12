import { Tool, ToolResult } from '../model/ToolModels'
import { ClaudeToolDefinition } from '../model/LLMModels'
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

  getAllDefinitions(): ClaudeToolDefinition[] {
    const definitions: ClaudeToolDefinition[] = []
    this.tools.forEach((tool) => {
      const schema = JSON.parse(tool.parametersSchema) as Record<string, Object>
      definitions.push(new ClaudeToolDefinition(tool.name, tool.description, schema))
    })
    return definitions
  }

  async executeTool(toolCallId: string, name: string, argsJson: string): Promise<ToolResult> {
    const tool = this.tools.get(name)
    if (!tool) {
      Logger.warn(TAG, `未知工具 name=${name}`)
      return new ToolResult(toolCallId, name, `未知工具: ${name}`, false)
    }

    try {
      const args: Record<string, Object> = JSON.parse(argsJson) as Record<string, Object>
      Logger.info(TAG, `执行工具 name=${name}`)
      const content = await tool.execute(args)
      return new ToolResult(toolCallId, name, content, true)
    } catch (err) {
      Logger.error(TAG, `工具执行失败 name=${name} error=${JSON.stringify(err)}`)
      return new ToolResult(toolCallId, name, `工具执行失败: ${(err as Error).message || String(err)}`, false)
    }
  }
}
