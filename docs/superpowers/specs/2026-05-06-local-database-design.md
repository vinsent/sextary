# 本地数据库功能设计文档

**日期：** 2026-05-06
**版本：** v1.0
**项目：** sextary - iOS AI 聊天应用

---

## 1. 需求概述

为 sextary 应用添加本地数据库功能，实现对话历史的持久化存储和用户设置管理。

---

## 2. 数据库选择决策

### 2.1 方案对比

| 方案 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| 仅 SQLite | 对话历史 + 设置 | 轻量、成熟、稳定 | 无法做语义搜索 |
| SQLite + 向量数据库 | + RAG/文档问答 | 支持语义搜索 | 增加复杂度 |
| 仅向量数据库 | RAG 场景 | 向量检索强大 | 不适合结构化数据 |

### 2.2 最终决策

**采用 SQLite 作为本地数据库，向量数据库作为 Phase 2 可选扩展**

**理由：**
1. 对话历史是结构化数据，SQLite 是最佳选择
2. iOS 平台 SQLite 支持成熟（SQLite.swift）
3. 避免前期过度设计（YAGNI）
4. Phase 2 可根据需求再引入向量数据库

---

## 3. 数据模型设计

### 3.1 对话历史（Conversation）

```swift
struct Conversation {
    let id: String           // UUID，主键
    let title: String        // 对话标题（可AI生成或首条消息）
    let createdAt: Date      // 创建时间
    let updatedAt: Date      // 最后更新时间
    let messageCount: Int    // 消息数量
}
```

### 3.2 消息（Message）

```swift
struct Message {
    let id: String           // UUID，主键
    let conversationId: String  // 外键，关联会话
    let content: String      // 消息内容
    let isUser: Bool        // true=用户，false=AI
    let createdAt: Date     // 发送时间
    let tokens: Int?        // Token 数量（可选）
}
```

### 3.3 用户设置（UserSettings）

```swift
struct UserSettings {
    let key: String         // 设置键
    let value: String       // 设置值
    let updatedAt: Date      // 更新时间
}

// 示例设置：
// - "theme": "dark" | "light"
// - "api_key": "***" (已加密存储于 Keychain)
// - "default_model": "kimi-k2.5"
```

---

## 4. 架构设计

### 4.1 目录结构

```
sextary/
├── Storage/
│   ├── DatabaseManager.swift      # SQLite 数据库管理
│   ├── ConversationStore.swift    # 对话仓储
│   ├── MessageStore.swift         # 消息仓储
│   └── SettingsStore.swift        # 设置仓储
├── Models/
│   └── (已有) ChatMessage.swift   # 扩展支持数据库
├── ViewModels/
│   └── (已有) ChatViewModel.swift  # 集成数据库操作
```

### 4.2 组件职责

| 组件 | 职责 |
|------|------|
| `DatabaseManager` | SQLite 连接管理、数据库初始化、表创建 |
| `ConversationStore` | 对话 CRUD 操作 |
| `MessageStore` | 消息 CRUD 操作 |
| `SettingsStore` | 用户设置读写 |

### 4.3 数据流

```
UI (ChatView)
    ↓
ViewModel (ChatViewModel)
    ↓
Stores (ConversationStore / MessageStore)
    ↓
DatabaseManager (SQLite)
```

---

## 5. 技术选型

### 5.1 依赖库

**SQLite.swift** - iOS SQLite 封装库
- 纯 Swift 实现
- 类型安全
- Swift Package Manager 支持
- 活跃维护

### 5.2 集成方式

通过 Swift Package Manager 集成：

```swift
// Package.swift 或 Xcode SPM
.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
```

---

## 6. 数据库 Schema

### 6.1 表创建 SQL

```sql
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    message_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    content TEXT NOT NULL,
    is_user INTEGER NOT NULL,
    created_at REAL NOT NULL,
    tokens INTEGER,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);
```

---

## 7. 功能列表

### 7.1 Phase 1（当前实现）

- [ ] 数据库初始化和版本管理
- [ ] 对话创建、列表查询、更新标题
- [ ] 消息保存和加载
- [ ] 新建对话
- [ ] 删除对话（级联删除消息）
- [ ] 加载历史对话

### 7.2 Phase 2（未来扩展）

- [ ] 对话搜索（按关键词）
- [ ] 导出对话为 Markdown/PDF
- [ ] 消息编辑和删除
- [ ] 多设备同步（云端）

### 7.3 未来可选（RAG）

- [ ] 文档上传和向量化
- [ ] 基于上下文的问答
- [ ] 向量相似度搜索

---

## 8. 错误处理

| 场景 | 处理方式 |
|------|---------|
| 数据库创建失败 | 提示用户，应用退出 |
| 写入失败 | 重试 3 次，失败后提示错误 |
| 读取失败 | 返回空数据，提示用户 |
| 数据损坏 | 提供清除数据选项 |

---

## 9. 性能考量

1. **批量写入**：多条消息合并为一个事务
2. **分页加载**：对话消息超过 100 条时分页
3. **懒加载**：仅在需要时加载历史数据
4. **索引优化**：为常用查询创建索引

---

## 10. 测试计划

1. **单元测试**
   - DatabaseManager 初始化
   - 各 Store 的 CRUD 操作
   - 数据一致性验证

2. **集成测试**
   - 对话完整生命周期（创建→发消息→加载→删除）
   - 多会话并发操作

---

## 11. 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 数据丢失 | 高 | 定期备份（未来支持） |
| 数据库迁移 | 中 | 版本管理，迁移脚本 |
| 性能问题 | 中 | 索引、分页、懒加载 |

---

## 12. 后续步骤

1. 创建实施计划（writing-plans）
2. 实现数据库管理层
3. 实现各仓储层
4. 集成到现有 ViewModel
5. 测试验证

---

**文档状态：** 已完成，等待用户审核后进入实施阶段