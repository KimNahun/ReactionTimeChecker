// Models/Grade.swift

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
        case .lightningGod: return "반응속도의 신"
        case .ninja:        return "닌자"
        case .cyborg:       return "사이보그"
        case .cheetah:      return "치타"
        case .rabbit:       return "토끼"
        case .human:        return "일반인"
        case .slothJr:      return "나무늘보 주니어"
        case .turtle:       return "거북이"
        case .snail:        return "달팽이"
        case .fossil:       return "화석"
        }
    }

    var description: String {
        switch self {
        case .lightningGod: return "당신은 번개보다 빠릅니다"
        case .ninja:        return "닌자도 당신 앞엔 느림보"
        case .cyborg:       return "인간의 한계를 넘었군요"
        case .cheetah:      return "지구상 가장 빠른 동물급"
        case .rabbit:       return "평균 이상의 빠른 손"
        case .human:        return "평범하지만 나쁘지 않아요"
        case .slothJr:      return "조금 더 집중해봐요..."
        case .turtle:       return "느려도 괜찮아요, 꾸준히!"
        case .snail:        return "달팽이도 당신보다 빠릅니다"
        case .fossil:       return "혹시 자고 계셨나요...?"
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
