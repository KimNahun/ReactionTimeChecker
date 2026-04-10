// ViewModels/Result/ResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class ResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0
        case averageMs = 1
        case percentile = 2
        case emoji = 3
        case gradeName = 4
        case gradeDesc = 5
        case comparison = 6
        case cheatedStat = 7
        case shareButton = 8

        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var stage: RevealStage = .nothing

    let session: TestSession
    let percentile: Int
    let grade: Grade

    private let statisticsService: StatisticsServiceProtocol
    private var revealTask: Task<Void, Never>?

    init(session: TestSession, statisticsService: StatisticsServiceProtocol = StatisticsService()) {
        self.session = session
        self.statisticsService = statisticsService
        let p = statisticsService.calculatePercentile(averageMs: session.averageMs)
        self.percentile = p
        self.grade = statisticsService.determineGrade(percentile: p)
    }

    func startReveal() {
        revealTask?.cancel()
        revealTask = Task {
            await runRevealSequence()
        }
    }

    /// Explicitly cancel the reveal sequence task.
    /// Called from `ResultView.onDisappear` because Swift 6's @MainActor
    /// class `deinit` is nonisolated and cannot safely reference
    /// the MainActor-isolated `revealTask` property.
    func cancelReveal() {
        revealTask?.cancel()
        revealTask = nil
    }

    private func runRevealSequence() async {
        let steps: [(RevealStage, UInt64)] = [
            (.averageMs,    600_000_000),
            (.percentile,   700_000_000),
            (.emoji,        700_000_000),
            (.gradeName,    500_000_000),
            (.gradeDesc,    500_000_000),
            (.comparison,   600_000_000),
            (.cheatedStat,  500_000_000),
            (.shareButton,  400_000_000),
        ]
        for (next, delay) in steps {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                return
            }
            stage = next
        }
    }

    func cheatedStatMessage() -> String {
        let count = session.cheatedCount
        if count == 0 {
            return "완벽해요! 단 한 번도 실격 없음 👏"
        } else if count >= 5 {
            return "성격 급한 편이시네요 😅 (\(count)회 실격)"
        } else {
            return "총 실격 횟수: \(count)회"
        }
    }
}
