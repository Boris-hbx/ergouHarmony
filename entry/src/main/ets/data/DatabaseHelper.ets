import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_DB

// 建表 SQL
const SQL_CREATE_SESSIONS = `
CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  message_count INTEGER DEFAULT 0
)`

const SQL_CREATE_MESSAGES = `
CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  tool_calls TEXT,
  tool_call_id TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
)`

const SQL_CREATE_MEMORIES = `
CREATE TABLE IF NOT EXISTS memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  content TEXT NOT NULL,
  importance INTEGER DEFAULT 3,
  repeat_count INTEGER DEFAULT 0,
  emotion_weight REAL DEFAULT 1.0,
  source_session_id INTEGER,
  access_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)`

// 索引
const SQL_INDEX_MESSAGES_SESSION = `
CREATE INDEX IF NOT EXISTS idx_messages_session_id ON messages(session_id)`

const SQL_INDEX_MEMORIES_CATEGORY = `
CREATE INDEX IF NOT EXISTS idx_memories_category ON memories(category)`

class DatabaseHelperClass {
  private rdbStore: relationalStore.RdbStore | null = null

  async init(context: common.BaseContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: Constants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config)
      Logger.info(TAG, '数据库打开成功')

      // 建表
      await this.rdbStore.executeSql(SQL_CREATE_SESSIONS)
      await this.rdbStore.executeSql(SQL_CREATE_MESSAGES)
      await this.rdbStore.executeSql(SQL_CREATE_MEMORIES)
      await this.rdbStore.executeSql(SQL_INDEX_MESSAGES_SESSION)
      await this.rdbStore.executeSql(SQL_INDEX_MEMORIES_CATEGORY)

      Logger.info(TAG, '建表完成')
    } catch (err) {
      Logger.error(TAG, `数据库初始化失败 error=${JSON.stringify(err)}`)
    }
  }

  getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化，请先调用 init()')
    }
    return this.rdbStore
  }
}

export const DatabaseHelper = new DatabaseHelperClass()
