import { relationalStore } from '@kit.ArkData'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { DatabaseHelper } from './DatabaseHelper'
import { Session } from '../model/ChatModels'

const TAG = Constants.TAG_DB

export class SessionDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async create(title: string): Promise<number> {
    const now = Date.now()
    const bucket: relationalStore.ValuesBucket = {
      title: title,
      created_at: now,
      updated_at: now,
      message_count: 0
    }
    try {
      const rowId = await this.getStore().insert('sessions', bucket)
      Logger.info(TAG, `会话创建成功 id=${rowId}`)
      return rowId
    } catch (err) {
      Logger.error(TAG, `会话创建失败 error=${JSON.stringify(err)}`)
      throw err
    }
  }

  async getById(id: number): Promise<Session | null> {
    const predicates = new relationalStore.RdbPredicates('sessions')
    predicates.equalTo('id', id)
    try {
      const resultSet = await this.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        const session = this.fromResultSet(resultSet)
        resultSet.close()
        return session
      }
      resultSet.close()
      return null
    } catch (err) {
      Logger.error(TAG, `查询会话失败 id=${id} error=${JSON.stringify(err)}`)
      return null
    }
  }

  async getAll(): Promise<Session[]> {
    const predicates = new relationalStore.RdbPredicates('sessions')
    predicates.orderByDesc('updated_at')
    try {
      const resultSet = await this.getStore().query(predicates)
      const sessions: Session[] = []
      while (resultSet.goToNextRow()) {
        sessions.push(this.fromResultSet(resultSet))
      }
      resultSet.close()
      return sessions
    } catch (err) {
      Logger.error(TAG, `查询所有会话失败 error=${JSON.stringify(err)}`)
      return []
    }
  }

  async updateTitle(id: number, title: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('sessions')
    predicates.equalTo('id', id)
    const bucket: relationalStore.ValuesBucket = {
      title: title,
      updated_at: Date.now()
    }
    try {
      await this.getStore().update(bucket, predicates)
    } catch (err) {
      Logger.error(TAG, `更新会话标题失败 id=${id} error=${JSON.stringify(err)}`)
    }
  }

  async incrementMessageCount(id: number): Promise<void> {
    try {
      await this.getStore().executeSql(
        `UPDATE sessions SET message_count = message_count + 1, updated_at = ? WHERE id = ?`,
        [Date.now(), id]
      )
    } catch (err) {
      Logger.error(TAG, `更新消息数失败 id=${id} error=${JSON.stringify(err)}`)
    }
  }

  async delete(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('sessions')
    predicates.equalTo('id', id)
    try {
      await this.getStore().delete(predicates)
      Logger.info(TAG, `会话删除成功 id=${id}`)
    } catch (err) {
      Logger.error(TAG, `会话删除失败 id=${id} error=${JSON.stringify(err)}`)
    }
  }

  private fromResultSet(resultSet: relationalStore.ResultSet): Session {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
      messageCount: resultSet.getLong(resultSet.getColumnIndex('message_count'))
    }
  }
}
