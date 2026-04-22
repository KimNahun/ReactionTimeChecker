// Services/ReactionTestService.swift
import QuartzCore

protocol ReactionTestServiceProtocol: Sendable {
    func scheduleGreen() async throws
    func randomDelay() async -> Double
}

actor ReactionTestService: ReactionTestServiceProtocol {
    func scheduleGreen() async throws {
        let delay = Double.random(in: 1.0...5.0)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    func randomDelay() async -> Double {
        return Double.random(in: 1.0...5.0)
    }
}
