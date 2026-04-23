// Views/Sequence/SequenceTestView.swift
import SwiftUI
import TopDesignSystem

struct SequenceTestView: View {
    let onComplete: (SequenceSession) -> Void
    let onCancel: () -> Void

    @State private var viewModel = SequenceViewModel()
    @Environment(\.designPalette) var palette

    @State private var shakeTrigger: CGFloat = 0
    @State private var showRedFlash: Bool = false

    private let columns = 5
    private let rows = 4

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            // Red flash on wrong tap
            if showRedFlash {
                Color.red.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                timerBar
                    .padding(.top, DesignSpacing.sm)

                Spacer()

                stateContent

                Spacer()
            }

            // "+3s" penalty overlay — dead center
            if viewModel.showPenalty {
                Text(viewModel.penaltyLabel)
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .shadow(color: .red.opacity(0.5), radius: 10)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .modifier(ShakeEffect(animatableData: shakeTrigger))
        .animation(.easeInOut(duration: 0.1), value: showRedFlash)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.showPenalty)
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        HStack {
            Button {
                viewModel.cancelAll()
                onCancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.ssBody)
                    .foregroundStyle(palette.primaryAction)
            }

            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.ssCaption)
                    .foregroundStyle(palette.textSecondary)
                Text(formatTime(viewModel.displayTime))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText())
            }

            Spacer()

            Text("\(viewModel.tappedCount) / \(viewModel.numberCount)")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)

            if viewModel.penaltyCount > 0 {
                Text("+" + formatTime(viewModel.penaltyTime))
                    .font(.ssCaption)
                    .foregroundStyle(palette.error)
            }
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.horizontal, DesignSpacing.md)
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .countdown(let n):
            VStack(spacing: DesignSpacing.lg) {
                CountdownView(seconds: n)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
                Text(String(localized: "Tap numbers in order!"))
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
            }

        case .playing, .wrongTap:
            numberGrid

        case .completed:
            Text(String(localized: "Done!"))
                .font(.ssTitle1)
                .foregroundStyle(palette.textPrimary)
                .onAppear {
                    let session = viewModel.buildSession()
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        onComplete(session)
                    }
                }
        }
    }

    // MARK: - Number Grid

    private var numberGrid: some View {
        let sorted = viewModel.numbers.sorted { $0.gridIndex < $1.gridIndex }
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns),
            spacing: 8
        ) {
            ForEach(sorted) { num in
                numberCell(num)
            }
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    private func numberCell(_ num: SequenceNumber) -> some View {
        Button {
            viewModel.handleTap(value: num.value)
        } label: {
            Text("\(num.value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(num.isTapped ? palette.textSecondary.opacity(0.3) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cellColor(num: num))
                )
        }
        .disabled(num.isTapped)
        .animation(.easeInOut(duration: 0.15), value: num.isTapped)
    }

    private func cellColor(num: SequenceNumber) -> some ShapeStyle {
        if num.isTapped {
            return AnyShapeStyle(palette.surface.opacity(0.4))
        }
        return AnyShapeStyle(palette.surface)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        let ms = Int((seconds - Double(s)) * 100)
        return String(format: "%d.%02d", s, ms)
    }

    private func handleStateChange(_ newState: SequenceState) {
        switch newState {
        case .countdown:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .wrongTap:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // Red flash + shake
            showRedFlash = true
            withAnimation(.linear(duration: 0.3)) {
                shakeTrigger += 1
            }
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                showRedFlash = false
            }
        case .completed:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        default:
            break
        }
    }
}
