// ViewModels/TimeSense/TimeSenseResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class TimeSenseResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0
        case averageError = 1
        case attempts = 2
        case emoji = 3
        case gradeName = 4
        case gradeDesc = 5
        case shareButton = 6

        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var stage: RevealStage = .nothing

    let session: TimeSenseSession
    let percentile: Int
    let grade: Grade

    private var revealTask: Task<Void, Never>?

    init(session: TimeSenseSession) {
        self.session = session
        self.percentile = Self.calculatePercentile(avgErrorMs: session.averageErrorMs)
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

    // Lower error = better
    private static func calculatePercentile(avgErrorMs: Int) -> Int {
        let anchors: [(ms: Int, percentile: Double)] = [
            (30,   0.5),
            (80,   2.0),
            (150,  5.0),
            (250,  12.0),
            (400,  22.0),
            (600,  33.0),
            (800,  44.0),
            (1000, 55.0),
            (1300, 65.0),
            (1700, 76.0),
            (2200, 86.0),
            (3000, 93.0),
            (5000, 99.0),
        ]

        if avgErrorMs <= anchors.first!.ms { return 1 }
        if avgErrorMs >= anchors.last!.ms { return 99 }

        for i in 0..<(anchors.count - 1) {
            let lo = anchors[i]
            let hi = anchors[i + 1]
            if avgErrorMs >= lo.ms && avgErrorMs <= hi.ms {
                let t = Double(avgErrorMs - lo.ms) / Double(hi.ms - lo.ms)
                let p = lo.percentile + t * (hi.percentile - lo.percentile)
                return max(1, min(99, Int(p.rounded())))
            }
        }
        return 99
    }

    private func runRevealSequence() async {
        let steps: [(RevealStage, UInt64)] = [
            (.averageError, 600_000_000),
            (.attempts,     600_000_000),
            (.emoji,        700_000_000),
            (.gradeName,    500_000_000),
            (.gradeDesc,    500_000_000),
            (.shareButton,  400_000_000),
        ]
        for (next, delay) in steps {
            do { try await Task.sleep(nanoseconds: delay) } catch { return }
            stage = next
        }
    }
}
