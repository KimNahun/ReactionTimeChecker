// Views/Home/HomeView.swift
import SwiftUI
import TopDesignSystem

struct HomeView: View {
    @Binding var phase: AppPhase
    var onBack: (() -> Void)? = nil
    @State private var selectedRounds: Int = 5
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                if let onBack {
                    HStack {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.ssBody)
                                Text(String(localized: "Back"))
                                    .font(.ssBody)
                            }
                            .foregroundStyle(palette.primaryAction)
                        }
                        .padding(.horizontal, DesignSpacing.md)
                        .padding(.top, DesignSpacing.sm)
                        Spacer()
                    }
                }

            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    Spacer().frame(height: onBack != nil ? DesignSpacing.sm : DesignSpacing.xl)

                    // App title
                    Text("QuickTap")
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .padding(.horizontal, DesignSpacing.md)

                    // Lightning bolt emoji decoration
                    Text("⚡️")
                        .font(.system(size: 72))

                    // Sub copy
                    Text("How fast are you?")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    // Round selector card
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            Text("Select Rounds")
                                .font(.ssTitle2)
                                .foregroundStyle(palette.textPrimary)

                            RoundSelectorView(selected: $selectedRounds)
                        }
                        .padding(DesignSpacing.md)
                    }
                    .padding(.horizontal, DesignSpacing.md)

                    // Round info text
                    Text("\(selectedRounds) rounds, then reveal your grade!")
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)

                    // Start button
                    PillButton(String(localized: "Start")) {
                        phase = .testing(rounds: selectedRounds)
                    }
                    .padding(.horizontal, DesignSpacing.lg)

                    // Warning
                    Text("⚠️ Do NOT tap on the red screen!")
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
}
