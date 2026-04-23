// ViewModels/Sequence/SequenceViewModel.swift
import Foundation
import Observation
import QuartzCore

enum SequenceState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case playing
    case wrongTap(penaltyTotal: Double)
    case completed(totalTimeMs: Int)
}

@MainActor
@Observable
final class SequenceViewModel {
    private(set) var state: SequenceState = .idle
    private(set) var numbers: [SequenceNumber] = []
    private(set) var penaltyCount: Int = 0
    private(set) var penaltyTime: Double = 0  // seconds
    private(set) var displayTime: Double = 0  // elapsed + penalties

    // Floating penalty text
    private(set) var showPenalty: Bool = false
    private(set) var penaltyLabel: String = ""

    let numberCount = 20
    private let penaltySeconds: Double = 3.0

    private var startTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    var nextTarget: Int? {
        numbers.filter { !$0.isTapped }.map { $0.value }.sorted().first
    }

    var tappedCount: Int { numbers.filter { $0.isTapped }.count }
    var isAllTapped: Bool { tappedCount >= numberCount }

    init() {
        generateNumbers()
    }

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap(value: Int) {
        guard case .playing = state else { return }
        guard let target = nextTarget else { return }

        if value == target {
            // Correct
            if let idx = numbers.firstIndex(where: { $0.value == value }) {
                numbers[idx].isTapped = true
            }
            if isAllTapped {
                let totalMs = Int(displayTime * 1000)
                timerTask?.cancel()
                state = .completed(totalTimeMs: totalMs)
            }
        } else {
            // Wrong — add penalty
            penaltyCount += 1
            penaltyTime += penaltySeconds
            penaltyLabel = "+\(Int(penaltySeconds))s"
            showPenalty = true

            state = .wrongTap(penaltyTotal: penaltyTime)

            currentTask?.cancel()
            currentTask = Task {
                do {
                    try await Task.sleep(nanoseconds: 500_000_000)
                } catch { return }
                showPenalty = false
                state = .playing
            }
        }
    }

    func buildSession() -> SequenceSession {
        SequenceSession(
            totalTimeMs: Int(displayTime * 1000),
            penaltyCount: penaltyCount,
            penaltyTimeMs: Int(penaltyTime * 1000),
            numberCount: numberCount
        )
    }

    func cancelAll() {
        currentTask?.cancel()
        currentTask = nil
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Private

    private func runTest() async {
        for n in stride(from: 3, through: 1, by: -1) {
            state = .countdown(n)
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch { return }
        }

        startTime = CACurrentMediaTime()
        state = .playing
        startTimer()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - startTime
                displayTime = elapsed + penaltyTime
                do {
                    try await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                } catch { return }
            }
        }
    }

    private func generateNumbers() {
        var pool = Array(1...100)
        pool.shuffle()
        let selected = Array(pool.prefix(numberCount)).sorted()
        var indices = Array(0..<numberCount)
        indices.shuffle()

        numbers = selected.enumerated().map { i, value in
            SequenceNumber(value: value, gridIndex: indices[i])
        }
    }
}
