// ViewModels/Stroop/StroopResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class StroopResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0
        case averageMs = 1
        case accuracy = 2
        case emoji = 3
        case gradeName = 4
        case gradeDesc = 5
        case breakdown = 6
        case shareButton = 7

        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var stage: RevealStage = .nothing

    let session: StroopSession
    let percentile: Int
    let grade: Grade

    private var revealTask: Task<Void, Never>?

    init(session: StroopSession) {
        self.session = session
        // Stroop scoring: penalize both slow speed and low accuracy
        let adjustedScore = Self.calculateAdjustedScore(session: session)
        self.percentile = Self.calculatePercentile(adjustedScore: adjustedScore)
        self.grade = StatisticsService().determineGrade(percentile: self.percentile)
    }

    func startReveal() {
        revealTask?.cancel()
        revealTask = Task { await runRevealSequence() }
    }

    func cancelReveal() {
        revealTask?.cancel()
        revealTask = nil
    }

    func breakdownMessage() -> String {
        let misses = session.missCount
        let falseAlarms = session.falseAlarmCount
        if misses == 0 && falseAlarms == 0 {
            return String(localized: "Perfect! No mistakes at all 👏")
        }
        var parts: [String] = []
        if misses > 0 {
            parts.append(String(format: String(localized: "Missed targets: %lld"), misses))
        }
        if falseAlarms > 0 {
            parts.append(String(format: String(localized: "False taps: %lld"), falseAlarms))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Scoring

    /// Combined score: averageMs adjusted by error rate
    /// Lower is better, like reaction time
    private static func calculateAdjustedScore(session: StroopSession) -> Int {
        guard session.averageMs > 0 else { return 9999 }
        let errorRate = Double(session.missCount + session.falseAlarmCount) / Double(session.totalStimuli)
        let adjusted = Double(session.averageMs) * (1.0 + errorRate * 3.0)
        return Int(adjusted.rounded())
    }

    /// Stroop-specific percentile (inherently slower than simple reaction)
    private static func calculatePercentile(adjustedScore: Int) -> Int {
        let anchors: [(ms: Int, percentile: Double)] = [
            (200, 0.5),
            (280, 2.0),
            (330, 5.0),
            (380, 12.0),
            (430, 22.0),
            (470, 33.0),
            (510, 44.0),
            (550, 55.0),
            (600, 65.0),
            (660, 76.0),
            (740, 86.0),
            (850, 93.0),
            (1000, 99.0),
        ]

        if adjustedScore <= anchors.first!.ms { return 1 }
        if adjustedScore >= anchors.last!.ms { return 99 }

        for i in 0..<(anchors.count - 1) {
            let lo = anchors[i]
            let hi = anchors[i + 1]
            if adjustedScore >= lo.ms && adjustedScore <= hi.ms {
                let t = Double(adjustedScore - lo.ms) / Double(hi.ms - lo.ms)
                let p = lo.percentile + t * (hi.percentile - lo.percentile)
                return max(1, min(99, Int(p.rounded())))
            }
        }
        return 99
    }

    private func runRevealSequence() async {
        let steps: [(RevealStage, UInt64)] = [
            (.averageMs,    600_000_000),
            (.accuracy,     700_000_000),
            (.emoji,        700_000_000),
            (.gradeName,    500_000_000),
            (.gradeDesc,    500_000_000),
            (.breakdown,    600_000_000),
            (.shareButton,  400_000_000),
        ]
        for (next, delay) in steps {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch { return }
            stage = next
        }
    }
}
