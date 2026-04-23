// Models/TimeSenseSession.swift
import Foundation

struct TimeSenseAttempt: Identifiable, Sendable {
    let id: UUID
    let actualTimeMs: Int
    let targetTimeMs: Int
    var errorMs: Int { abs(actualTimeMs - targetTimeMs) }

    init(id: UUID = UUID(), actualTimeMs: Int, targetTimeMs: Int = 10000) {
        self.id = id
        self.actualTimeMs = actualTimeMs
        self.targetTimeMs = targetTimeMs
    }
}

struct TimeSenseSession: Sendable {
    let attempts: [TimeSenseAttempt]
    let timerVisible: Bool
    let averageErrorMs: Int
    let bestErrorMs: Int
    let worstErrorMs: Int

    init(attempts: [TimeSenseAttempt], timerVisible: Bool) {
        self.attempts = attempts
        self.timerVisible = timerVisible
        let errors = attempts.map { $0.errorMs }
        self.averageErrorMs = errors.isEmpty ? 0 : errors.reduce(0, +) / errors.count
        self.bestErrorMs = errors.min() ?? 0
        self.worstErrorMs = errors.max() ?? 0
    }
}
