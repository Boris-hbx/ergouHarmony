# 二狗鸿蒙版 (Ergouh) 工程规范

> **你是二狗H**（鸿蒙端 Agent）。任务令在 `C:\Project\ergouPM\docs\agent-board.md`，看到 `@二狗H` 就是叫你接令。任务看板在 `C:\Project\ergouPM\docs\taskboard.md`。
> **完成任务后必须**：回到任务令文件，在原令下方回复完成内容，将该令移至「已结令」，状态改为 🟢。

Claude Code 每次对话自动加载此文件，所有代码修改必须遵循以下规范。

## 项目概览
- HarmonyOS NEXT 个人 AI 助手，包名 `com.example.ergou`
- 目标设备：华为 Pura X (HarmonyOS 6.0.0 / API 20+)
- 架构：MVVM (ViewModel → Service → DAO/API)
- 技术栈：ArkTS + ArkUI, RDB (relationalStore), @ohos.net.http, Preferences
- LLM：DeepSeek API（SSE 流式）
- 是 Android 版 `C:\Project\ergou\` 的鸿蒙移植版，共享 Next 后端

## 首期功能范围
- 对话界面（二狗 AI 对话 + 工具调用）
- 记账功能（通过对话记账 + 记账页面）
- 其他功能（任务、差旅、健康、英语、灵魂进化等）暂不实施

## 项目目录结构
```
ergouh/
├── entry/src/main/ets/
│   ├── entryability/          # 应用入口
│   ├── pages/                 # 页面 (Index, ChatPage, ExpensePage)
│   ├── viewmodel/             # 状态管理 (@Observed)
│   ├── service/               # 业务逻辑 (LLM, 记账, 工具执行)
│   ├── tool/                  # Tool Use 工具实现
│   ├── model/                 # 数据模型 (interface 定义)
│   ├── data/                  # 数据层 (RDB DAO, 数据库初始化)
│   ├── common/                # 工具类 (日志, Preferences, 常量, 净化)
│   └── components/            # 可复用 UI 组件
├── docs/
│   ├── design/                # 设计文档
│   └── demohtml/              # UI 草稿 (HTML mockup)
└── AppScope/                  # 应用级配置
```

## 1. 代码风格与命名

### 命名规则
| 类型 | 后缀/规则 | 示例 |
|------|----------|------|
| 页面 | Page | `ChatPage.ets` |
| 组件 | 描述性名称 | `MessageBubble.ets` |
| ViewModel | ViewModel | `ChatViewModel.ets` |
| Service | Service/Client | `LLMClient.ets`, `ExpenseService.ets` |
| 工具 | Tool | `AddExpenseTool.ets` |
| DAO | Dao | `MessageDao.ets` |
| 模型 | Models | `ChatModels.ets` |
| 常量 | Constants | `Constants.ets` |

### 文件组织
- 一个类/组件一个文件，文件名 = 类名/组件名
- 接口定义按领域分组放 `model/` 目录
- 常量集中到 `common/Constants.ets`

## 2. 日志规范
- 统一使用 `hilog`，封装在 `common/Logger.ets`
- 日志格式：`[模块] 操作描述 key=value`
- domain 统一使用 `0xFF00`，tag 按模块区分
- **禁止输出敏感信息**：API Key、用户隐私数据、完整 prompt

## 3. 错误处理
- Service 层 catch 底层异常，转为业务错误信息
- ViewModel 层 catch 业务错误，更新 UI 状态
- UI 层只展示状态，不做异常处理
- 网络请求失败指数退避重试，最多 3 次（1s → 2s → 4s）
- 非幂等操作不重试

## 4. 安全规范
- DeepSeek API Key 内置（Constants.ets），首次启动只需登录 Next 账号
- 用户数据本地存储，对话内容不上传
- 用户输入注入 prompt 前经过 `PromptSanitizer.sanitize()`
- 禁止日志输出敏感信息

## 5. 状态管理
- ViewModel 使用 `@Observed` 装饰器
- 页面使用 `@State` 持有 ViewModel 实例
- 子组件通过 `@ObjectLink` 或 `@Prop` 接收数据
- 列表使用 `List` + `ForEach` 并提供 key

## 6. 数据层
- 本地数据用 `@ohos.data.relationalStore` (RDB)
- 配置数据用 `@ohos.data.preferences`
- 远程数据通过 `@ohos.net.http` 调用
- 数据库操作在异步上下文中执行

## 7. 共享定义与多端协调
- 系统 Prompt、工具定义、API 接口的唯一来源：`C:\Project\ergouPM\`
- 修改共享定义时，先更新 ergouPM，再同步到本工程
- 共享 Next 后端 API（记账等功能）
- 系统 Prompt 保持一致（参考 `ergouPM/llm/system-prompt.md`）
- 工具定义保持一致（参考 `ergouPM/llm/tools.json`）
- UI 风格适配 HarmonyOS 设计语言，不强求与 Android 版一致

## 8. Git 规范
- 提交信息格式：`type: 简短描述`
- type：feat / fix / refactor / docs / chore / test
- 中文描述，简洁明了
