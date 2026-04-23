// Views/TimeSense/TimeSenseHomeView.swift
import SwiftUI
import TopDesignSystem

struct TimeSenseHomeView: View {
    let onStart: (Bool) -> Void  // timerVisible
    var onBack: (() -> Void)? = nil
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if let onBack {
                    HStack {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left").font(.ssBody)
                                Text(String(localized: "Back")).font(.ssBody)
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

                        Text(String(localized: "Time Sense"))
                            .font(.ssTitle1)
                            .foregroundStyle(palette.textPrimary)

                        Text("⏱️")
                            .font(.system(size: 72))

                        Text(String(localized: "Tap at exactly 10.00 seconds"))
                            .font(.ssBody)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)

                        // Mode selection
                        VStack(spacing: DesignSpacing.sm) {
                            Text(String(localized: "Choose Mode"))
                                .font(.ssTitle2)
                                .foregroundStyle(palette.textPrimary)

                            PillButton(String(localized: "Timer Visible")) {
                                onStart(true)
                            }
                            .padding(.horizontal, DesignSpacing.lg)

                            PillButton(String(localized: "Timer Hidden")) {
                                onStart(false)
                            }
                            .padding(.horizontal, DesignSpacing.lg)
                        }

                        Spacer().frame(height: DesignSpacing.xl)
                    }
                }
            }
        }
    }
}
