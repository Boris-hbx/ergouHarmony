import { Tool } from '../model/ToolModels'
import { ToolDefinition } from '../model/LLMModels'

export class GetDateTimeTool implements Tool {
  name: string = 'get_date_time'
  description: string = '获取当前日期和时间'
  parameters: object = { type: 'object', properties: {} }

  async execute(_args: Record<string, Object>): Promise<string> {
    const now = new Date()
    const weekDays = ['日', '一', '二', '三', '四', '五', '六']
    const dateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`
    return JSON.stringify({
      date: dateStr,
      time: timeStr,
      weekday: `星期${weekDays[now.getDay()]}`,
      timestamp: now.getTime()
    })
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
