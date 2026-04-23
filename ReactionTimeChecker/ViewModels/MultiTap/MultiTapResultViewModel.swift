// ViewModels/MultiTap/MultiTapResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class MultiTapResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0
        case score = 1
        case breakdown = 2
        case emoji = 3
        case gradeName = 4
        case gradeDesc = 5
        case shareButton = 6

        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var stage: RevealStage = .nothing

    let session: MultiTapSession
    let percentile: Int
    let grade: Grade

    private var revealTask: Task<Void, Never>?

    init(session: MultiTapSession) {
        self.session = session
        let total = session.circlesTapped + session.circlesAutoCollected
        self.percentile = Self.calculatePercentile(circlesTapped: total)
        self.grade = StatisticsService().determineGrade(percentile: self.percentile)
    }

    var totalCollected: Int {
        session.circlesTapped + session.circlesAutoCollected
    }

    func startReveal() {
        revealTask?.cancel()
        revealTask = Task { await runRevealSequence() }
    }

    func cancelReveal() {
        revealTask?.cancel()
        revealTask = nil
    }

    // 30 seconds, ~90+ circles spawned with fast spawn rate
    private static func calculatePercentile(circlesTapped: Int) -> Int {
        // Invert: more tapped = lower percentile (better)
        let anchors: [(count: Int, percentile: Double)] = [
            (85, 0.5),
            (75, 5.0),
            (65, 10.0),
            (58, 20.0),
            (50, 30.0),
            (44, 40.0),
            (38, 50.0),
            (32, 60.0),
            (26, 70.0),
            (20, 80.0),
            (14, 90.0),
            (8,  95.0),
            (0,  99.0),
        ]

        if circlesTapped >= anchors.first!.count { return 1 }
        if circlesTapped <= anchors.last!.count { return 99 }

        for i in 0..<(anchors.count - 1) {
            let hi = anchors[i]   // higher count = better
            let lo = anchors[i + 1]
            if circlesTapped <= hi.count && circlesTapped >= lo.count {
                let t = Double(hi.count - circlesTapped) / Double(hi.count - lo.count)
                let p = hi.percentile + t * (lo.percentile - hi.percentile)
                return max(1, min(99, Int(p.rounded())))
            }
        }
        return 99
    }

    private func runRevealSequence() async {
        let steps: [(RevealStage, UInt64)] = [
            (.score,       600_000_000),
            (.breakdown,   600_000_000),
            (.emoji,       700_000_000),
            (.gradeName,   500_000_000),
            (.gradeDesc,   500_000_000),
            (.shareButton, 400_000_000),
        ]
        for (next, delay) in steps {
            do { try await Task.sleep(nanoseconds: delay) } catch { return }
            stage = next
        }
    }
}
