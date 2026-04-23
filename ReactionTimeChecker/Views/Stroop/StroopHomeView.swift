// Views/Stroop/StroopHomeView.swift
import SwiftUI
import TopDesignSystem

struct StroopHomeView: View {
    let onStart: (Int) -> Void
    var onBack: (() -> Void)? = nil
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

                        Text(String(localized: "Color Stroop"))
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .padding(.horizontal, DesignSpacing.md)

                    Text("🎨")
                        .font(.system(size: 72))

                    Text(String(localized: "Can you ignore the word?"))
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    // How it works card
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.md) {
                            Text(String(localized: "How to Play"))
                                .font(.ssTitle2)
                                .foregroundStyle(palette.textPrimary)

                            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                                ruleRow(
                                    icon: "1.circle.fill",
                                    text: String(localized: "A color word appears in a DIFFERENT color")
                                )
                                ruleRow(
                                    icon: "2.circle.fill",
                                    text: String(localized: "Look at the TEXT COLOR, not the word!")
                                )
                                ruleRow(
                                    icon: "3.circle.fill",
                                    text: String(localized: "Tap ONLY when text color matches the target")
                                )
                            }

                            // Example
                            exampleView
                        }
                        .padding(DesignSpacing.md)
                    }
                    .padding(.horizontal, DesignSpacing.md)

                    // Round info
                    Text(String(format: String(localized: "%lld rounds"), 20))
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)

                    PillButton(String(localized: "Start")) {
                        onStart(20)
                    }
                    .padding(.horizontal, DesignSpacing.lg)

                    Text(String(localized: "⚠️ Words will flash fast — stay focused!"))
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

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSpacing.sm) {
            Image(systemName: icon)
                .font(.ssBody)
                .foregroundStyle(palette.primaryAction)
                .frame(width: 24)
            Text(text)
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exampleView: some View {
        VStack(spacing: DesignSpacing.xs) {
            Text(String(localized: "Example:"))
                .font(.ssCaption)
                .foregroundStyle(palette.textSecondary)

            HStack(spacing: DesignSpacing.lg) {
                // Example: "빨강" written in blue
                VStack(spacing: 4) {
                    Text(StroopColor.red.displayName)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(StroopColor.blue.swiftUIColor)
                    Text("→ \(StroopColor.blue.displayName)")
                        .font(.ssCaption)
                        .foregroundStyle(palette.textSecondary)
                }

                // Example: "초록" written in red
                VStack(spacing: 4) {
                    Text(StroopColor.green.displayName)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(StroopColor.red.swiftUIColor)
                    Text("→ \(StroopColor.red.displayName)")
                        .font(.ssCaption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .padding(DesignSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.surface)
        )
    }
}
