import { Tool } from '../model/ToolModels'
import { MemoryDao } from '../data/MemoryDao'
import { Memory } from '../model/ChatModels'

export class SearchMemoryTool implements Tool {
  name: string = 'search_memory'
  description: string = '搜索记忆'
  parametersSchema: string = '{"type":"object","properties":{"query":{"type":"string","description":"搜索关键词"}},"required":["query"]}'

  private memoryDao: MemoryDao = new MemoryDao()

  async execute(args: Record<string, Object>): Promise<string> {
    const query = args['query'] as string
    if (!query) {
      return '{"results":[],"message":"缺少 query 参数"}'
    }

    const memories: Memory[] = await this.memoryDao.search(query, 10)

    if (memories.length === 0) {
      return '{"results":[],"message":"没有找到相关记忆"}'
    }

    // 更新访问计数
    for (const memory of memories) {
      await this.memoryDao.incrementAccessCount(memory.id)
    }

    // 手动构建 JSON 字符串避免 untyped object literal
    const items: string[] = []
    for (const m of memories) {
      items.push(`{"id":${m.id},"category":"${m.category}","content":"${m.content}","importance":${m.importance}}`)
    }
    return `{"results":[${items.join(',')}],"count":${memories.length}}`
  }
}
