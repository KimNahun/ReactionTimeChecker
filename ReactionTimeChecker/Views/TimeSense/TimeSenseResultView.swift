// Views/TimeSense/TimeSenseResultView.swift
import SwiftUI
import TopDesignSystem

struct TimeSenseResultView: View {
    let session: TimeSenseSession
    let onPlayAgain: () -> Void

    @State private var viewModel: TimeSenseResultViewModel
    @Environment(\.designPalette) var palette

    init(session: TimeSenseSession, onPlayAgain: @escaping () -> Void) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self._viewModel = State(initialValue: TimeSenseResultViewModel(session: session))
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            mainResultView
        }
        .onAppear { viewModel.startReveal() }
        .onDisappear { viewModel.cancelReveal() }
        .onChange(of: viewModel.stage) { _, newStage in
            if newStage == .emoji { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        }
    }

    private var mainResultView: some View {
        ScrollView {
            VStack(spacing: DesignSpacing.lg) {
                Text(String(localized: "Results"))
                    .font(.ssTitle1)
                    .foregroundStyle(palette.textPrimary)
                    .padding(.top, DesignSpacing.xl)

                if viewModel.stage >= .averageError, let attempt = session.attempts.first {
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            Text(String(localized: "Your Tap"))
                                .font(.ssFootnote)
                                .foregroundStyle(palette.textSecondary)
                            Text(formatTimeMs(attempt.actualTimeMs))
                                .font(.ssLargeTitle)
                                .foregroundStyle(palette.textPrimary)

                            let sign = attempt.actualTimeMs >= 10000 ? "+" : "-"
                            Text("10.00s \(sign) \(formatErrorMs(attempt.errorMs))")
                                .font(.ssTitle2)
                                .foregroundStyle(attempt.errorMs < 300 ? palette.success : palette.error)

                            Text(session.timerVisible
                                 ? String(localized: "Timer visible mode")
                                 : String(localized: "Timer hidden mode"))
                                .font(.ssCaption)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .padding(DesignSpacing.lg)
                    }
                    .padding(.horizontal, DesignSpacing.md)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if viewModel.stage >= .emoji {
                    GradeCardView(
                        grade: viewModel.grade,
                        showEmoji: viewModel.stage >= .emoji,
                        showName: viewModel.stage >= .gradeName,
                        showDescription: viewModel.stage >= .gradeDesc
                    )
                    .padding(.horizontal, DesignSpacing.md)
                    .transition(.opacity)
                }

                if viewModel.stage >= .shareButton {
                    PillButton(String(localized: "Play Again")) {
                        onPlayAgain()
                    }
                    .padding(.horizontal, DesignSpacing.lg)
                    .transition(.opacity)
                }

                Spacer().frame(height: DesignSpacing.xl)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.stage)
        }
    }

    private func formatErrorMs(_ ms: Int) -> String {
        let s = ms / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d.%02ds", s, cs)
    }

    private func formatTimeMs(_ ms: Int) -> String {
        let s = ms / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d.%02ds", s, cs)
    }
}
