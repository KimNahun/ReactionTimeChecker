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

    // Extra colors for the "odd" replacement
    private let extraColors: [Color] = [
        Color(red: 0.95, green: 0.5, blue: 0.1),   // orange
        Color(red: 0.5, green: 0.2, blue: 0.7),     // purple
        Color(red: 0.1, green: 0.8, blue: 0.8),     // cyan
        Color(red: 0.85, green: 0.2, blue: 0.5),    // pink
        Color(red: 0.4, green: 0.3, blue: 0.2),     // brown
    ]

    private func generateTiles() {
        // Pick which quadrant will have the different color in the odd tile
        let oddQuadrant = Int.random(in: 0...3)

        // Normal tile: 4 base colors (shuffled per tile for variety)
        let normalColors = baseColors.shuffled()

        // Odd tile: replace one quadrant with a completely different color
        var oddTileColors = normalColors
        let replaced = oddTileColors[oddQuadrant]
        // Pick a replacement color that's NOT in baseColors
        let replacement = extraColors.filter { $0 != replaced }.randomElement() ?? extraColors[0]
        oddTileColors[oddQuadrant] = replacement

        let oddIndex = Int.random(in: 0...15)

        tiles = (0..<16).map { i in
            ColorTile(
                colors: (i == oddIndex) ? oddTileColors : baseColors.shuffled(),
                isOdd: i == oddIndex,
                index: i
            )
        }
    }
}
