// Views/BiggestCircle/BiggestCircleHomeView.swift
import SwiftUI
import TopDesignSystem

struct BiggestCircleHomeView: View {
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
                            HStack(spacing: 4) { Image(systemName: "chevron.left").font(.ssBody); Text(String(localized: "Back")).font(.ssBody) }.foregroundStyle(palette.primaryAction)
                        }.padding(.horizontal, DesignSpacing.md).padding(.top, DesignSpacing.sm); Spacer()
                    }
                }
                ScrollView {
                    VStack(spacing: DesignSpacing.lg) {
                        Spacer().frame(height: onBack != nil ? DesignSpacing.sm : DesignSpacing.xl)
                        Text(String(localized: "Biggest Circle")).font(.ssTitle1).foregroundStyle(palette.textPrimary)
                        Text("📐").font(.system(size: 72))
                        Text(String(localized: "Find the biggest circle!")).font(.ssBody).foregroundStyle(palette.textSecondary)
                        SurfaceCard(elevation: .raised) {
                            VStack(spacing: DesignSpacing.md) {
                                Text(String(localized: "How to Play")).font(.ssTitle2).foregroundStyle(palette.textPrimary)
                                VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                                    ruleRow(icon: "1.circle.fill", text: String(localized: "5 circles appear at random positions"))
                                    ruleRow(icon: "2.circle.fill", text: String(localized: "Tap the BIGGEST one!"))
                                    ruleRow(icon: "3.circle.fill", text: String(localized: "Size difference shrinks, time limit drops!"))
                                }
                            }.padding(DesignSpacing.md)
                        }.padding(.horizontal, DesignSpacing.md)
                        PillButton(String(localized: "Start")) { onStart() }.padding(.horizontal, DesignSpacing.lg)
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
