// ViewModels/Test/TestViewModel.swift
import Foundation
import Observation

enum TestState: Sendable, Equatable {
    case idle
    case countdown(Int)           // 3, 2, 1, 0 (GO! flash)
    case waiting
    case green
    case recorded(ms: Int)
    case cheated(message: String)
    case completed
}

@MainActor
@Observable
final class TestViewModel {
    private(set) var state: TestState = .idle
    private(set) var totalRounds: Int
    private(set) var validRoundCount: Int = 0
    private(set) var currentAttemptNumber: Int = 1
    private(set) var attempts: [ReactionAttempt] = []

    private let testService: ReactionTestServiceProtocol
    private var currentTask: Task<Void, Never>?

    var validAttempts: [ReactionAttempt] { attempts.filter { !$0.isCheated } }
    var cheatedCount: Int { attempts.filter { $0.isCheated }.count }
    var isCompleted: Bool { validRoundCount >= totalRounds }
    var currentDisplayRound: Int { min(validRoundCount + 1, totalRounds) }

    private static let cheatedMessages: [String] = [
        "성급하시네요! 😤 빨간불에선 기다려요!",
        "앗! 너무 빨랐어요. 초록불을 기다려주세요 🚦",
        "실격! 눈 감고 탭한 건 아니죠? 🙈",
        "부정 출발! 🏃‍♂️💨 다시 한 번 해볼까요?",
        "헉! 빨간불에 건너면 안 돼요 🚸",
        "치팅 감지! 🕵️ 정정당당하게!",
    ]

    init(totalRounds: Int, testService: ReactionTestServiceProtocol = ReactionTestService()) {
        self.totalRounds = totalRounds
        self.testService = testService
    }

    // MARK: - Public Interface

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await self.runRoundCycle() }
    }

    func handleTap(at tapTime: Double) async {
        switch state {
        case .waiting:
            applyCheat()

        case .countdown(let n) where n == 0:
            // GO! flash — treat as waiting (too early)
            applyCheat()

        case .countdown:
            // 3 / 2 / 1 — ignore completely, no penalty
            break

        case .green:
            let ms = await testService.calculateMs(tapTime: tapTime)
            applyValidRecord(ms: ms)

        default:
            break
        }
    }

    func retryCurrentRound() {
        currentAttemptNumber += 1
        currentTask?.cancel()
        currentTask = Task { await self.runRoundCycle() }
    }

    func buildSession() -> TestSession {
        TestSession(attempts: attempts, rounds: totalRounds)
    }

    /// Explicitly cancel the in-flight round task.
    /// Called from `TestView.onDisappear` (and on phase transitions) because
    /// Swift 6's @MainActor class `deinit` is nonisolated and cannot touch
    /// MainActor-isolated state like `currentTask` safely.
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Private

    private func applyCheat() {
        currentTask?.cancel()
        let message = Self.cheatedMessages.randomElement() ?? Self.cheatedMessages[0]
        let attempt = ReactionAttempt(
            reactionTimeMs: 0,
            isCheated: true,
            attemptNumber: currentAttemptNumber
        )
        attempts.append(attempt)
        state = .cheated(message: message)
    }

    private func applyValidRecord(ms: Int) {
        let attempt = ReactionAttempt(
            reactionTimeMs: ms,
            isCheated: false,
            attemptNumber: currentAttemptNumber
        )
        attempts.append(attempt)
        validRoundCount += 1
        currentAttemptNumber += 1
        state = .recorded(ms: ms)

        currentTask?.cancel()
        currentTask = Task {
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
            } catch {
                return
            }
            if self.isCompleted {
                self.state = .completed
            } else {
                await self.runRoundCycle()
            }
        }
    }

    private func runRoundCycle() async {
        // Countdown: 3 → 2 → 1 → 0 (1 second each)
        for n in stride(from: 3, through: 0, by: -1) {
            state = .countdown(n)
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return
            }
        }

        // Waiting phase with random delay
        state = .waiting
        do {
            try await testService.scheduleGreen()
            state = .green
            // Green state — handleTap will process the tap
        } catch {
            // Task was cancelled (cheat detected or retry)
        }
    }
}
