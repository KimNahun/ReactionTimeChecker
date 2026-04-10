// Views/Result/GradeCardView.swift
import SwiftUI
import TopDesignSystem

struct GradeCardView: View {
    let grade: Grade
    let showEmoji: Bool
    let showName: Bool
    let showDescription: Bool
    @Environment(\.designPalette) var palette

    @State private var emojiScale: CGFloat = 0.3
    @State private var emojiRotation: Double = 0

    var body: some View {
        GlassCard {
            VStack(spacing: DesignSpacing.md) {
                if showEmoji {
                    Text(grade.emoji)
                        .font(.system(size: 96))
                        .scaleEffect(emojiScale)
                        .rotationEffect(.degrees(emojiRotation))
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                                emojiScale = 1.0
                                emojiRotation = 360
                            }
                        }
                }

                if showName {
                    Text(grade.name)
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showDescription {
                    Text(grade.description)
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSpacing.sm)
                        .transition(.opacity)
                }
            }
            .padding(DesignSpacing.lg)
            .frame(maxWidth: .infinity)
        }
    }
}
