// ViewModels/OddColor/OddColorResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class OddColorResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0, score = 1, emoji = 2, gradeName = 3, gradeDesc = 4, shareButton = 5
        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    private(set) var stage: RevealStage = .nothing
    let session: OddColorSession
    let percentile: Int
    let grade: Grade
    private var revealTask: Task<Void, Never>?

    init(session: OddColorSession) {
        self.session = session
        self.percentile = Self.calcPercentile(rounds: session.roundsCompleted)
        self.grade = StatisticsService().determineGrade(percentile: self.percentile)
    }

    func startReveal() {
        revealTask?.cancel()
        revealTask = Task {
            for (stage, delay): (RevealStage, UInt64) in [(.score, 600_000_000), (.emoji, 700_000_000), (.gradeName, 500_000_000), (.gradeDesc, 500_000_000), (.shareButton, 400_000_000)] {
                do { try await Task.sleep(nanoseconds: delay) } catch { return }
                self.stage = stage
            }
        }
    }

    func cancelReveal() { revealTask?.cancel(); revealTask = nil }

    private static func calcPercentile(rounds: Int) -> Int {
        let anchors: [(r: Int, p: Double)] = [
            (20, 0.5), (16, 5), (13, 10), (10, 20), (8, 30), (7, 40),
            (6, 50), (5, 60), (4, 70), (3, 80), (2, 90), (0, 99),
        ]
        if rounds >= anchors.first!.r { return 1 }
        if rounds <= anchors.last!.r { return 99 }
        for i in 0..<(anchors.count - 1) {
            let hi = anchors[i]; let lo = anchors[i + 1]
            if rounds <= hi.r && rounds >= lo.r {
                let t = Double(hi.r - rounds) / Double(hi.r - lo.r)
                return max(1, min(99, Int((hi.p + t * (lo.p - hi.p)).rounded())))
            }
        }
        return 99
    }
}
