import Foundation
import SQLite

class SettingsStore {
    private let db: Connection
    private let settings = Table("settings")
    private let setKey = Expression<String>("key")
    private let setValue = Expression<String>("value")
    private let setUpdatedAt = Expression<Double>("updated_at")

    init(db: Connection) {
        self.db = db
    }

    func save(key: String, value: String) throws {
        let now = Date()
        let existing = settings.filter(setKey == key)

        if try db.pluck(existing) != nil {
            try db.run(existing.update(setValue <- value, setUpdatedAt <- now.timeIntervalSince1970))
        } else {
            try db.run(settings.insert(setKey <- key, setValue <- value, setUpdatedAt <- now.timeIntervalSince1970))
        }
    }

    func get(key: String) throws -> String? {
        return try db.pluck(settings.filter(setKey == key))?[setValue]
    }

    func delete(key: String) throws {
        let setting = settings.filter(setKey == key)
        try db.run(setting.delete())
    }
}