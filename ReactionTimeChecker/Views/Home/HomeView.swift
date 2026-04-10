// Views/Home/HomeView.swift
import SwiftUI
import TopDesignSystem

struct HomeView: View {
    @Binding var phase: AppPhase
    @State private var selectedRounds: Int = 5
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    Spacer().frame(height: DesignSpacing.xl)

                    // App title
                    Text("ReactionTimeChecker")
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)

                    // Lightning bolt emoji decoration
                    Text("⚡️")
                        .font(.system(size: 72))

                    // Sub copy
                    Text("얼마나 빠른지 확인해볼까?")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    // Round selector card
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            Text("측정 횟수 선택")
                                .font(.ssTitle2)
                                .foregroundStyle(palette.textPrimary)

                            RoundSelectorView(selected: $selectedRounds)
                        }
                        .padding(DesignSpacing.md)
                    }
                    .padding(.horizontal, DesignSpacing.md)

                    // Round info text
                    Text("\(selectedRounds)회 측정 후 등급 발표!")
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)

                    // Start button
                    PillButton(title: "시작하기") {
                        phase = .testing(rounds: selectedRounds)
                    }
                    .padding(.horizontal, DesignSpacing.lg)

                    // Warning
                    Text("⚠️ 빨간 화면에서 절대 탭하지 마세요!")
                        .font(.ssCaption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSpacing.lg)

                    Spacer().frame(height: DesignSpacing.xl)
                }
            }
        }
    }
}
