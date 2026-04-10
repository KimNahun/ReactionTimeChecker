// Services/ReactionTestService.swift
import QuartzCore

protocol ReactionTestServiceProtocol: Sendable {
    func scheduleGreen() async throws
    func markGreen() async
    func calculateMs(tapTime: Double) async -> Int
    func randomDelay() async -> Double
}

actor ReactionTestService: ReactionTestServiceProtocol {
    private var startTime: Double = 0

    func scheduleGreen() async throws {
        let delay = Double.random(in: 1.0...5.0)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        startTime = CACurrentMediaTime()
    }

    func markGreen() async {
        startTime = CACurrentMediaTime()
    }

    func calculateMs(tapTime: Double) async -> Int {
        return max(0, Int((tapTime - startTime) * 1000))
    }

    func randomDelay() async -> Double {
        return Double.random(in: 1.0...5.0)
    }
}
