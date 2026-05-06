//
//  ChatMessage.swift
//  sextary
//
//  Created by z z on 2026/4/15.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let createdAt: Date
    let tokens: Int?

    init(id: UUID = UUID(), content: String, isUser: Bool, createdAt: Date = Date(), tokens: Int? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.createdAt = createdAt
        self.tokens = tokens
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content && lhs.isUser == rhs.isUser
    }
}
