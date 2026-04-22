// Models/Grade.swift
import Foundation

enum Grade: String, Sendable, CaseIterable {
    case lightningGod
    case ninja
    case cyborg
    case cheetah
    case rabbit
    case human
    case slothJr
    case turtle
    case snail
    case fossil

    var emoji: String {
        switch self {
        case .lightningGod: return "⚡️"
        case .ninja:        return "🥷"
        case .cyborg:       return "🤖"
        case .cheetah:      return "🐆"
        case .rabbit:       return "🐰"
        case .human:        return "🧑"
        case .slothJr:      return "🦥"
        case .turtle:       return "🐢"
        case .snail:        return "🐌"
        case .fossil:       return "🪨"
        }
    }

    var name: String {
        switch self {
        case .lightningGod: return String(localized: "Speed God")
        case .ninja:        return String(localized: "Ninja")
        case .cyborg:       return String(localized: "Cyborg")
        case .cheetah:      return String(localized: "Cheetah")
        case .rabbit:       return String(localized: "Rabbit")
        case .human:        return String(localized: "Human")
        case .slothJr:      return String(localized: "Sloth Jr.")
        case .turtle:       return String(localized: "Turtle")
        case .snail:        return String(localized: "Snail")
        case .fossil:       return String(localized: "Fossil")
        }
    }

    var description: String {
        switch self {
        case .lightningGod: return String(localized: "Faster than lightning")
        case .ninja:        return String(localized: "Even ninjas can't keep up")
        case .cyborg:       return String(localized: "You've exceeded human limits")
        case .cheetah:      return String(localized: "On par with the fastest animals on Earth")
        case .rabbit:       return String(localized: "Above average reflexes")
        case .human:        return String(localized: "Decent, nothing to be ashamed of")
        case .slothJr:      return String(localized: "Try to focus a little more...")
        case .turtle:       return String(localized: "Slow is okay, keep it up!")
        case .snail:        return String(localized: "Even snails are faster")
        case .fossil:       return String(localized: "Were you asleep...?")
        }
    }

    var percentileUpperBound: Int {
        switch self {
        case .lightningGod: return 10
        case .ninja:        return 20
        case .cyborg:       return 30
        case .cheetah:      return 40
        case .rabbit:       return 50
        case .human:        return 60
        case .slothJr:      return 70
        case .turtle:       return 80
        case .snail:        return 90
        case .fossil:       return 100
        }
    }
}
