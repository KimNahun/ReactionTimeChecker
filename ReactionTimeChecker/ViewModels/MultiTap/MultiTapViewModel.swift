// ViewModels/MultiTap/MultiTapViewModel.swift
import Foundation
import Observation
import QuartzCore

enum MultiTapState: Sendable, Equatable {
    case idle
    case countdown(Int)
    case playing
    case completed
}

@MainActor
@Observable
final class MultiTapViewModel {
    private(set) var state: MultiTapState = .idle
    private(set) var shapes: [SpawnedShape] = []
    private(set) var circlesTapped: Int = 0
    private(set) var circlesAutoCollected: Int = 0
    private(set) var wrongTaps: Int = 0
    private(set) var remainingTime: Double = 30.0
    private(set) var totalCirclesSpawned: Int = 0
    private(set) var showWrongFlash: Bool = false

    let gameDuration: Double = 30.0
    private let shapeLifetime: Double = 1.2
    private let autoCollectRadius: CGFloat = 0.08

    private var startTime: Double = 0
    private var currentTask: Task<Void, Never>?
    private var spawnTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    func startTest() {
        currentTask?.cancel()
        currentTask = Task { await runTest() }
    }

    func handleTap(at position: CGPoint, in size: CGSize) {
        guard case .playing = state else { return }

        let relX = position.x / size.width
        let relY = position.y / size.height

        // Find closest shape to tap position
        var bestIndex: Int?
        var bestDist: CGFloat = .infinity
        for (i, shape) in shapes.enumerated() {
            guard !shape.isCollected else { continue }
            let dx = shape.x - relX
            let dy = shape.y - relY
            let dist = sqrt(dx * dx + dy * dy)
            if dist < 0.06 && dist < bestDist {  // tap radius
                bestDist = dist
                bestIndex = i
            }
        }

        guard let idx = bestIndex else { return }
        let shape = shapes[idx]

        if shape.kind == .circle {
            shapes[idx].isCollected = true
            circlesTapped += 1
        } else {
            shapes[idx].isCollected = true
            wrongTaps += 1
            // Flash red
            showWrongFlash = true
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                showWrongFlash = false
            }
        }
    }

    func buildSession() -> MultiTapSession {
        let missed = totalCirclesSpawned - circlesTapped - circlesAutoCollected
        return MultiTapSession(
            circlesTapped: circlesTapped,
            circlesAutoCollected: circlesAutoCollected,
            totalCirclesSpawned: totalCirclesSpawned,
            wrongTaps: wrongTaps,
            missedCircles: max(0, missed)
        )
    }

    func cancelAll() {
        currentTask?.cancel()
        spawnTask?.cancel()
        timerTask?.cancel()
        currentTask = nil
        spawnTask = nil
        timerTask = nil
    }

    // MARK: - Private

    private func runTest() async {
        for n in stride(from: 3, through: 1, by: -1) {
            state = .countdown(n)
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
        }

        startTime = CACurrentMediaTime()
        state = .playing
        startSpawner()
        startTimer()
    }

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - startTime
                remainingTime = max(0, gameDuration - elapsed)

                // Remove expired shapes
                let now = CACurrentMediaTime()
                shapes.removeAll { shape in
                    !shape.isCollected && (now - shape.spawnTime) > shapeLifetime
                }
                // Also remove collected shapes after brief delay
                shapes.removeAll { shape in
                    shape.isCollected && (now - shape.spawnTime) > shapeLifetime
                }

                if remainingTime <= 0 {
                    spawnTask?.cancel()
                    state = .completed
                    return
                }

                do { try await Task.sleep(nanoseconds: 16_000_000) } catch { return }
            }
        }
    }

    private func startSpawner() {
        spawnTask = Task {
            while !Task.isCancelled {
                // Spawn 1-2 shapes at once
                let count = Int.random(in: 1...2)
                for _ in 0..<count { spawnShape() }
                let interval = Double.random(in: 0.10...0.20)
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch { return }
            }
        }
    }

    private func spawnShape() {
        let kinds: [ShapeKind] = [.circle, .circle, .circle, .triangle, .triangle, .square, .square]
        let kind = kinds.randomElement()!
        let x = CGFloat.random(in: 0.1...0.9)
        let y = CGFloat.random(in: 0.1...0.85)
        let now = CACurrentMediaTime()

        if kind == .circle {
            totalCirclesSpawned += 1
        }

        // Auto-collect: if square spawns on top of existing circle
        if kind == .square {
            for i in shapes.indices {
                guard shapes[i].kind == .circle && !shapes[i].isCollected else { continue }
                let dx = shapes[i].x - x
                let dy = shapes[i].y - y
                if sqrt(dx * dx + dy * dy) < autoCollectRadius {
                    shapes[i].isCollected = true
                    circlesAutoCollected += 1
                    break
                }
            }
        }

        let shape = SpawnedShape(kind: kind, x: x, y: y, spawnTime: now)
        shapes.append(shape)
    }
}
