// Models/ReactionError.swift

enum ReactionError: Error, Sendable {
    case taskCancelled
    case invalidState
    case noValidAttempts
}
