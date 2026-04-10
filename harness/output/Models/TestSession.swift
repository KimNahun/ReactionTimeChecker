// Models/TestSession.swift

struct TestSession: Sendable {
    let attempts: [ReactionAttempt]
    let validAttempts: [ReactionAttempt]
    let averageMs: Int
    let bestMs: Int
    let worstMs: Int
    let cheatedCount: Int
    let rounds: Int

    init(attempts: [ReactionAttempt], rounds: Int) {
        self.attempts = attempts
        self.rounds = rounds
        let valid = attempts.filter { !$0.isCheated }
        self.validAttempts = valid
        self.cheatedCount = attempts.filter { $0.isCheated }.count

        if valid.isEmpty {
            self.averageMs = 0
            self.bestMs = 0
            self.worstMs = 0
        } else {
            let times = valid.map { $0.reactionTimeMs }
            self.averageMs = times.reduce(0, +) / times.count
            self.bestMs = times.min() ?? 0
            self.worstMs = times.max() ?? 0
        }
    }
}
