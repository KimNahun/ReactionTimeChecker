// ViewModels/Sequence/SequenceResultViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
final class SequenceResultViewModel {
    enum RevealStage: Int, Sendable, Comparable {
        case nothing = 0
        case totalTime = 1
        case penalties = 2
        case emoji = 3
        case gradeName = 4
        case gradeDesc = 5
        case shareButton = 6

        static func < (lhs: RevealStage, rhs: RevealStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var stage: RevealStage = .nothing

    let session: SequenceSession
    let percentile: Int
    let grade: Grade

    private var revealTask: Task<Void, Never>?

    init(session: SequenceSession) {
        self.session = session
        self.percentile = Self.calculatePercentile(totalTimeMs: session.totalTimeMs)
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

    // 20 numbers, total time including penalties
    private static func calculatePercentile(totalTimeMs: Int) -> Int {
        let anchors: [(ms: Int, percentile: Double)] = [
            (8_000,  0.5),
            (10_000, 2.0),
            (12_000, 5.0),
            (15_000, 12.0),
            (18_000, 22.0),
            (21_000, 33.0),
            (25_000, 44.0),
            (30_000, 55.0),
            (35_000, 65.0),
            (42_000, 76.0),
            (50_000, 86.0),
            (60_000, 93.0),
            (80_000, 99.0),
        ]

        if totalTimeMs <= anchors.first!.ms { return 1 }
        if totalTimeMs >= anchors.last!.ms { return 99 }

        for i in 0..<(anchors.count - 1) {
            let lo = anchors[i]
            let hi = anchors[i + 1]
            if totalTimeMs >= lo.ms && totalTimeMs <= hi.ms {
                let t = Double(totalTimeMs - lo.ms) / Double(hi.ms - lo.ms)
                let p = lo.percentile + t * (hi.percentile - lo.percentile)
                return max(1, min(99, Int(p.rounded())))
            }
        }
        return 99
    }

    private func runRevealSequence() async {
        let steps: [(RevealStage, UInt64)] = [
            (.totalTime,   600_000_000),
            (.penalties,   600_000_000),
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
