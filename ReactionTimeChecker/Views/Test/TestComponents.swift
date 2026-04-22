// Views/Test/TestComponents.swift
import SwiftUI
import TopDesignSystem

// MARK: - ShakeEffect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

// MARK: - CountdownView

struct CountdownView: View {
    let seconds: Int
    @Environment(\.designPalette) var palette
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(palette.primaryAction.opacity(0.3), lineWidth: 4)
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseScale = 1.12
                    }
                }

            Text("\(seconds)")
                .font(.ssLargeTitle)
                .foregroundStyle(palette.textPrimary)
                .id(seconds)
                .transition(
                    .scale(scale: 0.5)
                    .combined(with: .opacity)
                )
        }
    }
}

// MARK: - RoundProgressView

struct RoundProgressView: View {
    let current: Int      // validRoundCount (0-based completed)
    let total: Int
    let cheatedCount: Int
    @Environment(\.designPalette) var palette

    var body: some View {
        HStack(spacing: DesignSpacing.xs) {
            // Dot indicators
            HStack(spacing: DesignSpacing.xs) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }

            Spacer()

            // Round text
            Text("\(min(current + 1, total)) / \(total)")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)

            // Cheated badge
            if cheatedCount > 0 {
                Text("❌ \(cheatedCount)")
                    .font(.ssCaption)
                    .foregroundStyle(palette.error)
            }
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, DesignSpacing.md)
    }

    private func dotColor(for index: Int) -> AnyShapeStyle {
        if index < current {
            return AnyShapeStyle(palette.success)
        } else if index == current {
            return AnyShapeStyle(palette.primaryAction)
        } else {
            return AnyShapeStyle(palette.surface)
        }
    }
}
