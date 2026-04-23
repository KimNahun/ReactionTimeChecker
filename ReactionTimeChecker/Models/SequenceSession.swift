// Models/SequenceSession.swift
import Foundation

struct SequenceNumber: Identifiable, Sendable {
    let id: UUID
    let value: Int
    let gridIndex: Int
    var isTapped: Bool

    init(id: UUID = UUID(), value: Int, gridIndex: Int, isTapped: Bool = false) {
        self.id = id
        self.value = value
        self.gridIndex = gridIndex
        self.isTapped = isTapped
    }
}

struct SequenceSession: Sendable {
    let totalTimeMs: Int
    let penaltyCount: Int
    let penaltyTimeMs: Int
    let numberCount: Int

    /// Net time without penalties
    var pureTimeMs: Int { totalTimeMs - penaltyTimeMs }
}
