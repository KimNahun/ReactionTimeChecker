// ViewModels/FrameMatch/FrameMatchResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class FrameMatchResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0, score = 1, breakdown = 2, emoji = 3, gradeName = 4, gradeDesc = 5, shareButton = 6
        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    private(set) var stage: RevealStage = .nothing
    let session: FrameMatchSession
    let percentile: Int
    let grade: Grade
    private var revealTask: Task<Void, Never>?

    init(session: FrameMatchSession) {
        self.session = session
        self.percentile = Self.calcPercentile(avgError: Double(session.averageError))
        self.grade = StatisticsService().determineGrade(percentile: self.percentile)
    }

    func startReveal() {
        revealTask?.cancel()
        revealTask = Task {
            for (stage, delay): (RevealStage, UInt64) in [(.score, 600_000_000), (.breakdown, 600_000_000), (.emoji, 700_000_000), (.gradeName, 500_000_000), (.gradeDesc, 500_000_000), (.shareButton, 400_000_000)] {
                do { try await Task.sleep(nanoseconds: delay) } catch { return }
                self.stage = stage
            }
        }
    }

    func cancelReveal() { revealTask?.cancel(); revealTask = nil }

    // Lower error = better
    private static func calcPercentile(avgError: Double) -> Int {
        let anchors: [(e: Double, p: Double)] = [
            (1, 0.5), (3, 5), (5, 10), (8, 20), (12, 30), (16, 40),
            (22, 50), (30, 60), (40, 70), (55, 80), (75, 90), (100, 99),
        ]
        if avgError <= anchors.first!.e { return 1 }
        if avgError >= anchors.last!.e { return 99 }
        for i in 0..<(anchors.count - 1) {
            let lo = anchors[i]; let hi = anchors[i + 1]
            if avgError >= lo.e && avgError <= hi.e {
                let t = (avgError - lo.e) / (hi.e - lo.e)
                return max(1, min(99, Int((lo.p + t * (hi.p - lo.p)).rounded())))
            }
        }
        return 99
    }
}
