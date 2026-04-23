// ViewModels/Stroop/StroopViewModel.swift
import Foundation
import Observation
import QuartzCore

enum StroopTestState: Sendable, Equatable {
    case idle
    case instruction               // Show target color
    case countdown(Int)            // 3, 2, 1
    case showing(index: Int)       // Displaying stimulus
    case correctTap(ms: Int)       // Tapped target correctly
    case falseAlarm                // Tapped non-target
    case missed                    // Didn't tap target
    case colorChanged              // Target color changed notification
    case completed
}

@MainActor
@Observable
final class StroopViewModel {
    private(set) var state: StroopTestState = .idle
    private(set) var targetColor: StroopColor
    private(set) var stimuli: [StroopStimulus] = []
    private(set) var attempts: [StroopAttempt] = []
    private(set) var currentIndex: Int = 0

    let totalStimuli: Int

    private var currentTask: Task<Void, Never>?
    private var stimulusStartTime: Double = 0
    private var tappedThisStimulus = false

    var currentStimulus: StroopStimulus? {
        guard case .showing(let i) = state, i < stimuli.count else { return nil }
        return stimuli[i]
    }

    var previousStimulus: StroopStimulus? {
        guard currentIndex > 0 else { return nil }
        return stimuli[currentIndex - 1]
    }

    var completedCount: Int { attempts.count }
    var correctCount: Int { attempts.filter { $0.isCorrect }.count }
    var falseAlarmCount: Int { attempts.filter { $0.isFalseAlarm }.count }

    init(totalStimuli: Int) {
        self.totalStimuli = totalStimuli
        self.targetColor = StroopColor.allCases.randomElement()!
        self.stimuli = []
        self.stimuli = generateStimuli()
    }

    // MARK: - Public

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap() {
        guard case .showing(let index) = state, !tappedThisStimulus else { return }
        tappedThisStimulus = true

        let tapTime = CACurrentMediaTime()
        let ms = max(1, Int(round((tapTime - stimulusStartTime) * 1000)))
        let stimulus = stimuli[index]

        let attempt = StroopAttempt(
            reactionTimeMs: ms,
            wasTarget: stimulus.isTarget,
            didTap: true
        )
        attempts.append(attempt)

        // Cancel the display timer
        currentTask?.cancel()

        // Advance to next stimulus
        currentIndex += 1

        if stimulus.isTarget {
            state = .correctTap(ms: ms)
        } else {
            state = .falseAlarm
        }

        currentTask = Task {
            do {
                try await Task.sleep(nanoseconds: 400_000_000)
            } catch { return }
            await showNextStimulus()
        }
    }

    func buildSession() -> StroopSession {
        StroopSession(attempts: attempts, totalStimuli: totalStimuli, targetColor: targetColor)
    }

    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Private

    private func runTest() async {
        // Instruction phase
        state = .instruction
        do {
            try await Task.sleep(nanoseconds: 2_500_000_000)
        } catch { return }

        // Countdown
        for n in stride(from: 3, through: 1, by: -1) {
            state = .countdown(n)
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch { return }
        }

        await showNextStimulus()
    }

    private func showNextStimulus() async {
        guard currentIndex < stimuli.count else {
            state = .completed
            return
        }

        // Change target color every 10 stimuli
        if currentIndex > 0 && currentIndex % 10 == 0 {
            let newColor = targetColor.randomOther()
            targetColor = newColor
            // Regenerate remaining stimuli with new target
            let remaining = totalStimuli - currentIndex
            let newStimuli = generateStimuliForCount(remaining)
            stimuli = Array(stimuli.prefix(currentIndex)) + newStimuli

            state = .colorChanged
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch { return }
        }

        tappedThisStimulus = false
        stimulusStartTime = CACurrentMediaTime()
        state = .showing(index: currentIndex)

        // Display time: 0.6 - 1.0 seconds
        let displayTime = Double.random(in: 0.6...1.0)
        do {
            try await Task.sleep(nanoseconds: UInt64(displayTime * 1_000_000_000))
        } catch { return }

        // Time's up — user didn't tap
        if !tappedThisStimulus {
            let stimulus = stimuli[currentIndex]
            let attempt = StroopAttempt(
                reactionTimeMs: 0,
                wasTarget: stimulus.isTarget,
                didTap: false
            )
            attempts.append(attempt)

            if stimulus.isTarget {
                state = .missed
                do {
                    try await Task.sleep(nanoseconds: 350_000_000)
                } catch { return }
            }

            currentIndex += 1

            // Brief gap between stimuli
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch { return }

            await showNextStimulus()
        }
    }

    private func generateStimuli() -> [StroopStimulus] {
        generateStimuliForCount(totalStimuli)
    }

    private func generateStimuliForCount(_ count: Int) -> [StroopStimulus] {
        var result: [StroopStimulus] = []
        let targetCount = count / 2 + (count.isMultiple(of: 2) ? 0 : 1)
        let distractorCount = count - targetCount

        for _ in 0..<targetCount {
            let textMeaning = targetColor.randomOther()
            result.append(StroopStimulus(
                textLabel: textMeaning.displayName,
                textMeaning: textMeaning,
                displayColor: targetColor,
                isTarget: true
            ))
        }

        let nonTargetColors = StroopColor.allCases.filter { $0 != targetColor }
        for i in 0..<distractorCount {
            let displayColor = nonTargetColors[i % nonTargetColors.count]
            let useTargetText = i < distractorCount / 2
            let textMeaning: StroopColor
            if useTargetText {
                textMeaning = targetColor
            } else {
                textMeaning = displayColor.randomOther()
            }
            result.append(StroopStimulus(
                textLabel: textMeaning.displayName,
                textMeaning: textMeaning,
                displayColor: displayColor,
                isTarget: false
            ))
        }

        result.shuffle()
        return result
    }
}
