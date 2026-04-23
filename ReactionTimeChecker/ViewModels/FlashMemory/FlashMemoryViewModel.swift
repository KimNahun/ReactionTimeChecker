// ViewModels/FlashMemory/FlashMemoryViewModel.swift
import Foundation
import Observation
import QuartzCore

enum FlashMemoryState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case showing           // 3 numbers visible
    case picking           // 5 balls, pick 3
    case correct(round: Int)
    case wrong
    case timeout
    case completed(rounds: Int)
}

@MainActor
@Observable
final class FlashMemoryViewModel {
    private(set) var state: FlashMemoryState = .idle
    private(set) var currentRound: Int = 0
    private(set) var targetNumbers: [Int] = []
    private(set) var choiceNumbers: [Int] = []
    private(set) var selectedNumbers: Set<Int> = []
    private(set) var displayDuration: Double = 1.0
    private(set) var pickTimeRemaining: Double = 5.0

    private let pickTimeLimit: Double = 5.0
    private let minDuration: Double = 0.2
    private var currentTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func selectNumber(_ num: Int) {
        guard case .picking = state else { return }
        if selectedNumbers.contains(num) {
            selectedNumbers.remove(num)
            return
        }
        selectedNumbers.insert(num)

        if selectedNumbers.count == targetNumbers.count {
            timerTask?.cancel()
            if Set(targetNumbers) == selectedNumbers {
                state = .correct(round: currentRound)
                currentTask?.cancel()
                currentTask = Task {
                    do { try await Task.sleep(nanoseconds: 800_000_000) } catch { return }
                    await nextRound()
                }
            } else {
                state = .wrong
                currentTask?.cancel()
                currentTask = Task {
                    do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
                    state = .completed(rounds: currentRound - 1)
                }
            }
        }
    }

    func buildSession() -> FlashMemorySession {
        let rounds: Int
        if case .completed(let r) = state { rounds = r } else { rounds = currentRound }
        return FlashMemorySession(roundsCompleted: rounds, lastDisplayDuration: displayDuration)
    }

    func cancelAll() {
        currentTask?.cancel()
        timerTask?.cancel()
        currentTask = nil
        timerTask = nil
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
        currentRound += 1
        displayDuration = max(minDuration, 1.0 - Double(currentRound - 1) * 0.1)
        generateNumbers()
        selectedNumbers = []

        // Show numbers
        state = .showing
        do {
            try await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
        } catch { return }

        // Switch to picking
        pickTimeRemaining = pickTimeLimit
        state = .picking
        startPickTimer()
    }

    private func startPickTimer() {
        timerTask?.cancel()
        timerTask = Task {
            let start = CACurrentMediaTime()
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - start
                pickTimeRemaining = max(0, pickTimeLimit - elapsed)
                if pickTimeRemaining <= 0 {
                    state = .timeout
                    do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
                    state = .completed(rounds: currentRound - 1)
                    return
                }
                do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
            }
        }
    }

    private func generateNumbers() {
        var pool = Array(1...99)
        pool.shuffle()
        targetNumbers = Array(pool.prefix(3))
        let distractors = Array(pool.dropFirst(3).prefix(2))
        choiceNumbers = (targetNumbers + distractors).shuffled()
    }
}
