export class Constants {
  // Claude API
  // API Key 在 Secrets.ets 中（已 gitignore）
  static readonly CLAUDE_API_URL: string = 'https://api.anthropic.com/v1/messages'
  static readonly CLAUDE_MODEL: string = 'claude-sonnet-4-20250514'
  static readonly CLAUDE_API_VERSION: string = '2023-06-01'

  // LLM 参数
  static readonly LLM_TEMPERATURE: number = 0.7
  static readonly LLM_MAX_TOKENS: number = 2048
  static readonly LLM_CONTEXT_MESSAGES: number = 20

  // Next 后端
  static readonly NEXT_API_BASE_URL: string = 'https://next-boris.fly.dev/api'

  // 数据库
  static readonly DB_NAME: string = 'ergou.db'
  static readonly DB_VERSION: number = 1

  // Preferences
  static readonly PREFERENCES_NAME: string = 'ergou_settings'

  // Preferences Keys
  static readonly KEY_SESSION_TOKEN: string = 'next_session_token'
  static readonly KEY_USERNAME: string = 'next_username'
  static readonly KEY_THEME_MODE: string = 'theme_mode'

  // 网络重试
  static readonly MAX_RETRY_COUNT: number = 3
  static readonly RETRY_BASE_DELAY_MS: number = 1000

  // 日志 tag
  static readonly TAG_ENTRY: string = 'EntryAbility'
  static readonly TAG_DB: string = 'Database'
  static readonly TAG_PREFS: string = 'Preferences'
  static readonly TAG_LLM: string = 'LLMClient'
  static readonly TAG_CHAT: string = 'ChatService'
  static readonly TAG_EXPENSE: string = 'ExpenseService'
  static readonly TAG_TOOL: string = 'ToolExecutor'
}
