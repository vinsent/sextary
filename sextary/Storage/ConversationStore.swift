import Foundation
import SQLite

struct Conversation: Identifiable {
    let id: String
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messageCount: Int
}

class ConversationStore {
    private let db: Connection
    private let conversations = Table("conversations")
    private let convId = Expression<String>("id")
    private let convTitle = Expression<String>("title")
    private let convCreatedAt = Expression<Double>("created_at")
    private let convUpdatedAt = Expression<Double>("updated_at")
    private let convMessageCount = Expression<Int>("message_count")

    init(db: Connection) {
        self.db = db
    }

    func create(title: String) throws -> Conversation {
        let now = Date()
        let conversation = Conversation(
            id: UUID().uuidString,
            title: title,
            createdAt: now,
            updatedAt: now,
            messageCount: 0
        )

        try db.run(conversations.insert(
            convId <- conversation.id,
            convTitle <- conversation.title,
            convCreatedAt <- conversation.createdAt.timeIntervalSince1970,
            convUpdatedAt <- conversation.updatedAt.timeIntervalSince1970,
            convMessageCount <- conversation.messageCount
        ))

        return conversation
    }

    func fetchAll() throws -> [Conversation] {
        return try db.prepare(conversations.order(convUpdatedAt.desc)).map { row in
            Conversation(
                id: row[convId],
                title: row[convTitle],
                createdAt: Date(timeIntervalSince1970: row[convCreatedAt]),
                updatedAt: Date(timeIntervalSince1970: row[convUpdatedAt]),
                messageCount: row[convMessageCount]
            )
        }
    }

    func fetchById(_ id: String) throws -> Conversation? {
        return try db.pluck(conversations.filter(convId == id)).map { row in
            Conversation(
                id: row[convId],
                title: row[convTitle],
                createdAt: Date(timeIntervalSince1970: row[convCreatedAt]),
                updatedAt: Date(timeIntervalSince1970: row[convUpdatedAt]),
                messageCount: row[convMessageCount]
            )
        }
    }

    func updateTitle(id: String, title: String) throws {
        let conversation = conversations.filter(convId == id)
        try db.run(conversation.update(
            convTitle <- title,
            convUpdatedAt <- Date().timeIntervalSince1970
        ))
    }

    func delete(id: String) throws {
        let conversation = conversations.filter(convId == id)
        try db.run(conversation.delete())
    }

    func updateMessageCount(id: String, count: Int) throws {
        let conversation = conversations.filter(convId == id)
        try db.run(conversation.update(
            convMessageCount <- count,
            convUpdatedAt <- Date().timeIntervalSince1970
        ))
    }
}