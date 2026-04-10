// Models/AppPhase.swift

enum AppPhase: Sendable {
    case home
    case testing(rounds: Int)
    case result(session: TestSession)
}
