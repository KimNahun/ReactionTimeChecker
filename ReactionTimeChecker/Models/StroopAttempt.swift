// Models/StroopAttempt.swift
import Foundation

struct StroopAttempt: Identifiable, Sendable, Codable {
    let id: UUID
    let reactionTimeMs: Int   // 0 if user didn't tap
    let wasTarget: Bool       // Was the font color the target?
    let didTap: Bool          // Did user tap?

    /// Correct = tapped a target OR didn't tap a non-target
    var isCorrect: Bool {
        (wasTarget && didTap) || (!wasTarget && !didTap)
    }

    /// Missed target (should have tapped but didn't)
    var isMiss: Bool {
        wasTarget && !didTap
    }

    /// False alarm (tapped a non-target)
    var isFalseAlarm: Bool {
        !wasTarget && didTap
    }

    init(id: UUID = UUID(), reactionTimeMs: Int, wasTarget: Bool, didTap: Bool) {
        self.id = id
        self.reactionTimeMs = reactionTimeMs
        self.wasTarget = wasTarget
        self.didTap = didTap
    }
}
