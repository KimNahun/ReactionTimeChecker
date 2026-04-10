// Services/StatisticsService.swift

protocol StatisticsServiceProtocol: Sendable {
    func calculatePercentile(averageMs: Int) -> Int
    func determineGrade(percentile: Int) -> Grade
}

struct StatisticsService: StatisticsServiceProtocol, Sendable {
    private let anchors: [(ms: Int, percentile: Double)] = [
        (100, 0.5),
        (150, 1.0),
        (175, 5.0),
        (190, 10.0),
        (205, 20.0),
        (220, 30.0),
        (235, 40.0),
        (250, 50.0),
        (265, 60.0),
        (280, 70.0),
        (300, 80.0),
        (330, 90.0),
        (400, 99.0),
    ]

    func calculatePercentile(averageMs: Int) -> Int {
        // Below minimum anchor
        if averageMs <= anchors.first!.ms {
            return 1
        }
        // Above maximum anchor
        if averageMs >= anchors.last!.ms {
            return 99
        }

        // Find surrounding anchors and linearly interpolate
        for i in 0..<(anchors.count - 1) {
            let lo = anchors[i]
            let hi = anchors[i + 1]
            if averageMs >= lo.ms && averageMs <= hi.ms {
                let t = Double(averageMs - lo.ms) / Double(hi.ms - lo.ms)
                let p = lo.percentile + t * (hi.percentile - lo.percentile)
                return max(1, min(99, Int(p.rounded())))
            }
        }
        return 99
    }

    func determineGrade(percentile: Int) -> Grade {
        switch percentile {
        case ...10:   return .lightningGod
        case 11...20: return .ninja
        case 21...30: return .cyborg
        case 31...40: return .cheetah
        case 41...50: return .rabbit
        case 51...60: return .human
        case 61...70: return .slothJr
        case 71...80: return .turtle
        case 81...90: return .snail
        default:      return .fossil
        }
    }
}
