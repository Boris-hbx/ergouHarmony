import { Tool } from '../model/ToolModels'
import { MemoryDao } from '../data/MemoryDao'
import { CreateMemoryParams } from '../model/ChatModels'

export class SaveMemoryTool implements Tool {
  name: string = 'save_memory'
  description: string = '保存记忆'
  parametersSchema: string = '{"type":"object","properties":{"category":{"type":"string","enum":["fact","habit","personality","intent"],"description":"记忆类别"},"content":{"type":"string","description":"记忆内容"}},"required":["category","content"]}'

  private memoryDao: MemoryDao = new MemoryDao()
  private currentSessionId: number = -1

  setSessionId(sessionId: number): void {
    this.currentSessionId = sessionId
  }

  async execute(args: Record<string, Object>): Promise<string> {
    const category = args['category'] as string
    const content = args['content'] as string

    if (!category || !content) {
      return '{"error":"缺少 category 或 content 参数"}'
    }

    const now = Date.now()
    const memory = new CreateMemoryParams(category, content, 3, 0, 1.0, this.currentSessionId, 0, now, now)

    const id = await this.memoryDao.create(memory)
    return `{"success":true,"id":${id},"message":"已记住: ${content}"}`
  }
}
