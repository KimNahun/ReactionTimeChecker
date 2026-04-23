// Views/TimeSense/TimeSenseTestView.swift
import SwiftUI
import TopDesignSystem

struct TimeSenseTestView: View {
    let timerVisible: Bool
    let onComplete: (TimeSenseSession) -> Void
    let onCancel: () -> Void

    @State private var viewModel = TimeSenseViewModel()
    @Environment(\.designPalette) var palette
    @State private var touchProcessed = false

    var body: some View {
        ZStack {
            backgroundColorView
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.12), value: backgroundKey)

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        viewModel.cancelAll()
                        onCancel()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.ssBody)
                            Text(String(localized: "Back")).font(.ssBody)
                        }
                        .foregroundStyle(palette.primaryAction)
                    }
                    .padding(.horizontal, DesignSpacing.md)
                    .padding(.top, DesignSpacing.sm)
                    Spacer()
                }

                Spacer()
                stateContent
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !touchProcessed else { return }
                    touchProcessed = true
                    if case .running = viewModel.state {
                        viewModel.handleTap()
                    }
                }
                .onEnded { _ in touchProcessed = false }
        )
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear { viewModel.startTest(timerVisible: timerVisible) }
        .onDisappear { viewModel.cancelAll() }
    }

    @ViewBuilder
    private var backgroundColorView: some View {
        switch viewModel.state {
        case .roundResult(_, _, let errorMs):
            if errorMs < 200 { palette.success }
            else if errorMs < 500 { Color.orange.opacity(0.7) }
            else { palette.error }
        case .running:
            palette.surface
        default:
            palette.background
        }
    }

    private var backgroundKey: String {
        switch viewModel.state {
        case .running: return "running"
        case .roundResult: return "result"
        default: return "default"
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .modeSelect:
            EmptyView()

        case .countdown(let n):
            VStack(spacing: DesignSpacing.lg) {
                CountdownView(seconds: n)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
                Text(String(localized: "Tap at exactly 10.00s!"))
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
            }

        case .running:
            VStack(spacing: DesignSpacing.lg) {
                if viewModel.showTimer {
                    Text(formatTime(viewModel.displayTime))
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(palette.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("???")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(palette.textSecondary)
                }

                Text(String(localized: "TAP at 10.00s"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textSecondary)
            }

        case .roundResult(_, let actualMs, let errorMs):
            VStack(spacing: DesignSpacing.md) {
                Text(formatTimeMs(actualMs))
                    .font(.system(size: 56, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                let sign = actualMs >= 10000 ? "+" : "-"
                Text("10.00s \(sign) \(formatTimeMs(errorMs))")
                    .font(.ssTitle2)
                    .foregroundStyle(.white.opacity(0.8))

                Text(errorMs < 100 ? "Amazing!" : errorMs < 300 ? "Close!" : errorMs < 700 ? "Not bad" : "Way off...")
                    .font(.ssBody)
                    .foregroundStyle(.white.opacity(0.7))
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

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds) % 60
        let cs = Int((seconds - Double(Int(seconds))) * 100)
        return String(format: "%d.%02d", s, cs)
    }

    private func formatTimeMs(_ ms: Int) -> String {
        let s = ms / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d.%02ds", s, cs)
    }

    private func handleStateChange(_ newState: TimeSenseState) {
        switch newState {
        case .countdown:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .roundResult(_, _, let errorMs):
            if errorMs < 200 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        default: break
        }
    }
}
