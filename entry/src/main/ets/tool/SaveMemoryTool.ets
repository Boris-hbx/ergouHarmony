import { Tool } from '../model/ToolModels'
import { NextApiClient } from '../service/NextApiClient'
import { MemoryDao } from '../data/MemoryDao'
import { CreateMemoryParams } from '../model/ChatModels'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_MEMORY

export class SaveMemoryTool implements Tool {
  name: string = 'save_memory'
  description: string = '保存记忆'
  parametersSchema: string = '{"type":"object","properties":{"category":{"type":"string","enum":["fact","habit","personality","intent"],"description":"记忆类别"},"content":{"type":"string","description":"记忆内容"}},"required":["category","content"]}'

  private memoryDao: MemoryDao = new MemoryDao()

  async execute(args: Record<string, Object>): Promise<string> {
    const category = args['category'] as string
    const content = args['content'] as string

    if (!category || !content) {
      return '{"error":"缺少 category 或 content 参数"}'
    }

    // 优先调后端 API
    try {
      const memory = await NextApiClient.saveMemory(category, content, 3)
      const id = String(memory['id'] || '')
      Logger.info(TAG, `记忆保存成功(后端) id=${id} category=${category}`)

      // 同步到本地缓存
      try {
        const now = Date.now()
        await this.memoryDao.create(new CreateMemoryParams(category, content, 3, 0, 1.0, -1, 0, now, now))
      } catch {
        // 本地缓存失败不影响结果
      }

      return `{"success":true,"id":"${id}","message":"已记住: ${content}"}`
    } catch (err) {
      Logger.warn(TAG, `后端保存失败，降级到本地 error=${(err as Error).message}`)
    }

    // fallback: 本地存储
    try {
      const now = Date.now()
      const localId = await this.memoryDao.create(new CreateMemoryParams(category, content, 3, 0, 1.0, -1, 0, now, now))
      return `{"success":true,"id":${localId},"message":"已记住(离线): ${content}"}`
    } catch (localErr) {
      return `{"error":"保存失败: ${(localErr as Error).message}"}`
    }
  }
}
