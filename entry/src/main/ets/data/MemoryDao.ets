import { relationalStore } from '@kit.ArkData'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { DatabaseHelper } from './DatabaseHelper'
import { Memory } from '../model/ChatModels'

const TAG = Constants.TAG_DB

export class MemoryDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async create(memory: Omit<Memory, 'id'>): Promise<number> {
    const bucket: relationalStore.ValuesBucket = {
      category: memory.category,
      content: memory.content,
      importance: memory.importance,
      repeat_count: memory.repeatCount,
      emotion_weight: memory.emotionWeight,
      source_session_id: memory.sourceSessionId,
      access_count: memory.accessCount,
      created_at: memory.createdAt,
      updated_at: memory.updatedAt
    }
    try {
      const rowId = await this.getStore().insert('memories', bucket)
      Logger.info(TAG, `记忆创建成功 id=${rowId} category=${memory.category}`)
      return rowId
    } catch (err) {
      Logger.error(TAG, `记忆创建失败 error=${JSON.stringify(err)}`)
      throw err
    }
  }

  async getById(id: number): Promise<Memory | null> {
    const predicates = new relationalStore.RdbPredicates('memories')
    predicates.equalTo('id', id)
    try {
      const resultSet = await this.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        const memory = this.fromResultSet(resultSet)
        resultSet.close()
        return memory
      }
      resultSet.close()
      return null
    } catch (err) {
      Logger.error(TAG, `查询记忆失败 id=${id} error=${JSON.stringify(err)}`)
      return null
    }
  }

  async getByCategory(category: string): Promise<Memory[]> {
    const predicates = new relationalStore.RdbPredicates('memories')
    predicates.equalTo('category', category)
    predicates.orderByDesc('importance')
    try {
      const resultSet = await this.getStore().query(predicates)
      const memories: Memory[] = []
      while (resultSet.goToNextRow()) {
        memories.push(this.fromResultSet(resultSet))
      }
      resultSet.close()
      return memories
    } catch (err) {
      Logger.error(TAG, `按类别查询记忆失败 category=${category} error=${JSON.stringify(err)}`)
      return []
    }
  }

  async search(keyword: string, limit: number = 10): Promise<Memory[]> {
    try {
      const resultSet = await this.getStore().querySql(
        `SELECT * FROM memories WHERE content LIKE ? ORDER BY importance DESC, access_count DESC LIMIT ?`,
        [`%${keyword}%`, limit.toString()]
      )
      const memories: Memory[] = []
      while (resultSet.goToNextRow()) {
        memories.push(this.fromResultSet(resultSet))
      }
      resultSet.close()
      return memories
    } catch (err) {
      Logger.error(TAG, `搜索记忆失败 keyword=${keyword} error=${JSON.stringify(err)}`)
      return []
    }
  }

  async getRecent(limit: number = 10): Promise<Memory[]> {
    try {
      const resultSet = await this.getStore().querySql(
        `SELECT * FROM memories ORDER BY updated_at DESC LIMIT ?`,
        [limit.toString()]
      )
      const memories: Memory[] = []
      while (resultSet.goToNextRow()) {
        memories.push(this.fromResultSet(resultSet))
      }
      resultSet.close()
      return memories
    } catch (err) {
      Logger.error(TAG, `查询最近记忆失败 error=${JSON.stringify(err)}`)
      return []
    }
  }

  async incrementAccessCount(id: number): Promise<void> {
    try {
      await this.getStore().executeSql(
        `UPDATE memories SET access_count = access_count + 1, updated_at = ? WHERE id = ?`,
        [Date.now(), id]
      )
    } catch (err) {
      Logger.error(TAG, `更新记忆访问数失败 id=${id} error=${JSON.stringify(err)}`)
    }
  }

  async delete(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('memories')
    predicates.equalTo('id', id)
    try {
      await this.getStore().delete(predicates)
      Logger.info(TAG, `记忆删除成功 id=${id}`)
    } catch (err) {
      Logger.error(TAG, `记忆删除失败 id=${id} error=${JSON.stringify(err)}`)
    }
  }

  private fromResultSet(resultSet: relationalStore.ResultSet): Memory {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      category: resultSet.getString(resultSet.getColumnIndex('category')) as Memory['category'],
      content: resultSet.getString(resultSet.getColumnIndex('content')),
      importance: resultSet.getLong(resultSet.getColumnIndex('importance')),
      repeatCount: resultSet.getLong(resultSet.getColumnIndex('repeat_count')),
      emotionWeight: resultSet.getDouble(resultSet.getColumnIndex('emotion_weight')),
      sourceSessionId: resultSet.getLong(resultSet.getColumnIndex('source_session_id')),
      accessCount: resultSet.getLong(resultSet.getColumnIndex('access_count')),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    }
  }
}
