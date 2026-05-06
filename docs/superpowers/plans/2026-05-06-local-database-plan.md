# 本地数据库功能实施计划

**功能：** sextary 本地数据库存储
**目标：** 实现对话历史持久化和用户设置管理
**日期：** 2026-05-06

---

## 1. 实施概述

### 目标
为 sextary iOS 应用添加本地 SQLite 数据库，实现：
- 对话历史的持久化存储
- 消息的保存和加载
- 用户设置的本地管理

### 架构
- 使用 SQLite.swift 库
- MVVM 架构模式
- 仓储模式（Repository Pattern）

---

## 2. 文件结构

```
sextary/
├── Storage/
│   ├── DatabaseManager.swift      # SQLite 数据库管理
│   ├── ConversationStore.swift    # 对话仓储
│   ├── MessageStore.swift         # 消息仓储
│   └── SettingsStore.swift       # 设置仓储
├── Models/
│   └── ChatMessage.swift          # 扩展数据库字段
```

---

## 3. 实施任务

### Task 1: 添加 SQLite.swift 依赖

**文件：** `sextary.xcodeproj/project.pbxproj` 或使用 SPM

**步骤：**
1. 在 Xcode 中添加 SQLite.swift 包依赖
   - URL: `https://github.com/stephencelis/SQLite.swift.git`
   - 版本: from "0.15.0"

**验证：**
```bash
# 在 Xcode 中验证包已解析
# Build 项目确认无错误
```

---

### Task 2: 创建 DatabaseManager

**文件：** `sextary/Storage/DatabaseManager.swift`

**步骤：**
1. 创建 DatabaseManager 类
   - 管理 SQLite 数据库连接
   - 实现数据库初始化方法
   - 创建表结构（conversations, messages）

**代码结构：**
```swift
import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?

    // 表定义
    let conversations = Table("conversations")
    let messages = Table("messages")

    // conversations 列
    let convId = Expression<String>("id")
    let convTitle = Expression<String>("title")
    let convCreatedAt = Expression<Double>("created_at")
    let convUpdatedAt = Expression<Double>("updated_at")
    let convMessageCount = Expression<Int>("message_count")

    // messages 列
    let msgId = Expression<String>("id")
    let msgConversationId = Expression<String>("conversation_id")
    let msgContent = Expression<String>("content")
    let msgIsUser = Expression<Bool>("is_user")
    let msgCreatedAt = Expression<Double>("created_at")
    let msgTokens = Expression<Int?>("tokens")

    private init() {}

    func setup() throws {
        // 创建数据库文件
        // 创建表
        // 创建索引
    }
}
```

**验证：**
- 编译通过
- 数据库文件成功创建

---

### Task 3: 创建 ConversationStore

**文件：** `sextary/Storage/ConversationStore.swift`

**步骤：**
1. 创建 Conversation 模型结构
2. 实现 ConversationStore 类
   - `create(title:) -> Conversation`
   - `fetchAll() -> [Conversation]`
   - `updateTitle(id:, title:)`
   - `delete(id:)`
   - `updateMessageCount(id:, count:)`

**代码结构：**
```swift
import Foundation
import SQLite

struct Conversation {
    let id: String
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messageCount: Int
}

class ConversationStore {
    private let db: Connection

    func create(title: String) throws -> Conversation
    func fetchAll() throws -> [Conversation]
    func updateTitle(id: String, title: String) throws
    func delete(id: String) throws
    func updateMessageCount(id: String, count: Int) throws
}
```

**验证：**
- 单元测试验证 CRUD 操作
- 创建 → 查询 → 更新 → 删除 流程正常

---

### Task 4: 创建 MessageStore

**文件：** `sextary/Storage/MessageStore.swift`

**步骤：**
1. 创建 Message 模型结构（与 ChatMessage 兼容）
2. 实现 MessageStore 类
   - `create(conversationId:, content:, isUser:) -> Message`
   - `fetchByConversation(id:) -> [Message]`
   - `delete(id:)`
   - `deleteByConversation(id:)` (级联删除)

**代码结构：**
```swift
struct Message {
    let id: String
    let conversationId: String
    let content: String
    let isUser: Bool
    let createdAt: Date
    let tokens: Int?
}

class MessageStore {
    private let db: Connection

    func create(conversationId: String, content: String, isUser: Bool) throws -> Message
    func fetchByConversation(id: String) throws -> [Message]
    func delete(id: String) throws
    func deleteByConversation(id: String) throws
}
```

**验证：**
- 单元测试验证 CRUD 操作
- 消息关联查询正常
- 级联删除正常

---

### Task 5: 创建 SettingsStore

**文件：** `sextary/Storage/SettingsStore.swift`

**步骤：**
1. 实现 SettingsStore 类
   - `save(key:, value:)`
   - `get(key:) -> String?`
   - `delete(key:)`

**代码结构：**
```swift
class SettingsStore {
    private let db: Connection

    func save(key: String, value: String) throws
    func get(key: String) throws -> String?
    func delete(key: String) throws
}
```

**验证：**
- 设置保存和读取正常
- 与 KeychainManager 配合使用

---

### Task 6: 扩展 ChatMessage 模型

**文件：** `sextary/Chat/ChatMessage.swift`

**步骤：**
1. 添加数据库 ID 字段（可选，用于关联）
2. 添加 `createdAt` 字段
3. 添加 `tokens` 字段（可选）

**代码结构：**
```swift
struct ChatMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isUser: Bool
    let createdAt: Date
    let tokens: Int?
    // ... 其他已有字段
}
```

**验证：**
- 与数据库 Message 模型兼容
- 编译通过

---

### Task 7: 集成到 ChatViewModel

**文件：** `sextary/Chat/ChatViewModel.swift`

**步骤：**
1. 添加 DatabaseManager 初始化
2. 添加 ConversationStore 和 MessageStore 实例
3. 修改 `sendMessage()` 保存消息到数据库
4. 修改 `loadMessages()` 从数据库加载
5. 添加对话列表管理
6. 添加新建/删除对话逻辑

**代码结构：**
```swift
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversations: [Conversation] = []
    @Published var currentConversationId: String?

    private var dbManager: DatabaseManager!
    private var conversationStore: ConversationStore!
    private var messageStore: MessageStore!

    func setup() {
        dbManager = DatabaseManager.shared
        try? dbManager.setup()
        conversationStore = ConversationStore(dbManager.db)
        messageStore = MessageStore(dbManager.db)
    }

    func sendMessage() {
        // 保存消息到数据库
        // ...
    }

    func loadMessages() {
        // 从数据库加载
        // ...
    }

    func createNewConversation() {
        // 创建新对话
        // ...
    }

    func deleteConversation(id: String) {
        // 删除对话及消息
        // ...
    }
}
```

**验证：**
- 应用启动无崩溃
- 发送消息自动保存
- 重启后消息可恢复

---

### Task 8: 更新 ChatView 界面

**文件：** `sextary/Chat/ChatView.swift`

**步骤：**
1. 添加对话列表侧边栏（或下拉菜单）
2. 添加新建对话按钮
3. 添加删除对话选项
4. 添加加载历史对话功能

**验证：**
- UI 正常显示
- 对话切换流畅

---

### Task 9: 单元测试

**文件：** `sextaryTests/DatabaseTests.swift` (新建)

**步骤：**
1. 测试 DatabaseManager 初始化
2. 测试 ConversationStore CRUD
3. 测试 MessageStore CRUD
4. 测试数据一致性

**验证：**
```bash
xcodebuild test -scheme sextaryTests -destination 'platform=iOS Simulator,name=iPhone 16'
# 所有测试通过
```

---

## 4. 任务依赖关系

```
Task 1 (添加依赖)
    ↓
Task 2 (DatabaseManager)
    ↓
Task 3 (ConversationStore) ─┐
Task 4 (MessageStore)     │
Task 5 (SettingsStore)    │
    ↓                     │
Task 6 (扩展 ChatMessage)─┘
    ↓
Task 7 (集成到 ViewModel)
    ↓
Task 8 (更新 UI)
    ↓
Task 9 (单元测试)
```

---

## 5. 实施检查清单

- [ ] Task 1: SQLite.swift 依赖添加成功
- [ ] Task 2: DatabaseManager 实现并编译通过
- [ ] Task 3: ConversationStore CRUD 测试通过
- [ ] Task 4: MessageStore CRUD 测试通过
- [ ] Task 5: SettingsStore 实现完成
- [ ] Task 6: ChatMessage 模型扩展完成
- [ ] Task 7: ChatViewModel 集成数据库成功
- [ ] Task 8: ChatView 对话管理 UI 完成
- [ ] Task 9: 所有单元测试通过
- [ ] 应用启动无崩溃
- [ ] 消息持久化正常
- [ ] 对话切换正常

---

## 6. 预估工作量

- Task 1-5（基础设施）: 30 分钟
- Task 6-7（集成）: 45 分钟
- Task 8（UI）: 30 分钟
- Task 9（测试）: 30 分钟

**总计：** 约 2-2.5 小时

---

## 7. 下一步

计划审核通过后，使用 subagent-driven-development 或 executing-plans 执行实施。

---

**计划状态：** 待用户审核