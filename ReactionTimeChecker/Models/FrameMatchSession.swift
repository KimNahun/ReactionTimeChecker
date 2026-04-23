// Models/FrameMatchSession.swift
import Foundation

struct FrameMatchSession: Sendable {
    let errors: [CGFloat]  // error in pt per round
    let averageError: CGFloat
    let bestError: CGFloat
    let totalRounds: Int

    init(errors: [CGFloat]) {
        self.errors = errors
        self.totalRounds = errors.count
        self.averageError = errors.isEmpty ? 999 : errors.reduce(0, +) / CGFloat(errors.count)
        self.bestError = errors.min() ?? 999
    }
}
