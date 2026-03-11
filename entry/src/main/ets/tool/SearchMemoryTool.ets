import { Tool } from '../model/ToolModels'
import { ToolDefinition } from '../model/LLMModels'
import { MemoryDao } from '../data/MemoryDao'

export class SearchMemoryTool implements Tool {
  name: string = 'search_memory'
  description: string = '搜索记忆'
  parameters: object = {
    type: 'object',
    properties: {
      query: { type: 'string', description: '搜索关键词' }
    },
    required: ['query']
  }

  private memoryDao: MemoryDao = new MemoryDao()

  async execute(args: Record<string, Object>): Promise<string> {
    const query = args['query'] as string
    if (!query) {
      return JSON.stringify({ error: '缺少 query 参数' })
    }

    const memories = await this.memoryDao.search(query, 10)

    if (memories.length === 0) {
      return JSON.stringify({ results: [], message: '没有找到相关记忆' })
    }

    // 更新访问计数
    for (const memory of memories) {
      await this.memoryDao.incrementAccessCount(memory.id)
    }

    const results = memories.map(m => ({
      id: m.id,
      category: m.category,
      content: m.content,
      importance: m.importance
    }))

    return JSON.stringify({ results: results, count: results.length })
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
