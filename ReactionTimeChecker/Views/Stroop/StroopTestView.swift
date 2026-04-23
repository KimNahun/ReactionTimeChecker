// Views/Stroop/StroopTestView.swift
import SwiftUI
import TopDesignSystem

struct StroopTestView: View {
    let totalStimuli: Int
    let onComplete: (StroopSession) -> Void
    let onCancel: () -> Void

    @State private var viewModel: StroopViewModel
    @Environment(\.designPalette) var palette

    @State private var shakeTrigger: CGFloat = 0
    @State private var wordScale: CGFloat = 1.0
    @State private var touchProcessed = false

    init(totalStimuli: Int, onComplete: @escaping (StroopSession) -> Void, onCancel: @escaping () -> Void) {
        self.totalStimuli = totalStimuli
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._viewModel = State(initialValue: StroopViewModel(totalStimuli: totalStimuli))
    }

    var body: some View {
        ZStack {
            backgroundColorView
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.1), value: backgroundKey)

            VStack(spacing: 0) {
                // Progress
                StroopProgressView(
                    completed: viewModel.completedCount,
                    total: viewModel.totalStimuli,
                    correct: viewModel.correctCount,
                    falseAlarms: viewModel.falseAlarmCount
                )
                .padding(.top, DesignSpacing.sm)

                Spacer()

                stateContent
                    .modifier(ShakeModifier(trigger: shakeTrigger))

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !touchProcessed else { return }
                    touchProcessed = true
                    viewModel.handleTap()
                }
                .onEnded { _ in
                    touchProcessed = false
                }
        )
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear {
            viewModel.startTest()
        }
        .onDisappear {
            viewModel.cancelCurrentTask()
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundColorView: some View {
        switch viewModel.state {
        case .correctTap:
            palette.success
        case .falseAlarm:
            palette.error
        case .missed:
            Color.orange.opacity(0.8)
        case .countdown, .instruction:
            palette.surface
        default:
            palette.background
        }
    }

    private var backgroundKey: String {
        switch viewModel.state {
        case .idle:            return "idle"
        case .instruction:     return "instruction"
        case .countdown:       return "countdown"
        case .showing(let i):  return "showing_\(i)"
        case .correctTap:      return "correct"
        case .falseAlarm:      return "false"
        case .missed:          return "missed"
        case .completed:       return "completed"
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .instruction:
            VStack(spacing: DesignSpacing.lg) {
                Text(String(localized: "Target Color"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textSecondary)

                // Show a different color NAME in the target color (Stroop style)
                Text(viewModel.targetColor.randomOther().displayName)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(viewModel.targetColor.swiftUIColor)

                Text(String(localized: "Tap when the text color is this color!"))
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSpacing.lg)
            }

        case .countdown(let n):
            VStack(spacing: DesignSpacing.lg) {
                CountdownView(seconds: n)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.55),
                        value: n
                    )
                Text(String(localized: "Get ready..."))
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
            }

        case .showing(let index):
            if index < viewModel.stimuli.count {
                let stimulus = viewModel.stimuli[index]
                VStack(spacing: DesignSpacing.md) {
                    Text(stimulus.textLabel)
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(stimulus.displayColor.swiftUIColor)
                        .scaleEffect(wordScale)
                        .id("stimulus_\(index)")
                        .transition(.scale(scale: 0.5).combined(with: .opacity))

                    // Target reminder — show previous stimulus combo
                    if let prev = viewModel.previousStimulus {
                        VStack(spacing: 2) {
                            Text(prev.textLabel)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(prev.displayColor.swiftUIColor)
                            Text("↑ \(prev.isTarget ? "O" : "X")")
                                .font(.ssCaption)
                                .foregroundStyle(palette.textSecondary.opacity(0.5))
                        }
                        .padding(.top, DesignSpacing.sm)
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.targetColor.swiftUIColor)
                                .frame(width: 12, height: 12)
                            Text(viewModel.targetColor.displayName)
                                .font(.ssCaption)
                                .foregroundStyle(palette.textSecondary.opacity(0.6))
                        }
                    }
                }
                .onAppear {
                    wordScale = 0.7
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        wordScale = 1.0
                    }
                }
            }

        case .correctTap(let ms):
            VStack(spacing: DesignSpacing.sm) {
                Text("\(ms) ms")
                    .font(.ssLargeTitle)
                    .foregroundStyle(.white)
                Text("✓")
                    .font(.system(size: 40))
            }

        case .falseAlarm:
            VStack(spacing: DesignSpacing.sm) {
                Text("✗")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                Text(String(localized: "Wrong! Don't tap that color"))
                    .font(.ssTitle2)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

        case .missed:
            VStack(spacing: DesignSpacing.sm) {
                Text(String(localized: "Too slow!"))
                    .font(.ssTitle1)
                    .foregroundStyle(.white)
                Text(String(localized: "That was the target color"))
                    .font(.ssBody)
                    .foregroundStyle(.white.opacity(0.8))
            }

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

    // MARK: - State Change Haptics

    private func handleStateChange(_ newState: StroopTestState) {
        switch newState {
        case .countdown:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

        case .showing:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            wordScale = 0.7

        case .correctTap:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        case .falseAlarm:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.linear(duration: 0.4)) {
                shakeTrigger += 1
            }

        case .missed:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

        default:
            break
        }
    }
}

// MARK: - StroopProgressView

private struct StroopProgressView: View {
    let completed: Int
    let total: Int
    let correct: Int
    let falseAlarms: Int
    @Environment(\.designPalette) var palette

    var body: some View {
        HStack(spacing: DesignSpacing.xs) {
            // Progress dots
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Text("\(completed) / \(total)")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)

            if falseAlarms > 0 {
                Text("✗ \(falseAlarms)")
                    .font(.ssCaption)
                    .foregroundStyle(palette.error)
            }
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, DesignSpacing.md)
    }

    private func dotColor(for index: Int) -> AnyShapeStyle {
        if index < completed {
            return AnyShapeStyle(palette.success)
        } else if index == completed {
            return AnyShapeStyle(palette.primaryAction)
        } else {
            return AnyShapeStyle(palette.surface)
        }
    }
}

// Reuse ShakeModifier from TestComponents
private struct ShakeModifier: ViewModifier {
    let trigger: CGFloat

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: trigger))
    }
}
