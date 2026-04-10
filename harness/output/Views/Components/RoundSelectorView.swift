// Views/Components/RoundSelectorView.swift
import SwiftUI
import TopDesignSystem

struct RoundSelectorView: View {
    @Binding var selected: Int
    @Environment(\.designPalette) var palette

    private let options = [5, 10]

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        selected = option
                    }
                } label: {
                    Text("\(option)회")
                        .font(.ssTitle2)
                        .foregroundStyle(selected == option ? .white : palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignCornerRadius.lg)
                                .fill(selected == option ? palette.accent : palette.surface)
                        )
                }
                .buttonStyle(.pressScale)
                .gentleSpring(value: selected)
            }
        }
        .onChange(of: selected) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
