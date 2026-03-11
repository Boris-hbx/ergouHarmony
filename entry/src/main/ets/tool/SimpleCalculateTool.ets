import { Tool } from '../model/ToolModels'
import { ToolDefinition } from '../model/LLMModels'

export class SimpleCalculateTool implements Tool {
  name: string = 'simple_calculate'
  description: string = '简单数学计算'
  parameters: object = {
    type: 'object',
    properties: {
      expression: { type: 'string', description: '数学表达式，如 "100 * 1.13"' }
    },
    required: ['expression']
  }

  async execute(args: Record<string, Object>): Promise<string> {
    const expression = args['expression'] as string
    if (!expression) {
      return JSON.stringify({ error: '缺少 expression 参数' })
    }

    // 安全校验：只允许数字、运算符、括号、小数点、空格
    if (!/^[\d\s+\-*/().%]+$/.test(expression)) {
      return JSON.stringify({ error: '不支持的表达式' })
    }

    try {
      // 使用 Function 构造安全的计算
      const result = new Function(`return (${expression})`)()
      return JSON.stringify({
        expression: expression,
        result: result
      })
    } catch {
      return JSON.stringify({ error: '计算失败，请检查表达式' })
    }
  }

  toDefinition(): ToolDefinition {
    return {
      type: 'function',
      function: {
        name: this.name,
        description: this.description,
        parameters: this.parameters
      }
    }
  }
}
