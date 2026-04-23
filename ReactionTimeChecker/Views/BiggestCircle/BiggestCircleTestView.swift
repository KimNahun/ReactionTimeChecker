// Views/BiggestCircle/BiggestCircleTestView.swift
import SwiftUI
import TopDesignSystem

struct BiggestCircleTestView: View {
    let onComplete: (BiggestCircleSession) -> Void
    let onCancel: () -> Void
    @State private var viewModel = BiggestCircleViewModel()
    @State private var shakeTrigger: CGFloat = 0
    @State private var showRedFlash = false
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            if showRedFlash { Color.red.opacity(0.3).ignoresSafeArea().transition(.opacity) }

            VStack(spacing: 0) {
                // HUD
                HStack {
                    Button { viewModel.cancelAll(); onCancel() } label: {
                        Image(systemName: "chevron.left").font(.ssBody).foregroundStyle(palette.primaryAction)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "timer").font(.ssCaption).foregroundStyle(palette.textSecondary)
                        Text(String(format: "%.1f", viewModel.timeRemaining))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(viewModel.timeRemaining < 3 ? palette.error : palette.textPrimary)
                    }
                    Text(String(format: String(localized: "R%lld"), viewModel.currentRound))
                        .font(.ssFootnote).foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, DesignSpacing.md).padding(.vertical, DesignSpacing.sm)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal, DesignSpacing.md).padding(.top, DesignSpacing.sm)

                Spacer()
                stateContent
                Spacer()
            }
        }
        .modifier(ShakeEffect(animatableData: shakeTrigger))
        .animation(.easeInOut(duration: 0.1), value: showRedFlash)
        .onChange(of: viewModel.state) { _, s in handleStateChange(s) }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .countdown(let n):
            CountdownView(seconds: n).animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
        case .showing:
            bubblesView
        case .correct(_, let ms):
            VStack(spacing: DesignSpacing.sm) {
                Text("✓").font(.system(size: 56)).foregroundStyle(palette.success)
                Text("\(ms)ms").font(.ssTitle1).foregroundStyle(palette.textPrimary)
            }
        case .wrong:
            VStack(spacing: DesignSpacing.sm) {
                Text("✗").font(.system(size: 56)).foregroundStyle(palette.error)
                Text(String(localized: "Not the biggest!")).font(.ssTitle1).foregroundStyle(palette.error)
            }
        case .timeout:
            VStack(spacing: DesignSpacing.sm) {
                Text("⏰").font(.system(size: 56))
                Text(String(localized: "Time's up!")).font(.ssTitle1).foregroundStyle(palette.error)
            }
        case .completed:
            Text(String(localized: "Done!")).font(.ssTitle1).foregroundStyle(palette.textPrimary)
                .onAppear {
                    let session = viewModel.buildSession()
                    Task { try? await Task.sleep(nanoseconds: 300_000_000); onComplete(session) }
                }
        }
    }

    private var bubblesView: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(viewModel.bubbles) { bubble in
                    Circle()
                        .fill(palette.primaryAction)
                        .frame(width: bubble.radius * 2, height: bubble.radius * 2)
                        .position(
                            x: bubble.x * geo.size.width,
                            y: bubble.y * geo.size.height
                        )
                        .onTapGesture {
                            viewModel.handleTap(bubble: bubble)
                        }
                }
            }
        }
    }

    private func handleStateChange(_ s: BiggestCircleState) {
        switch s {
        case .countdown: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .correct: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .wrong, .timeout:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showRedFlash = true
            withAnimation(.linear(duration: 0.3)) { shakeTrigger += 1 }
            Task { try? await Task.sleep(nanoseconds: 200_000_000); showRedFlash = false }
        default: break
        }
    }
}
