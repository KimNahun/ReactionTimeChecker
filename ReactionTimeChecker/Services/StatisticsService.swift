// Services/StatisticsService.swift

protocol StatisticsServiceProtocol: Sendable {
    func calculatePercentile(averageMs: Int) -> Int
    func determineGrade(percentile: Int) -> Grade
}

struct StatisticsService: StatisticsServiceProtocol, Sendable {
    // Distribution based on humanbenchmark.com data (mean ~273ms, mode ~215ms, right-skewed)
    private let anchors: [(ms: Int, percentile: Double)] = [
        (100, 0.5),   // 극소수 (세계 기록급)
        (125, 1.0),   // 상위 1%
        (150, 4.0),   // 상위 4%
        (175, 13.0),  // 상위 13%
        (200, 30.0),  // 상위 30%
        (215, 42.0),  // 최빈값 구간 (~215ms)
        (230, 52.0),  // 중앙값 (~230ms)
        (250, 64.0),  // 하위 36%
        (275, 74.0),  // 하위 26%
        (300, 82.0),  // 하위 18%
        (340, 90.0),  // 하위 10%
        (390, 95.0),  // 하위 5%
        (475, 99.0),  // 하위 1%
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
