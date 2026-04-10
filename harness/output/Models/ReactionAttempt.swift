// Models/ReactionAttempt.swift
import Foundation

struct ReactionAttempt: Identifiable, Sendable, Codable {
    let id: UUID
    let reactionTimeMs: Int
    let isCheated: Bool
    let attemptNumber: Int

    init(id: UUID = UUID(), reactionTimeMs: Int, isCheated: Bool, attemptNumber: Int) {
        self.id = id
        self.reactionTimeMs = reactionTimeMs
        self.isCheated = isCheated
        self.attemptNumber = attemptNumber
    }
}
