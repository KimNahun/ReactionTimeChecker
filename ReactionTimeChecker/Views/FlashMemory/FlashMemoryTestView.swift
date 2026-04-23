// Views/FlashMemory/FlashMemoryTestView.swift
import SwiftUI
import TopDesignSystem

struct FlashMemoryTestView: View {
    let onComplete: (FlashMemorySession) -> Void
    let onCancel: () -> Void
    @State private var viewModel = FlashMemoryViewModel()
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // HUD
                HStack {
                    Button { viewModel.cancelAll(); onCancel() } label: {
                        Image(systemName: "chevron.left").font(.ssBody).foregroundStyle(palette.primaryAction)
                    }
                    Spacer()
                    Text(String(format: String(localized: "Round %lld"), viewModel.currentRound))
                        .font(.ssFootnote).foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, DesignSpacing.md)
                .padding(.vertical, DesignSpacing.sm)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal, DesignSpacing.md)
                .padding(.top, DesignSpacing.sm)

                Spacer()
                stateContent
                Spacer()
            }
        }
        .onChange(of: viewModel.state) { _, newState in handleStateChange(newState) }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .countdown(let n):
            CountdownView(seconds: n)
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
        case .showing:
            VStack(spacing: DesignSpacing.lg) {
                Text(String(format: "%.1fs", viewModel.displayDuration))
                    .font(.ssCaption).foregroundStyle(palette.textSecondary)
                HStack(spacing: DesignSpacing.md) {
                    ForEach(viewModel.targetNumbers, id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(palette.primaryAction)
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(palette.surface))
                    }
                }
                Text(String(localized: "Remember these!"))
                    .font(.ssBody).foregroundStyle(palette.textSecondary)
            }
        case .picking:
            VStack(spacing: DesignSpacing.lg) {
                // Timer bar
                HStack(spacing: 4) {
                    Image(systemName: "timer").font(.ssCaption).foregroundStyle(palette.textSecondary)
                    Text(String(format: "%.1f", viewModel.pickTimeRemaining))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(viewModel.pickTimeRemaining < 2 ? palette.error : palette.textPrimary)
                }
                Text(String(localized: "Pick the 3 numbers"))
                    .font(.ssTitle2).foregroundStyle(palette.textPrimary)
                HStack(spacing: DesignSpacing.sm) {
                    ForEach(viewModel.choiceNumbers, id: \.self) { num in
                        let isSelected = viewModel.selectedNumbers.contains(num)
                        Button { viewModel.selectNumber(num) } label: {
                            Text("\(num)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(isSelected ? .white : palette.textPrimary)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(isSelected ? palette.primaryAction : palette.surface))
                                .overlay(Circle().stroke(palette.textSecondary.opacity(0.3), lineWidth: 2))
                        }
                    }
                }
            }
        case .correct(let round):
            VStack(spacing: DesignSpacing.sm) {
                Text("✓").font(.system(size: 56)).foregroundStyle(palette.success)
                Text(String(format: String(localized: "Round %lld cleared!"), round))
                    .font(.ssTitle2).foregroundStyle(palette.textPrimary)
            }
        case .wrong:
            VStack(spacing: DesignSpacing.sm) {
                Text("✗").font(.system(size: 56)).foregroundStyle(palette.error)
                Text(String(localized: "Wrong!")).font(.ssTitle1).foregroundStyle(palette.error)
                Text(String(localized: "The correct numbers were:")).font(.ssBody).foregroundStyle(palette.textSecondary)
                HStack(spacing: DesignSpacing.sm) {
                    ForEach(viewModel.targetNumbers, id: \.self) { num in
                        Text("\(num)").font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryAction)
                    }
                }
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

    private func handleStateChange(_ state: FlashMemoryState) {
        switch state {
        case .countdown: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .correct: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .wrong, .timeout: UINotificationFeedbackGenerator().notificationOccurred(.error)
        default: break
        }
    }
}
