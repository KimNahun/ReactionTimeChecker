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

    // 0.06s (60ms) intervals, 10% tiers
    // 0ms = top 1%, ~60ms = top 10%, ~120ms = top 20%, ...
    private static func calculatePercentile(avgErrorMs: Int) -> Int {
        if avgErrorMs == 0 { return 1 }
        let tier = (avgErrorMs - 1) / 60 + 1
        let percentile = tier * 10
        return min(99, max(1, percentile))
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
