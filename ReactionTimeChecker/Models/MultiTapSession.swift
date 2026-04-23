// Models/MultiTapSession.swift
import Foundation

enum ShapeKind: Sendable, Equatable {
    case circle, triangle, square
}

struct SpawnedShape: Identifiable, Sendable {
    let id: UUID
    let kind: ShapeKind
    let x: CGFloat  // 0-1 relative
    let y: CGFloat  // 0-1 relative
    let spawnTime: Double
    var isCollected: Bool

    init(id: UUID = UUID(), kind: ShapeKind, x: CGFloat, y: CGFloat, spawnTime: Double, isCollected: Bool = false) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        self.spawnTime = spawnTime
        self.isCollected = isCollected
    }
}

struct MultiTapSession: Sendable {
    let circlesTapped: Int
    let circlesAutoCollected: Int
    let totalCirclesSpawned: Int
    let wrongTaps: Int
    let missedCircles: Int
}
