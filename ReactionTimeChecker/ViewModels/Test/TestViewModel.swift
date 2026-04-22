// ViewModels/Test/TestViewModel.swift
import Foundation
import Observation
import QuartzCore

enum TestState: Sendable, Equatable {
    case idle
    case countdown(Int)           // 3, 2, 1
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
    private var greenFrameTime: Double = 0   // targetTimestamp of the frame green was first displayed
    private var _dlHelper: _FrameTimingHelper?

    var validAttempts: [ReactionAttempt] { attempts.filter { !$0.isCheated } }
    var cheatedCount: Int { attempts.filter { $0.isCheated }.count }
    var isCompleted: Bool { validRoundCount >= totalRounds }
    var currentDisplayRound: Int { min(validRoundCount + 1, totalRounds) }

    private static let cheatedMessages: [String] = [
        String(localized: "Too eager! 😤 Wait for the red screen!"),
        String(localized: "Oops! Too fast. Wait for green 🚦"),
        String(localized: "Foul! Did you tap with your eyes closed? 🙈"),
        String(localized: "False start! 🏃 Let's try again"),
        String(localized: "Hey! Don't go on red 🚸"),
        String(localized: "Cheat detected! 🕵️ Play fair!"),
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

        case .countdown:
            // 3 / 2 / 1 — ignore completely, no penalty
            break

        case .green:
            let ms = max(1, Int(round((tapTime - greenFrameTime) * 1000)))
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
        _dlHelper?.invalidate()
        _dlHelper = nil
    }

    // MARK: - Private

    private func applyCheat() {
        currentTask?.cancel()
        // Invalidate pending display link so it cannot overwrite .cheated state
        _dlHelper?.invalidate()
        _dlHelper = nil
        let message = Self.cheatedMessages.randomElement() ?? ""
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
        // Countdown: 3 → 2 → 1 then straight to waiting
        for n in stride(from: 3, through: 1, by: -1) {
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
            // CADisplayLink로 다음 프레임의 정확한 표시 시각을 startTime으로 사용
            // targetTimestamp = 해당 프레임이 실제 디스플레이에 나타나는 시각 → 이론상 오차 0
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                let helper = _FrameTimingHelper()
                helper.onTick = { [weak self] link in
                    MainActor.assumeIsolated {
                        guard self?.state == .waiting else { return }
                        self?.greenFrameTime = link.targetTimestamp
                        self?.state = .green
                        self?._dlHelper = nil
                    }
                    cont.resume()
                }
                helper.start()
                _dlHelper = helper
            }
        } catch {
            // Task was cancelled (cheat detected or retry)
        }
    }
}

// MARK: - CADisplayLink 헬퍼

/// 다음 프레임 타이밍을 한 번만 캡처하기 위한 one-shot CADisplayLink 래퍼.
private final class _FrameTimingHelper: NSObject {
    var onTick: ((CADisplayLink) -> Void)?
    private var link: CADisplayLink?

    func start() {
        let dl = CADisplayLink(target: self, selector: #selector(tick))
        dl.add(to: .main, forMode: .common)
        link = dl
    }

    func invalidate() {
        link?.invalidate()
        link = nil
        onTick = nil
    }

    @objc func tick(_ dl: CADisplayLink) {
        onTick?(dl)
        invalidate()
    }
}
