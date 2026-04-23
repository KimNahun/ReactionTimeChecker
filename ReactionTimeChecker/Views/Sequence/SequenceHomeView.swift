// Views/Sequence/SequenceHomeView.swift
import SwiftUI
import TopDesignSystem

struct SequenceHomeView: View {
    let onStart: () -> Void
    var onBack: (() -> Void)? = nil
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if let onBack {
                    HStack {
                        Button { onBack() } label: {
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

                        Text(String(localized: "Sequence"))
                            .font(.ssTitle1)
                            .foregroundStyle(palette.textPrimary)

                        Text("🔢")
                            .font(.system(size: 72))

                        Text(String(localized: "Tap numbers in ascending order!"))
                            .font(.ssBody)
                            .foregroundStyle(palette.textSecondary)

                        SurfaceCard(elevation: .raised) {
                            VStack(spacing: DesignSpacing.md) {
                                Text(String(localized: "How to Play"))
                                    .font(.ssTitle2)
                                    .foregroundStyle(palette.textPrimary)

                                VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                                    ruleRow(icon: "1.circle.fill", text: String(localized: "20 random numbers appear on screen"))
                                    ruleRow(icon: "2.circle.fill", text: String(localized: "Tap from smallest to largest"))
                                    ruleRow(icon: "3.circle.fill", text: String(localized: "Wrong tap = +3 second penalty!"))
                                }
                            }
                            .padding(DesignSpacing.md)
                        }
                        .padding(.horizontal, DesignSpacing.md)

                        PillButton(String(localized: "Start")) { onStart() }
                            .padding(.horizontal, DesignSpacing.lg)

                        Spacer().frame(height: DesignSpacing.xl)
                    }
                }
            }
        }
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSpacing.sm) {
            Image(systemName: icon).font(.ssBody).foregroundStyle(palette.primaryAction).frame(width: 24)
            Text(text).font(.ssFootnote).foregroundStyle(palette.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
