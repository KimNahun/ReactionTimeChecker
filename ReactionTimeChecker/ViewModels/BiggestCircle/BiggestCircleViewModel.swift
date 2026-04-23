// ViewModels/BiggestCircle/BiggestCircleViewModel.swift
import SwiftUI
import Observation
import QuartzCore

enum BiggestCircleState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case showing(round: Int)
    case correct(round: Int, ms: Int)
    case wrong
    case timeout
    case completed
}

struct CircleBubble: Identifiable, Sendable {
    let id: UUID
    let radius: CGFloat
    let x: CGFloat  // 0-1 relative
    let y: CGFloat  // 0-1 relative
    let isBiggest: Bool

    init(id: UUID = UUID(), radius: CGFloat, x: CGFloat, y: CGFloat, isBiggest: Bool) {
        self.id = id; self.radius = radius; self.x = x; self.y = y; self.isBiggest = isBiggest
    }
}

@MainActor
@Observable
final class BiggestCircleViewModel {
    private(set) var state: BiggestCircleState = .idle
    private(set) var bubbles: [CircleBubble] = []
    private(set) var currentRound: Int = 0
    private(set) var roundTimes: [Int] = []
    private(set) var timeRemaining: Double = 10.0

    private var roundStartTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    /// Time limit: 10, 9, 8, 7 ... min 2 seconds
    private var roundTimeLimit: Double {
        max(2.0, 10.0 - Double(currentRound - 1))
    }

    /// Size difference shrinks each round
    private var sizeDifference: CGFloat {
        max(2.0, 20.0 - CGFloat(currentRound - 1) * 1.5)
    }

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap(bubble: CircleBubble) {
        guard case .showing = state else { return }
        timerTask?.cancel()
        let ms = max(1, Int((CACurrentMediaTime() - roundStartTime) * 1000))

        if bubble.isBiggest {
            roundTimes.append(ms)
            state = .correct(round: currentRound, ms: ms)
            currentTask?.cancel()
            currentTask = Task {
                do { try await Task.sleep(nanoseconds: 600_000_000) } catch { return }
                await nextRound()
            }
        } else {
            state = .wrong
            currentTask?.cancel()
            currentTask = Task {
                do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
                state = .completed
            }
        }
    }

    func buildSession() -> BiggestCircleSession {
        let total = roundTimes.reduce(0, +)
        let avg = roundTimes.isEmpty ? 0 : total / roundTimes.count
        return BiggestCircleSession(roundsCompleted: roundTimes.count, totalTimeMs: total, averageTimeMs: avg)
    }

    func cancelAll() {
        currentTask?.cancel(); timerTask?.cancel()
        currentTask = nil; timerTask = nil
    }

    // MARK: - Private

    private func runTest() async {
        for n in stride(from: 3, through: 1, by: -1) {
            state = .countdown(n)
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
        }
        await nextRound()
    }

    private func nextRound() async {
        currentRound = roundTimes.count + 1
        generateBubbles()
        roundStartTime = CACurrentMediaTime()
        timeRemaining = roundTimeLimit
        state = .showing(round: currentRound)
        startTimer()
    }

    private func startTimer() {
        timerTask?.cancel()
        let limit = roundTimeLimit
        timerTask = Task {
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - roundStartTime
                timeRemaining = max(0, limit - elapsed)
                if timeRemaining <= 0 {
                    state = .timeout
                    do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
                    state = .completed
                    return
                }
                do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
            }
        }
    }

    private func generateBubbles() {
        let baseRadius: CGFloat = CGFloat.random(in: 25...40)
        let diff = sizeDifference
        let biggestRadius = baseRadius + diff

        // Generate 5 positions that don't overlap too much
        var positions: [(CGFloat, CGFloat)] = []
        let bubbleMaxR = biggestRadius / 300.0  // relative radius for collision check
        for _ in 0..<5 {
            var x: CGFloat = 0, y: CGFloat = 0
            for _ in 0..<50 {
                x = CGFloat.random(in: 0.15...0.85)
                y = CGFloat.random(in: 0.15...0.85)
                let tooClose = positions.contains { px, py in
                    let dx = px - x; let dy = py - y
                    return sqrt(dx * dx + dy * dy) < bubbleMaxR * 3
                }
                if !tooClose { break }
            }
            positions.append((x, y))
        }

        let biggestIndex = Int.random(in: 0...4)

        // Other 4 circles: similar sizes but all smaller
        var radii: [CGFloat] = []
        for i in 0..<5 {
            if i == biggestIndex {
                radii.append(biggestRadius)
            } else {
                // Random size smaller than biggest, but close
                let r = baseRadius + CGFloat.random(in: 0...(diff * 0.6))
                radii.append(r)
            }
        }

        bubbles = (0..<5).map { i in
            CircleBubble(
                radius: radii[i],
                x: positions[i].0,
                y: positions[i].1,
                isBiggest: i == biggestIndex
            )
        }
    }
}
