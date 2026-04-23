// Views/Components/NameInputView.swift
import SwiftUI
import TopDesignSystem

struct NameInputView: View {
    let onComplete: (String) -> Void
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            SurfaceCard(elevation: .raised) {
                VStack(spacing: DesignSpacing.lg) {
                    Text("QuickTap")
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)

                    Text("⚡️")
                        .font(.system(size: 56))

                    Text(String(localized: "Enter your name"))
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    TextField(String(localized: "Name"), text: $name)
                        .font(.ssTitle2)
                        .multilineTextAlignment(.center)
                        .padding(DesignSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignCornerRadius.lg)
                                .fill(palette.background)
                        )
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { confirmName() }

                    PillButton(String(localized: "Confirm")) {
                        confirmName()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                }
                .padding(DesignSpacing.lg)
            }
            .padding(.horizontal, DesignSpacing.lg)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }

    private func confirmName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        UserNameService.name = trimmed
        onComplete(trimmed)
    }
}
