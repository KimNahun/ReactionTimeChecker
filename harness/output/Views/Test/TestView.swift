// Views/Test/TestView.swift
import SwiftUI
import TopDesignSystem

struct TestView: View {
    let rounds: Int
    @Binding var phase: AppPhase
    @State private var viewModel: TestViewModel
    @Environment(\.designPalette) var palette

    // Animation states
    @State private var shakeTrigger: CGFloat = 0
    @State private var pulseOpacity: Double = 1.0
    @State private var goScale: CGFloat = 1.0

    init(rounds: Int, phase: Binding<AppPhase>) {
        self.rounds = rounds
        self._phase = phase
        self._viewModel = State(initialValue: TestViewModel(totalRounds: rounds))
    }

    var body: some View {
        ZStack {
            // Full-screen background color driven by state
            backgroundColorView
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.12), value: backgroundKey)

            VStack(spacing: 0) {
                // Progress bar — always visible during test
                RoundProgressView(
                    current: viewModel.validRoundCount,
                    total: viewModel.totalRounds,
                    cheatedCount: viewModel.cheatedCount
                )
                .padding(.top, DesignSpacing.sm)

                Spacer()

                // State-specific content
                stateContent
                    .modifier(ShakeModifier(trigger: shakeTrigger))

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let tapTime = CACurrentMediaTime()
            Task { await viewModel.handleTap(at: tapTime) }
        }
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
        case .countdown:
            palette.surface
        case .waiting:
            palette.error
        case .green:
            palette.success
        case .recorded:
            palette.success
        case .cheated:
            palette.error
        default:
            palette.background
        }
    }

    // Used only as animation value to trigger color transitions
    private var backgroundKey: String {
        switch viewModel.state {
        case .countdown:  return "surface"
        case .waiting:    return "error"
        case .green:      return "success"
        case .recorded:   return "success_recorded"
        case .cheated:    return "error_cheated"
        default:          return "background"
        }
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
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.55),
                        value: n
                    )

                Text("탭하지 마세요!")
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
            }

        case .waiting:
            VStack(spacing: DesignSpacing.md) {
                Text("준비...")
                    .font(.ssTitle2)
                    .foregroundStyle(.white)
                    .opacity(pulseOpacity)

                Text("초록색이 되면 바로 탭!")
                    .font(.ssBody)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .onAppear {
                pulseOpacity = 1.0
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseOpacity = 0.92
                }
            }

        case .green:
            Text("TAP!")
                .font(.ssLargeTitle)
                .foregroundStyle(.white)
                .scaleEffect(goScale)
                .onAppear {
                    goScale = 1.0
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        goScale = 1.15
                    }
                }

        case .recorded(let ms):
            VStack(spacing: DesignSpacing.sm) {
                Text("\(ms) ms")
                    .font(.ssLargeTitle)
                    .foregroundStyle(.white)
                    .transition(
                        .scale(scale: 0.6)
                        .combined(with: .opacity)
                    )

                Text("기록됨!")
                    .font(.ssTitle2)
                    .foregroundStyle(.white.opacity(0.9))
                    .transition(.opacity)
            }

        case .cheated(let message):
            VStack(spacing: DesignSpacing.lg) {
                Text("❌ 실격")
                    .font(.ssTitle1)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.ssTitle2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSpacing.lg)

                RoundedActionButton("다시 하기") {
                    viewModel.retryCurrentRound()
                }
                .padding(.horizontal, DesignSpacing.lg)
            }
            .onAppear {
                withAnimation(.linear(duration: 0.4)) {
                    shakeTrigger += 1
                }
            }

        case .completed:
            Text("완료!")
                .font(.ssTitle1)
                .foregroundStyle(palette.textPrimary)
                .onAppear {
                    let session = viewModel.buildSession()
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        withAnimation(.smooth(duration: 0.35)) {
                            phase = .result(session: session)
                        }
                    }
                }
        }
    }

    // MARK: - State Change Handling (Haptics)

    private func handleStateChange(_ newState: TestState) {
        switch newState {
        case .countdown:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Reset animation states for next round
            goScale = 1.0
            pulseOpacity = 1.0

        case .green:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            goScale = 1.0

        case .recorded:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

        case .cheated:
            UINotificationFeedbackGenerator().notificationOccurred(.error)

        default:
            break
        }
    }
}

// MARK: - ShakeModifier

private struct ShakeModifier: ViewModifier {
    let trigger: CGFloat

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: trigger))
    }
}
