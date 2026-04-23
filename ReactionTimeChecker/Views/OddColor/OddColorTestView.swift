// Views/OddColor/OddColorTestView.swift
import SwiftUI
import TopDesignSystem

struct OddColorTestView: View {
    let onComplete: (OddColorSession) -> Void
    let onCancel: () -> Void
    @State private var viewModel = OddColorViewModel()
    @State private var shakeTrigger: CGFloat = 0
    @State private var showRedFlash = false
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            if showRedFlash { Color.red.opacity(0.3).ignoresSafeArea().transition(.opacity) }

            VStack(spacing: 0) {
                HStack {
                    Button { viewModel.cancelAll(); onCancel() } label: {
                        Image(systemName: "chevron.left").font(.ssBody).foregroundStyle(palette.primaryAction)
                    }

                    // Target color indicator — large
                    HStack(spacing: 6) {
                        Text(String(localized: "Find:")).font(.ssBody).foregroundStyle(palette.textSecondary)
                        RoundedRectangle(cornerRadius: 6).fill(viewModel.targetColor).frame(width: 36, height: 36)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.5), lineWidth: 2))
                    }

                    Spacer()

                    // Timer
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
            tileGrid
        case .correct(_, let ms):
            VStack(spacing: DesignSpacing.sm) {
                Text("✓").font(.system(size: 56)).foregroundStyle(palette.success)
                Text("\(ms)ms").font(.ssTitle1).foregroundStyle(palette.textPrimary)
            }
        case .wrong:
            VStack(spacing: DesignSpacing.sm) {
                Text("✗").font(.system(size: 56)).foregroundStyle(palette.error)
                Text(String(localized: "Wrong tile!")).font(.ssTitle1).foregroundStyle(palette.error)
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

    private var tileGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(viewModel.tiles) { tile in
                Button { viewModel.handleTap(tile: tile) } label: {
                    fourColorTile(colors: tile.colors)
                        .frame(height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    private func fourColorTile(colors: [Color]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                colors[0].frame(maxWidth: .infinity, maxHeight: .infinity)
                colors[1].frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack(spacing: 0) {
                colors[2].frame(maxWidth: .infinity, maxHeight: .infinity)
                colors[3].frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func handleStateChange(_ s: OddColorState) {
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
