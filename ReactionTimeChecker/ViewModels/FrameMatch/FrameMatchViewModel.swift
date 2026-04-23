// ViewModels/FrameMatch/FrameMatchViewModel.swift
import Foundation
import Observation
import QuartzCore

enum FrameMatchState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case moving(round: Int)
    case stopped(round: Int, error: Double)
    case completed
}

@MainActor
@Observable
final class FrameMatchViewModel {
    private(set) var state: FrameMatchState = .idle
    private(set) var squareOffset: CGFloat = 0  // offset from center
    private(set) var errors: [CGFloat] = []

    let totalRounds = 5
    let frameSize: CGFloat = 80

    private var direction: CGFloat = 1
    private var speed: CGFloat = 2.0
    private var moveTask: Task<Void, Never>?
    private var currentTask: Task<Void, Never>?
    private var currentRound = 0

    var completedRounds: Int { errors.count }

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap() {
        guard case .moving = state else { return }
        moveTask?.cancel()
        let error = abs(squareOffset)
        errors.append(error)
        state = .stopped(round: currentRound, error: Double(error))

        currentTask?.cancel()
        currentTask = Task {
            do { try await Task.sleep(nanoseconds: 1_200_000_000) } catch { return }
            if errors.count >= totalRounds {
                state = .completed
            } else {
                await startRound()
            }
        }
    }

    func buildSession() -> FrameMatchSession {
        FrameMatchSession(errors: errors)
    }

    func cancelAll() {
        currentTask?.cancel()
        moveTask?.cancel()
        currentTask = nil
        moveTask = nil
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
        currentRound = errors.count + 1
        speed = CGFloat.random(in: 1.5...4.0)
        // Start from random side
        let screenHalf: CGFloat = 160
        squareOffset = Bool.random() ? -screenHalf : screenHalf
        direction = squareOffset < 0 ? 1 : -1

        state = .moving(round: currentRound)
        startMoving()
    }

    private func startMoving() {
        moveTask?.cancel()
        moveTask = Task {
            while !Task.isCancelled {
                squareOffset += direction * speed
                // Bounce at edges
                let limit: CGFloat = 160
                if abs(squareOffset) > limit {
                    direction *= -1
                }
                do { try await Task.sleep(nanoseconds: 16_000_000) } catch { return }
            }
        }
    }
}
