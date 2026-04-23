// Models/AppPhase.swift

enum AppPhase: Sendable, Equatable {
    case home
    case testing(rounds: Int)
    case result(session: TestSession)

    static func == (lhs: AppPhase, rhs: AppPhase) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): return true
        case (.testing(let a), .testing(let b)): return a == b
        case (.result, .result): return true
        default: return false
        }
    }
}
