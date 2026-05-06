import Foundation
import SQLite

struct MessageRecord {
    let id: String
    let conversationId: String
    let content: String
    let isUser: Bool
    let createdAt: Date
    let tokens: Int?
}

class MessageStore {
    private let db: Connection
    private let messages = Table("messages")
    private let msgId = Expression<String>("id")
    private let msgConversationId = Expression<String>("conversation_id")
    private let msgContent = Expression<String>("content")
    private let msgIsUser = Expression<Bool>("is_user")
    private let msgCreatedAt = Expression<Double>("created_at")
    private let msgTokens = Expression<Int?>("tokens")

    init(db: Connection) {
        self.db = db
    }

    func create(conversationId: String, content: String, isUser: Bool, tokens: Int? = nil) throws -> MessageRecord {
        let message = MessageRecord(
            id: UUID().uuidString,
            conversationId: conversationId,
            content: content,
            isUser: isUser,
            createdAt: Date(),
            tokens: tokens
        )

        try db.run(messages.insert(
            msgId <- message.id,
            msgConversationId <- message.conversationId,
            msgContent <- message.content,
            msgIsUser <- message.isUser,
            msgCreatedAt <- message.createdAt.timeIntervalSince1970,
            msgTokens <- message.tokens
        ))

        return message
    }

    func fetchByConversationId(_ conversationId: String) throws -> [MessageRecord] {
        return try db.prepare(messages
            .filter(msgConversationId == conversationId)
            .order(msgCreatedAt.asc)
        ).map { row in
            MessageRecord(
                id: row[msgId],
                conversationId: row[msgConversationId],
                content: row[msgContent],
                isUser: row[msgIsUser],
                createdAt: Date(timeIntervalSince1970: row[msgCreatedAt]),
                tokens: row[msgTokens]
            )
        }
    }

    func delete(id: String) throws {
        let message = messages.filter(msgId == id)
        try db.run(message.delete())
    }

    func deleteByConversationId(_ conversationId: String) throws {
        let conversationMessages = messages.filter(msgConversationId == conversationId)
        try db.run(conversationMessages.delete())
    }

    func countByConversationId(_ conversationId: String) throws -> Int {
        let conversationMessages = messages.filter(msgConversationId == conversationId)
        return try db.scalar(conversationMessages.count)
    }
}