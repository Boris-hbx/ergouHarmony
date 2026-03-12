import { relationalStore } from '@kit.ArkData'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { DatabaseHelper } from './DatabaseHelper'
import { ChatMessage, CreateMessageParams } from '../model/ChatModels'
import { ToolCall } from '../model/LLMModels'

const TAG = Constants.TAG_DB

export class MessageDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async create(message: CreateMessageParams): Promise<number> {
    const bucket: relationalStore.ValuesBucket = {
      session_id: message.sessionId,
      role: message.role,
      content: message.content,
      created_at: message.createdAt,
      tool_calls: message.toolCalls ? JSON.stringify(message.toolCalls) : null,
      tool_call_id: message.toolCallId ?? null
    }
    try {
      const rowId = await this.getStore().insert('messages', bucket)
      return rowId
    } catch (err) {
      Logger.error(TAG, `消息创建失败 error=${JSON.stringify(err)}`)
      throw new Error(JSON.stringify(err))
    }
  }

  async getBySessionId(sessionId: number, limit: number = 20): Promise<ChatMessage[]> {
    try {
      // 取最新的 limit 条，按时间正序返回
      const resultSet = await this.getStore().querySql(
        `SELECT * FROM (
          SELECT * FROM messages WHERE session_id = ? ORDER BY created_at DESC LIMIT ?
        ) sub ORDER BY created_at ASC`,
        [sessionId.toString(), limit.toString()]
      )
      const messages: ChatMessage[] = []
      while (resultSet.goToNextRow()) {
        messages.push(this.fromResultSet(resultSet))
      }
      resultSet.close()
      return messages
    } catch (err) {
      Logger.error(TAG, `查询消息失败 sessionId=${sessionId} error=${JSON.stringify(err)}`)
      return []
    }
  }

  async getCountBySessionId(sessionId: number): Promise<number> {
    try {
      const resultSet = await this.getStore().querySql(
        `SELECT COUNT(*) as cnt FROM messages WHERE session_id = ?`,
        [sessionId.toString()]
      )
      if (resultSet.goToFirstRow()) {
        const count = resultSet.getLong(resultSet.getColumnIndex('cnt'))
        resultSet.close()
        return count
      }
      resultSet.close()
      return 0
    } catch (err) {
      Logger.error(TAG, `查询消息数失败 sessionId=${sessionId} error=${JSON.stringify(err)}`)
      return 0
    }
  }

  async deleteBySessionId(sessionId: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('messages')
    predicates.equalTo('session_id', sessionId)
    try {
      await this.getStore().delete(predicates)
    } catch (err) {
      Logger.error(TAG, `删除会话消息失败 sessionId=${sessionId} error=${JSON.stringify(err)}`)
    }
  }

  private fromResultSet(resultSet: relationalStore.ResultSet): ChatMessage {
    const toolCallsStr = resultSet.getString(resultSet.getColumnIndex('tool_calls'))
    let toolCalls: ToolCall[] | undefined = undefined
    if (toolCallsStr) {
      try {
        toolCalls = JSON.parse(toolCallsStr) as ToolCall[]
      } catch {
        // 解析失败忽略
      }
    }

    const toolCallId = resultSet.getString(resultSet.getColumnIndex('tool_call_id'))

    return new ChatMessage(
      resultSet.getLong(resultSet.getColumnIndex('id')),
      resultSet.getLong(resultSet.getColumnIndex('session_id')),
      resultSet.getString(resultSet.getColumnIndex('role')) as 'system' | 'user' | 'assistant' | 'tool',
      resultSet.getString(resultSet.getColumnIndex('content')),
      resultSet.getLong(resultSet.getColumnIndex('created_at')),
      toolCalls,
      toolCallId || undefined
    )
  }
}
