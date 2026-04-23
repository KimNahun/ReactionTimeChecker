// Views/Sequence/SequenceTestView.swift
import SwiftUI
import TopDesignSystem

struct SequenceTestView: View {
    let onComplete: (SequenceSession) -> Void
    let onCancel: () -> Void

    @State private var viewModel = SequenceViewModel()
    @Environment(\.designPalette) var palette

    private let columns = 5
    private let rows = 4

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Timer display
                timerBar
                    .padding(.top, DesignSpacing.sm)

                Spacer()

                stateContent

                Spacer()
            }

            // Floating penalty
            if viewModel.showPenalty {
                Text(viewModel.penaltyLabel)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.4), value: viewModel.showPenalty)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        HStack {
            // Back button
            Button {
                viewModel.cancelAll()
                onCancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.ssBody)
                    .foregroundStyle(palette.primaryAction)
            }

            // Timer
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

            // Progress
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

        case .completed(let totalMs):
            Text(String(localized: "Done!"))
                .font(.ssTitle1)
                .foregroundStyle(palette.textPrimary)
                .onAppear {
                    let _ = totalMs
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
        let isNext = num.value == viewModel.nextTarget
        let isWrong: Bool = {
            if case .wrongTap = viewModel.state { return false }
            return false
        }()

        return Button {
            viewModel.handleTap(value: num.value)
        } label: {
            Text("\(num.value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(num.isTapped ? palette.textSecondary.opacity(0.3) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cellColor(num: num, isNext: isNext))
                )
        }
        .disabled(num.isTapped)
        .animation(.easeInOut(duration: 0.15), value: num.isTapped)
        .modifier(ShakeEffect(animatableData: isWrong ? 1 : 0))
    }

    private func cellColor(num: SequenceNumber, isNext: Bool) -> some ShapeStyle {
        if num.isTapped {
            return AnyShapeStyle(palette.surface.opacity(0.4))
        }
        if isNext {
            return AnyShapeStyle(palette.primaryAction)
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
        case .completed:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        default:
            break
        }
    }
}
