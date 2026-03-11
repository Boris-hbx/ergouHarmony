import { Tool } from '../model/ToolModels'
import { ToolDefinition } from '../model/LLMModels'
import { MemoryDao } from '../data/MemoryDao'
import { Memory } from '../model/ChatModels'

export class SaveMemoryTool implements Tool {
  name: string = 'save_memory'
  description: string = '保存记忆'
  parameters: object = {
    type: 'object',
    properties: {
      category: { type: 'string', enum: ['fact', 'habit', 'personality', 'intent'], description: '记忆类别' },
      content: { type: 'string', description: '记忆内容' }
    },
    required: ['category', 'content']
  }

  private memoryDao: MemoryDao = new MemoryDao()
  private currentSessionId: number = -1

  setSessionId(sessionId: number): void {
    this.currentSessionId = sessionId
  }

  async execute(args: Record<string, Object>): Promise<string> {
    const category = args['category'] as string
    const content = args['content'] as string

    if (!category || !content) {
      return JSON.stringify({ error: '缺少 category 或 content 参数' })
    }

    const now = Date.now()
    const memory: Omit<Memory, 'id'> = {
      category: category as Memory['category'],
      content: content,
      importance: 3,
      repeatCount: 0,
      emotionWeight: 1.0,
      sourceSessionId: this.currentSessionId,
      accessCount: 0,
      createdAt: now,
      updatedAt: now
    }

    const id = await this.memoryDao.create(memory)
    return JSON.stringify({ success: true, id: id, message: `已记住: ${content}` })
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
