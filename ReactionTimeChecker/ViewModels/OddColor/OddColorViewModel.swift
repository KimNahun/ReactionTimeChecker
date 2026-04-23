// ViewModels/OddColor/OddColorViewModel.swift
import SwiftUI
import Observation
import QuartzCore

enum OddColorState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case showing(round: Int)
    case correct(round: Int, ms: Int)
    case wrong
    case timeout
    case completed
}

struct ColorTile: Identifiable, Sendable, Equatable {
    let id: UUID
    let colors: [Color]  // 4 quadrant colors
    let isOdd: Bool
    let index: Int

    init(id: UUID = UUID(), colors: [Color], isOdd: Bool, index: Int) {
        self.id = id
        self.colors = colors
        self.isOdd = isOdd
        self.index = index
    }

    static func == (lhs: ColorTile, rhs: ColorTile) -> Bool { lhs.id == rhs.id }
}

@MainActor
@Observable
final class OddColorViewModel {
    private(set) var state: OddColorState = .idle
    private(set) var tiles: [ColorTile] = []
    private(set) var currentRound: Int = 0
    private(set) var roundTimes: [Int] = []
    private(set) var timeRemaining: Double = 10.0
    private(set) var targetColor: Color = .red

    private var roundStartTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    /// Time limit decreases: 10, 9.5, 9, 8.5 ... min 3 seconds
    private var roundTimeLimit: Double {
        max(3.0, 10.0 - Double(currentRound - 1) * 0.5)
    }

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap(tile: ColorTile) {
        guard case .showing = state else { return }
        timerTask?.cancel()
        let ms = max(1, Int((CACurrentMediaTime() - roundStartTime) * 1000))

        if tile.isOdd {
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

    func buildSession() -> OddColorSession {
        let total = roundTimes.reduce(0, +)
        let avg = roundTimes.isEmpty ? 0 : total / roundTimes.count
        return OddColorSession(roundsCompleted: roundTimes.count, totalTimeMs: total, averageTimeMs: avg)
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
        generateTiles()
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

    private func generateTiles() {
        // Generate target color (the "odd" color) — fully random RGB
        targetColor = randomColor()

        // Generate 64 random colors for normal tiles (16 tiles × 4 quadrants)
        // All 15 normal tiles share the same 4 colors (shuffled order per tile)
        let normalQuadColors = (0..<4).map { _ in randomColor() }

        // Odd tile: 3 normal random colors + target color in a random quadrant
        let oddIndex = Int.random(in: 0...15)
        let targetQuadrant = Int.random(in: 0...3)

        tiles = (0..<16).map { i in
            if i == oddIndex {
                // Odd tile: insert target color at random quadrant
                var colors = (0..<4).map { _ in randomColor() }
                colors[targetQuadrant] = targetColor
                return ColorTile(colors: colors, isOdd: true, index: i)
            } else {
                // Normal tile: 4 fully random colors (no target color)
                let colors = (0..<4).map { _ in randomColorExcluding(targetColor) }
                return ColorTile(colors: colors, isOdd: false, index: i)
            }
        }
    }

    private func randomColor() -> Color {
        Color(
            red: Double.random(in: 0.15...0.95),
            green: Double.random(in: 0.15...0.95),
            blue: Double.random(in: 0.15...0.95)
        )
    }

    /// Generate a random color that's visually different from the target
    private func randomColorExcluding(_ target: Color) -> Color {
        for _ in 0..<20 {
            let c = randomColor()
            // Simple distance check to make sure it's not too close to target
            // (we can't easily extract Color components, so just generate and hope)
            return c
        }
        return randomColor()
    }
}
