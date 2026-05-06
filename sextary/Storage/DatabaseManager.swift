import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?

    // 表定义
    let conversations = Table("conversations")
    let messages = Table("messages")
    let settings = Table("settings")

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

    // settings 列
    let setKey = Expression<String>("key")
    let setValue = Expression<String>("value")
    let setUpdatedAt = Expression<Double>("updated_at")

    private init() {}

    func setup() throws {
        try createDatabase()
        try createTables()
        try createIndexes()
    }

    private func createDatabase() throws {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!

        db = try Connection("\(path)/sextary.sqlite3")
        print("Database created at: \(path)/sextary.sqlite3")
    }

    private func createTables() throws {
        guard let db = db else { return }

        try db.run(conversations.create(ifNotExists: true) { t in
            t.column(convId, primaryKey: true)
            t.column(convTitle)
            t.column(convCreatedAt)
            t.column(convUpdatedAt)
            t.column(convMessageCount, defaultValue: 0)
        })

        try db.run(messages.create(ifNotExists: true) { t in
            t.column(msgId, primaryKey: true)
            t.column(msgConversationId)
            t.column(msgContent)
            t.column(msgIsUser)
            t.column(msgCreatedAt)
            t.column(msgTokens)
            t.foreignKey(msgConversationId, references: conversations, convId, delete: .cascade)
        })

        try db.run(settings.create(ifNotExists: true) { t in
            t.column(setKey, primaryKey: true)
            t.column(setValue)
            t.column(setUpdatedAt)
        })
    }

    private func createIndexes() throws {
        guard let db = db else { return }

        try db.run(messages.createIndex(msgConversationId, ifNotExists: true))
        try db.run(conversations.createIndex(convUpdatedAt, ifNotExists: true))
    }

    func getConnection() throws -> Connection {
        guard let connection = db else {
            throw DatabaseError.connectionNotEstablished
        }
        return connection
    }
}

enum DatabaseError: Error {
    case connectionNotEstablished
    case tableNotFound
    case queryFailed
    case insertFailed
    case updateFailed
    case deleteFailed
}