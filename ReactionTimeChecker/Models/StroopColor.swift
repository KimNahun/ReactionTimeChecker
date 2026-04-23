// Models/StroopColor.swift
import SwiftUI

enum StroopColor: String, CaseIterable, Sendable, Codable, Equatable {
    case red, blue, green, yellow, purple

    var displayName: String {
        switch self {
        case .red:    return String(localized: "StroopRed")
        case .blue:   return String(localized: "StroopBlue")
        case .green:  return String(localized: "StroopGreen")
        case .yellow: return String(localized: "StroopYellow")
        case .purple: return String(localized: "StroopPurple")
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .red:    return Color(red: 0.95, green: 0.2, blue: 0.2)
        case .blue:   return Color(red: 0.2, green: 0.4, blue: 0.95)
        case .green:  return Color(red: 0.1, green: 0.75, blue: 0.3)
        case .yellow: return Color(red: 0.82, green: 0.58, blue: 0.0)
        case .purple: return Color(red: 0.6, green: 0.2, blue: 0.9)
        }
    }

    /// Returns a random color excluding self
    func randomOther() -> StroopColor {
        let others = StroopColor.allCases.filter { $0 != self }
        return others.randomElement()!
    }
}
