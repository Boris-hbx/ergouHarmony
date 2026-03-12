import { Tool } from '../model/ToolModels'
import { NextApiClient } from '../service/NextApiClient'
import { MemoryDao } from '../data/MemoryDao'
import { Memory } from '../model/ChatModels'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_MEMORY

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

    // 优先调后端 API
    try {
      const memories = await NextApiClient.searchMemory(query, 10)

      if (memories.length === 0) {
        return '{"results":[],"message":"没有找到相关记忆"}'
      }

      const items: string[] = []
      for (const m of memories) {
        const mem = m as Record<string, Object>
        const id = String(mem['id'] || '')
        const category = String(mem['category'] || '')
        const content = String(mem['content'] || '').replace(/"/g, '\\"')
        const importance = Number(mem['importance'] || 3)
        items.push(`{"id":"${id}","category":"${category}","content":"${content}","importance":${importance}}`)
      }
      Logger.info(TAG, `记忆搜索成功(后端) query=${query} count=${memories.length}`)
      return `{"results":[${items.join(',')}],"count":${memories.length}}`
    } catch (err) {
      Logger.warn(TAG, `后端搜索失败，降级到本地 error=${(err as Error).message}`)
    }

    // fallback: 本地搜索
    try {
      const localMemories: Memory[] = await this.memoryDao.search(query, 10)
      if (localMemories.length === 0) {
        return '{"results":[],"message":"没有找到相关记忆"}'
      }

      for (const memory of localMemories) {
        await this.memoryDao.incrementAccessCount(memory.id)
      }

      const items: string[] = []
      for (const m of localMemories) {
        items.push(`{"id":${m.id},"category":"${m.category}","content":"${m.content}","importance":${m.importance}}`)
      }
      return `{"results":[${items.join(',')}],"count":${localMemories.length}}`
    } catch {
      return '{"results":[],"message":"搜索失败"}'
    }
  }
}
