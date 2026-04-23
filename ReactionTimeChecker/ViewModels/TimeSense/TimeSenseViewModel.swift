// ViewModels/TimeSense/TimeSenseViewModel.swift
import Foundation
import Observation
import QuartzCore

enum TimeSenseState: Sendable, Equatable {
    case idle
    case modeSelect
    case countdown(Int)
    case running(round: Int)
    case roundResult(round: Int, actualMs: Int, errorMs: Int)
    case completed
}

@MainActor
@Observable
final class TimeSenseViewModel {
    private(set) var state: TimeSenseState = .idle
    private(set) var timerVisible: Bool = true
    private(set) var showTimer: Bool = true  // actual visibility (hidden mode shows first 3s)
    private(set) var displayTime: Double = 0  // seconds
    private(set) var attempts: [TimeSenseAttempt] = []

    let totalRounds = 1
    let targetTimeMs = 10_000  // 10.00 seconds
    private let hiddenModeVisibleDuration: Double = 3.0

    private var startTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var currentRound: Int = 0

    var completedRounds: Int { attempts.count }

    func startTest(timerVisible: Bool) {
        self.timerVisible = timerVisible
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap() {
        guard case .running = state else { return }

        let elapsed = CACurrentMediaTime() - startTime
        let actualMs = Int(elapsed * 1000)
        let errorMs = abs(actualMs - targetTimeMs)

        timerTask?.cancel()

        let attempt = TimeSenseAttempt(actualTimeMs: actualMs)
        attempts.append(attempt)

        state = .roundResult(round: currentRound, actualMs: actualMs, errorMs: errorMs)

        currentTask?.cancel()
        currentTask = Task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch { return }

            if attempts.count >= totalRounds {
                state = .completed
            } else {
                await startRound()
            }
        }
    }

    func buildSession() -> TimeSenseSession {
        TimeSenseSession(attempts: attempts, timerVisible: timerVisible)
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
        await startRound()
    }

    private func startRound() async {
        currentRound = attempts.count + 1
        startTime = CACurrentMediaTime()
        displayTime = 0
        showTimer = true  // always visible at start
        state = .running(round: currentRound)
        startTimerUpdate()
    }

    private func startTimerUpdate() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - startTime
                displayTime = elapsed

                // Hidden mode: show timer for first 3 seconds, then hide
                if !timerVisible && elapsed >= hiddenModeVisibleDuration {
                    showTimer = false
                }

                do { try await Task.sleep(nanoseconds: 10_000_000) } catch { return }
            }
        }
    }
}
