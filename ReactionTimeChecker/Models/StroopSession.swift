// Models/StroopSession.swift

struct StroopSession: Sendable {
    let attempts: [StroopAttempt]
    let totalStimuli: Int
    let targetColor: StroopColor

    // Correct taps on targets
    let correctTaps: [StroopAttempt]
    let averageMs: Int
    let bestMs: Int
    let worstMs: Int

    // Accuracy metrics
    let accuracy: Int          // percentage 0-100
    let missCount: Int         // targets user didn't tap
    let falseAlarmCount: Int   // non-targets user tapped

    init(attempts: [StroopAttempt], totalStimuli: Int, targetColor: StroopColor) {
        self.attempts = attempts
        self.totalStimuli = totalStimuli
        self.targetColor = targetColor

        let hits = attempts.filter { $0.wasTarget && $0.didTap }
        self.correctTaps = hits
        self.missCount = attempts.filter { $0.isMiss }.count
        self.falseAlarmCount = attempts.filter { $0.isFalseAlarm }.count

        let correctCount = attempts.filter { $0.isCorrect }.count
        self.accuracy = totalStimuli > 0 ? (correctCount * 100) / totalStimuli : 0

        if hits.isEmpty {
            self.averageMs = 0
            self.bestMs = 0
            self.worstMs = 0
        } else {
            let times = hits.map { $0.reactionTimeMs }
            self.averageMs = times.reduce(0, +) / times.count
            self.bestMs = times.min() ?? 0
            self.worstMs = times.max() ?? 0
        }
    }
}
