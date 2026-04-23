// Views/Sequence/SequenceResultView.swift
import SwiftUI
import UIKit
import TopDesignSystem

struct SequenceResultView: View {
    let session: SequenceSession
    let onPlayAgain: () -> Void

    @State private var viewModel: SequenceResultViewModel
    @Environment(\.designPalette) var palette

    init(session: SequenceSession, onPlayAgain: @escaping () -> Void) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self._viewModel = State(initialValue: SequenceResultViewModel(session: session))
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

                if viewModel.stage >= .totalTime {
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            Text(String(localized: "Total Time"))
                                .font(.ssFootnote)
                                .foregroundStyle(palette.textSecondary)
                            Text(formatMs(session.totalTimeMs))
                                .font(.ssLargeTitle)
                                .foregroundStyle(palette.textPrimary)

                            if session.penaltyCount > 0 {
                                HStack(spacing: DesignSpacing.lg) {
                                    VStack(spacing: 4) {
                                        Text(String(localized: "Pure Time"))
                                            .font(.ssCaption)
                                            .foregroundStyle(palette.textSecondary)
                                        Text(formatMs(session.pureTimeMs))
                                            .font(.ssBody)
                                            .foregroundStyle(palette.success)
                                    }
                                    Divider().frame(height: 32)
                                    VStack(spacing: 4) {
                                        Text(String(localized: "Penalties"))
                                            .font(.ssCaption)
                                            .foregroundStyle(palette.textSecondary)
                                        Text("+\(formatMs(session.penaltyTimeMs))")
                                            .font(.ssBody)
                                            .foregroundStyle(palette.error)
                                    }
                                }
                            }
                        }
                        .padding(DesignSpacing.lg)
                    }
                    .padding(.horizontal, DesignSpacing.md)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if viewModel.stage >= .penalties {
                    Text(session.penaltyCount == 0
                         ? String(localized: "Perfect! No wrong taps 👏")
                         : String(format: String(localized: "Wrong taps: %lld"), session.penaltyCount))
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .transition(.opacity)
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

    private func formatMs(_ ms: Int) -> String {
        let s = ms / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d.%02ds", s, cs)
    }
}
