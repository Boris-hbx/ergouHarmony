# 二狗鸿蒙版 系统设计

> 目标设备：华为 Pura X (HarmonyOS 6.0.0 / API 20+)
> 开发语言：ArkTS
> 首期范围：对话界面 + 记账功能

---

## 1. 整体架构

```
┌─────────────────────────────────────────────────┐
│                    UI 层 (ArkUI)                 │
│  ┌──────────────┐  ┌──────────────┐             │
│  │  ChatPage    │  │ ExpensePage  │             │
│  └──────┬───────┘  └──────┬───────┘             │
│         │                  │                     │
├─────────┼──────────────────┼─────────────────────┤
│         ▼                  ▼                     │
│              ViewModel 层 (状态管理)              │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ChatViewModel │  │ExpenseVM     │             │
│  └──────┬───────┘  └──────┬───────┘             │
│         │                  │                     │
├─────────┼──────────────────┼─────────────────────┤
│         ▼                  ▼                     │
│              Service 层 (业务逻辑)                │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ChatService   │  │ExpenseService│             │
│  │  ├ LLMClient │  └──────┬───────┘             │
│  │  ├ ToolExec  │         │                     │
│  │  └ MemoryMgr │         │                     │
│  └──────┬───────┘         │                     │
│         │                 │                      │
├─────────┼─────────────────┼──────────────────────┤
│         ▼                 ▼                      │
│              数据层 (Data)                        │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ LocalDB      │  │ NextApi      │             │
│  │ (RDB/Prefs)  │  │ (HTTP)       │             │
│  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────┘
```

### 架构原则
- **MVVM**：与 Android 版保持一致的分层思想
- **单向数据流**：UI → Event → ViewModel → State → UI
- **本地优先**：对话数据、记忆存本地 RDB，记账走 Next API（与 Android 版共享后端）
- **隐私第一**：API Key 存 Preferences，不上传用户对话内容

---

## 2. 目录结构

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets              # 应用入口
├── pages/
│   ├── Index.ets                     # 主页（导航容器）
│   ├── ChatPage.ets                  # 对话页面
│   └── ExpensePage.ets               # 记账页面
├── viewmodel/
│   ├── ChatViewModel.ets             # 对话状态管理
│   └── ExpenseViewModel.ets          # 记账状态管理
├── service/
│   ├── LLMClient.ets                 # DeepSeek API 调用（SSE 流式）
│   ├── ChatService.ets               # 对话业务逻辑（上下文组装、记忆提取）
│   ├── ExpenseService.ets            # 记账业务（调用 Next API）
│   ├── NextApiClient.ets             # Next 后端 HTTP 客户端
│   ├── ToolExecutor.ets              # 工具调度器
│   └── ErgouPrompt.ets               # 系统 Prompt 定义
├── tool/
│   ├── Tool.ets                      # Tool 接口定义
│   ├── ToolRegistry.ets              # 工具注册表
│   ├── AddExpenseTool.ets            # 记账工具
│   ├── ExpenseSummaryTool.ets        # 记账汇总工具
│   ├── QueryExpensesTool.ets         # 查询记账工具
│   ├── DeleteExpenseTool.ets         # 删除记账工具
│   ├── GetDateTimeTool.ets           # 获取当前时间
│   ├── SimpleCalculateTool.ets       # 计算器
│   └── SaveMemoryTool.ets            # 记忆保存工具
├── model/
│   ├── ChatModels.ets                # 对话相关数据模型
│   ├── ExpenseModels.ets             # 记账相关数据模型
│   ├── LLMModels.ets                 # LLM 请求/响应模型
│   └── ToolModels.ets                # 工具定义模型
├── data/
│   ├── DatabaseHelper.ets            # RDB 数据库管理
│   ├── SessionDao.ets                # 会话 DAO
│   ├── MessageDao.ets                # 消息 DAO
│   └── MemoryDao.ets                 # 记忆 DAO
├── common/
│   ├── Constants.ets                 # 常量定义
│   ├── Logger.ets                    # 日志工具（封装 hilog）
│   ├── PreferencesUtil.ets           # Preferences 工具（存 API Key 等）
│   └── PromptSanitizer.ets           # 输入净化
└── components/
    ├── MessageBubble.ets             # 消息气泡组件
    ├── ChatInputBar.ets              # 输入栏组件
    ├── MarkdownText.ets              # Markdown 渲染组件
    ├── ExpenseCard.ets               # 记账卡片组件
    ├── ExpenseSummaryCard.ets        # 记账摘要卡片
    └── TagFilterBar.ets              # 标签筛选栏
```

---

## 3. 数据模型

### 3.1 对话相关

```typescript
// 会话
interface Session {
  id: number
  title: string
  createdAt: number    // timestamp ms
  updatedAt: number
  messageCount: number
}

// 消息
interface ChatMessage {
  id: number
  sessionId: number
  role: 'system' | 'user' | 'assistant' | 'tool'
  content: string
  createdAt: number
  toolCalls?: ToolCall[]     // assistant 消息中的工具调用
  toolCallId?: string        // tool 消息的关联 ID
}

// 记忆
interface Memory {
  id: number
  category: 'fact' | 'habit' | 'personality' | 'intent'
  content: string
  importance: number         // 1-5
  repeatCount: number
  emotionWeight: number      // 0.5-2.0
  sourceSessionId: number
  accessCount: number
  createdAt: number
  updatedAt: number
}
```

### 3.2 LLM 请求/响应

```typescript
// 请求
interface ChatRequest {
  model: string              // "deepseek-chat"
  messages: LLMMessage[]
  stream: boolean
  temperature: number        // 0.7
  max_tokens: number         // 2048
  tools?: ToolDefinition[]
}

interface LLMMessage {
  role: string
  content: string | null
  tool_calls?: ToolCall[]
  tool_call_id?: string
}

// 工具定义
interface ToolDefinition {
  type: 'function'
  function: {
    name: string
    description: string
    parameters: object       // JSON Schema
  }
}

// 工具调用
interface ToolCall {
  id: string
  type: 'function'
  function: {
    name: string
    arguments: string        // JSON string
  }
}

// SSE 流式响应 chunk
interface ChatResponseChunk {
  id: string
  choices: [{
    index: number
    delta: {
      role?: string
      content?: string
      tool_calls?: ToolCall[]
    }
    finish_reason: string | null
  }]
}
```

### 3.3 记账相关

```typescript
interface ExpenseEntry {
  id: string
  amount: number
  notes: string
  tags: string[]
  currency: 'CAD' | 'CNY' | 'USD'
  date: string              // "2026-03-11"
  createdAt: string
}

interface ExpenseSummary {
  totalAmount: number
  count: number
  currency: string
  period: string
  comparison?: string       // 与上期对比
}
```

---

## 4. 核心流程

### 4.1 对话流程

```
用户输入消息
    │
    ▼
ChatPage → ChatViewModel.sendMessage(text)
    │
    ▼
ChatService.sendMessage(sessionId, text)
    ├─ 1. 保存用户消息到本地 RDB
    ├─ 2. 加载最近 20 条历史消息
    ├─ 3. 检索相关记忆 (MemoryDao)
    ├─ 4. 组装 system prompt + 记忆 + 历史 + 用户消息
    ├─ 5. 附加 tools 定义（记账等工具）
    ├─ 6. 调用 LLMClient.chatStream(request)
    │      │
    │      ▼
    │   DeepSeek API (SSE)
    │      ├─ 逐 chunk 返回文本 → 更新 streamingContent
    │      └─ 返回 tool_calls → 进入工具执行
    │
    ├─ 7. [如有 tool_calls] ToolExecutor 执行
    │      ├─ 解析工具名 + 参数
    │      ├─ ToolRegistry 查找并执行对应 Tool
    │      ├─ 将结果作为 tool message 追加
    │      └─ 再次调用 LLM 获取最终回复
    │
    ├─ 8. 提取记忆标记 [SAVE_MEMORY:...]
    ├─ 9. 保存助手消息到本地 RDB
    └─ 10. 更新 UI 状态
```

### 4.2 记账流程（通过对话）

```
用户："帮我记一笔，午饭 35 块"
    │
    ▼
LLM 识别意图 → 返回 tool_calls: add_expense
    │
    ▼
ToolExecutor → AddExpenseTool.execute({
  amount: 35,
  notes: "午饭",
  currency: "CNY",
  tags: ["餐饮"],
  date: "2026-03-11"
})
    │
    ▼
ExpenseService → NextApiClient.createExpense(request)
    │
    ▼
返回结果 → LLM 生成确认回复
"已记录：午饭 ¥35.00 #餐饮"
```

### 4.3 记账页面流程

```
用户进入 ExpensePage
    │
    ▼
ExpenseViewModel.loadExpenses()
    ├─ ExpenseService.getExpenses(month)
    │   └─ NextApiClient.getExpenses()
    ├─ ExpenseService.getSummary(month)
    │   └─ NextApiClient.getExpenseSummary()
    └─ ExpenseService.getTags()
        └─ NextApiClient.getExpenseTags()
    │
    ▼
UI 渲染：
├─ 摘要卡片（本月总额 + 条目数）
├─ 标签筛选栏（FlowRow FilterChip）
└─ 记账列表（按日期分组）
```

---

## 5. 页面设计

### 5.1 导航结构

**不使用底部 Tab**，采用顶栏 ≡ 汉堡菜单 + 侧边抽屉的方式导航：

- 主页即对话页面 (ChatPage)，是唯一的主屏幕
- 顶栏：左 ≡ 汉堡菜单 + "二狗"标题，右 🕐历史 + ⚙设置
- ≡ 点击展开侧边抽屉，包含功能入口：对话（默认）、记账、其余待开发
- 功能页面（如记账）通过 `router.pushUrl` 跳转，顶栏有 ← 返回

### 5.2 对话页面 (ChatPage.ets / 主页)

```
┌─────────────────────────────┐
│  ≡  二狗               🕐 ⚙│  ← 顶栏
├─────────────────────────────┤
│                             │
│           用户气泡（右对齐） │
│                             │
│  助手气泡（左对齐）         │
│  支持 Markdown / 流式显示   │
│  📋 👍 👎 🔄               │  ← 消息操作
│                             │
│  ...消息列表 (List)...      │
│                             │
├─────────────────────────────┤
│ [任务] [例行] [记账] [出差] │  ← 快捷栏（横向滚动 Chip）
├─────────────────────────────┤
│ ┌─────────────────────┐  ▶ │  ← 输入栏 + 发送按钮
│ │ 说点什么...          │    │
│ └─────────────────────┘    │
└─────────────────────────────┘
```

**快捷栏：**
- 位于输入框上方，横向滚动
- 首期"记账"可用（点击跳转记账页），其余灰色待开发
- Chip 圆角 18vp，边框 1px，14fp 字号

**核心交互：**
- List 组件展示消息列表，自动滚动到底部
- 流式回复逐字追加，末尾闪烁光标 |
- 消息操作：复制、点赞、点踩、重新生成（参照 Android 版）
- 发送按钮：有内容蓝色可点，无内容灰色 disabled
- 停止生成：流式中发送按钮变红色方块
- 空状态显示二狗 Logo + 欢迎语 + 建议话题

### 5.3 侧边抽屉 (Drawer)

```
┌──────────────┬──────────┐
│  🐕           │          │
│  二狗 v1.0    │  遮罩    │
│ ─────────── │          │
│  💬 对话 ◄   │          │
│  💰 记账      │          │
│ ─────────── │          │
│  📝 任务 待开发│         │
│  📅 例行 待开发│         │
│  ✈️ 出差 待开发│         │
│  🔤 英语 待开发│         │
│  🧘 养生 待开发│         │
│ ─────────── │          │
│  ⚙ 设置      │          │
└──────────────┴──────────┘
```

- 宽度 280vp，左侧滑出
- 可用项正常色，待开发项灰色 + "待开发" badge
- 点击遮罩 / 左滑 / 选择菜单项后关闭

### 5.4 记账页面 (ExpensePage.ets)

```
┌─────────────────────────────┐
│  ←        记账               │  ← 顶栏（返回按钮）
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  本月支出    ¥3,456.78  │ │  ← 摘要卡片（渐变蓝）
│ │  42 笔  日均¥314  +12%  │ │
│ └─────────────────────────┘ │
│                             │
│ [全部] [餐饮] [交通] [购物] │  ← 标签筛选
│                             │
│ ── 3月11日 小计 ¥85 ─────  │  ← 日期分组
│ │ 🍜 午饭    -¥35.00      │ │
│ │ 🚗 打车    -¥50.00      │ │
│ ...                         │
│                         [+] │  ← FAB 添加按钮
└─────────────────────────────┘
```

**核心交互：**
- 从抽屉菜单进入，顶栏 ← 返回对话
- 摘要卡片：本月总额 + 条目数 + 日均 + 同比
- 标签筛选：横向滚动 Chip
- 列表按日期分组，每组显示当日小计
- FAB 打开底部半屏添加弹窗
- 左滑删除

---

## 6. 关键技术方案

### 6.1 SSE 流式通信

HarmonyOS 使用 `@ohos.net.http` 模块发起 HTTP 请求。流式 SSE 处理方案：

```typescript
// LLMClient.ets 核心逻辑
import { http } from '@kit.NetworkKit'

chatStream(request: ChatRequest): void {
  let httpRequest = http.createHttp()

  httpRequest.on('dataReceive', (data: ArrayBuffer) => {
    // 将 ArrayBuffer 转为字符串
    // 按行解析 SSE: "data: {...}"
    // 解析 JSON chunk → 提取 delta.content / delta.tool_calls
    // 通过回调或 Emitter 通知 ViewModel 更新
  })

  httpRequest.requestInStream(url, {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    extraData: JSON.stringify(request)
  })
}
```

### 6.2 本地数据库 (关系型数据库 RDB)

使用 `@ohos.data.relationalStore` 存储对话和记忆数据：

```sql
-- sessions 表
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  message_count INTEGER DEFAULT 0
);

-- messages 表
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  tool_calls TEXT,           -- JSON string
  tool_call_id TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);

-- memories 表
CREATE TABLE memories (
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
);
```

### 6.3 Preferences 存储

用于存储登录状态等轻量配置：

```typescript
// PreferencesUtil.ets
import { preferences } from '@kit.ArkData'

const STORE_NAME = 'ergou_settings'

// 存储项
- next_session_token: string
- next_username: string
- theme_mode: string         // 'light' | 'dark' | 'system'
```

> 注意：DeepSeek API Key 内置在应用中，不需要用户配置。

### 6.4 工具系统

```typescript
// Tool 接口
interface Tool {
  name: string
  description: string
  parameters: object          // JSON Schema
  execute(args: Record<string, string>): Promise<string>
  toDefinition(): ToolDefinition
}

// ToolRegistry - 注册所有可用工具
class ToolRegistry {
  private tools: Map<string, Tool> = new Map()

  register(tool: Tool): void
  getTool(name: string): Tool | undefined
  getAllDefinitions(): ToolDefinition[]
  executeTool(name: string, args: Record<string, string>): Promise<string>
}
```

首期注册的工具：
| 工具名 | 说明 | 调用后端 |
|--------|------|----------|
| `add_expense` | 记账 | Next API |
| `expense_summary` | 月度汇总 | Next API |
| `query_expenses` | 查询记录 | Next API |
| `delete_expense` | 删除记录 | Next API |
| `save_memory` | 保存记忆 | 本地 RDB |
| `search_memory` | 搜索记忆 | 本地 RDB |
| `get_date_time` | 当前时间 | 本地 |
| `simple_calculate` | 计算器 | 本地 |

### 6.5 状态管理

使用 `@Observed` / `@ObjectLink` / `@State` / `@Prop` 装饰器管理状态：

```typescript
// ChatViewModel.ets
@Observed
export class ChatViewModel {
  messages: ChatMessage[] = []
  streamingContent: string = ''
  isLoading: boolean = false
  currentSessionId: number = -1
  errorMessage: string = ''

  async sendMessage(content: string): Promise<void> { ... }
  async loadSession(sessionId: number): Promise<void> { ... }
  stopGenerating(): void { ... }
}

// ExpenseViewModel.ets
@Observed
export class ExpenseViewModel {
  expenses: ExpenseEntry[] = []
  summary: ExpenseSummary | null = null
  tags: string[] = []
  selectedTag: string = '全部'
  isLoading: boolean = false

  async loadExpenses(): Promise<void> { ... }
  async addExpense(entry: Partial<ExpenseEntry>): Promise<void> { ... }
  async deleteExpense(id: string): Promise<void> { ... }
  filterByTag(tag: string): void { ... }
}
```

---

## 7. 与 Android 版的差异

| 维度 | Android 版 | 鸿蒙版 |
|------|-----------|--------|
| 语言 | Kotlin | ArkTS |
| UI 框架 | Jetpack Compose | ArkUI |
| 数据库 | Room (SQLite) | RDB (relationalStore) |
| 网络库 | Ktor Client | @ohos.net.http |
| 键值存储 | DataStore | Preferences |
| DI | Koin | 手动注入 / 单例模式 |
| 日志 | Timber | hilog |
| 序列化 | kotlinx.serialization | JSON.parse/stringify |
| 状态管理 | StateFlow | @State/@Observed |
| 导航 | NavHost | Tabs + Navigation |

---

## 8. 首期不做的功能

以下功能在首期**不实施**，留待后续迭代：
- 任务管理 (Task)
- 差旅报销 (Trip)
- 日常习惯 (Routine)
- 英语学习 (English)
- 健康养生 (Health)
- 灵魂进化 (Soul Evolution)
- 记忆浏览页面（记忆存储和检索仍在，但无独立页面）
- 设置页面（API Key 首次启动时弹窗输入即可）
- 多模型切换（仅 DeepSeek）
- 图片/语音输入

---

## 9. 实施阶段

### Phase 1：基础框架（~2天）
- [ ] 项目目录结构搭建
- [ ] 常量、日志、Preferences 工具类
- [ ] RDB 数据库初始化（3 张表）
- [ ] DAO 层实现
- [ ] 主页 Tabs 导航

### Phase 2：对话功能（~4天）
- [ ] LLMClient：DeepSeek API 调用 + SSE 流式解析
- [ ] ErgouPrompt：系统 Prompt 移植
- [ ] ChatService：上下文组装、消息管理
- [ ] 工具系统：Tool 接口 + Registry + Executor
- [ ] ChatViewModel：状态管理
- [ ] ChatPage UI：消息列表 + 输入栏 + 流式显示
- [ ] MessageBubble：气泡组件 + Markdown 渲染
- [ ] 会话管理（新建/切换/历史）

### Phase 3：记账功能（~3天）
- [ ] NextApiClient：HTTP 客户端 + 认证
- [ ] ExpenseService：CRUD 操作
- [ ] 记账工具（4个 Tool 实现）
- [ ] ExpenseViewModel：状态管理
- [ ] ExpensePage UI：摘要 + 筛选 + 列表 + 添加
- [ ] 通过对话记账的端到端流程打通

### Phase 4：打磨（~1天）
- [ ] 首次启动 API Key 配置流程
- [ ] Next 账号登录流程
- [ ] 错误处理 & 空状态
- [ ] 输入净化 (PromptSanitizer)
- [ ] 基础测试
- [ ] 签名打包
