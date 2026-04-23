// Views/Stroop/StroopShareCardView.swift
import SwiftUI
import UIKit

struct StroopShareCardView: View {
    let averageMs: Int
    let bestMs: Int
    let worstMs: Int
    let accuracy: Int
    let percentile: Int
    let grade: Grade

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(hex2: 0x1A0A2E), Color(hex2: 0x3D1C6E), Color(hex2: 0x2E1A47)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [gradeAccentColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(y: -30)

            VStack(spacing: 0) {
                // App branding
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(gradeAccentColor)
                    Text("QuickTap · Stroop")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.5)
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(gradeAccentColor)
                }
                .padding(.top, 28)

                Spacer().frame(height: 20)

                // Grade emoji
                Text(grade.emoji)
                    .font(.system(size: 80))
                    .shadow(color: gradeAccentColor.opacity(0.5), radius: 20)

                Spacer().frame(height: 12)

                // Average ms
                Text("\(averageMs)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                + Text(" ms")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer().frame(height: 4)

                // Grade name
                Text(grade.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(gradeAccentColor)

                Spacer().frame(height: 16)

                // Stats row
                HStack(spacing: 0) {
                    statBadge(label: "TOP", value: "\(percentile)%", color: Color(hex2: 0xFFD700))
                    divider
                    statBadge(label: "ACC", value: "\(accuracy)%", color: Color(hex2: 0x00CCFF))
                    divider
                    statBadge(label: "BEST", value: "\(bestMs)ms", color: Color(hex2: 0x00FF88))
                    divider
                    statBadge(label: "WORST", value: "\(worstMs)ms", color: Color(hex2: 0xFF6B6B))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer().frame(height: 20)

                // Challenge text
                Text(String(localized: "Can you beat my Stroop score?"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer().frame(height: 24)
            }
        }
        .frame(width: 320, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Helpers

    private var gradeAccentColor: Color {
        switch grade {
        case .lightningGod, .ninja: return Color(hex2: 0x00D2FF)
        case .cyborg, .cheetah:     return Color(hex2: 0x7B68EE)
        case .rabbit, .human:       return Color(hex2: 0x4CAF50)
        case .slothJr, .turtle:     return Color(hex2: 0xFF9800)
        case .snail, .fossil:       return Color(hex2: 0xFF5252)
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 32)
    }
}

// MARK: - Render to UIImage

extension StroopShareCardView {
    @MainActor
    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Color hex helper

private extension Color {
    init(hex2: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex2 >> 16) & 0xFF) / 255,
            green: Double((hex2 >> 8) & 0xFF) / 255,
            blue: Double(hex2 & 0xFF) / 255,
            opacity: opacity
        )
    }
}
