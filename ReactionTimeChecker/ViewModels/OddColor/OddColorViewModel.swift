// ViewModels/OddColor/OddColorViewModel.swift
import SwiftUI
import UIKit
import Observation
import QuartzCore

enum OddColorState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case showing(round: Int)
    case correct(round: Int, ms: Int)
    case wrong
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

    private var roundStartTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private let baseColors: [Color] = [
        Color(red: 0.9, green: 0.25, blue: 0.2),
        Color(red: 0.2, green: 0.5, blue: 0.9),
        Color(red: 0.15, green: 0.7, blue: 0.35),
        Color(red: 0.95, green: 0.75, blue: 0.1),
    ]

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap(tile: ColorTile) {
        guard case .showing = state else { return }
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

    func cancelAll() { currentTask?.cancel(); currentTask = nil }

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
        state = .showing(round: currentRound)
    }

    private func generateTiles() {
        // Difficulty: color difference decreases with rounds
        let diff = max(0.05, 0.25 - Double(currentRound - 1) * 0.015)

        // Pick which quadrant will be different in the odd tile
        let oddQuadrant = Int.random(in: 0...3)

        // Normal tile: 4 base colors in shuffled order
        let normalOrder = baseColors.shuffled()

        // Odd tile: same colors but one quadrant is slightly shifted
        var oddColors = normalOrder
        let original = oddColors[oddQuadrant]
        // Shift the color
        oddColors[oddQuadrant] = shiftColor(original, by: diff)

        let oddIndex = Int.random(in: 0...15)

        tiles = (0..<16).map { i in
            let colors = (i == oddIndex) ? oddColors : normalOrder.shuffled()
            // Keep same set of colors, just different order for normal tiles
            // But odd tile has the shifted color
            return ColorTile(
                colors: (i == oddIndex) ? oddColors : baseColors.shuffled(),
                isOdd: i == oddIndex,
                index: i
            )
        }
    }

    private func shiftColor(_ color: Color, by amount: Double) -> Color {
        // Create a slightly different shade
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        let r = min(1, max(0, components[0] + amount))
        let g = min(1, max(0, components[1] - amount * 0.5))
        let b = min(1, max(0, components[2] - amount * 0.3))
        return Color(red: r, green: g, blue: b)
    }
}
