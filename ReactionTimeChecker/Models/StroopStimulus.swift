// Models/StroopStimulus.swift

struct StroopStimulus: Sendable, Equatable {
    let textLabel: String        // The word displayed (e.g. "빨강")
    let textMeaning: StroopColor // What the word means (e.g. .red)
    let displayColor: StroopColor // Actual font color (e.g. .blue)
    let isTarget: Bool           // displayColor == targetColor
}
