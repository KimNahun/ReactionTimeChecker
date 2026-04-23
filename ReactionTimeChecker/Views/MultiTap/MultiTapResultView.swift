// Views/MultiTap/MultiTapResultView.swift
import SwiftUI
import TopDesignSystem

struct MultiTapResultView: View {
    let session: MultiTapSession
    let onPlayAgain: () -> Void

    @State private var viewModel: MultiTapResultViewModel
    @Environment(\.designPalette) var palette

    init(session: MultiTapSession, onPlayAgain: @escaping () -> Void) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self._viewModel = State(initialValue: MultiTapResultViewModel(session: session))
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

                if viewModel.stage >= .score {
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            Text(String(localized: "Circles Tapped"))
                                .font(.ssFootnote)
                                .foregroundStyle(palette.textSecondary)
                            Text("\(viewModel.totalCollected)")
                                .font(.ssLargeTitle)
                                .foregroundStyle(palette.textPrimary)
                            Text(String(format: String(localized: "out of %lld circles"), session.totalCirclesSpawned))
                                .font(.ssCaption)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .padding(DesignSpacing.lg)
                    }
                    .padding(.horizontal, DesignSpacing.md)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if viewModel.stage >= .breakdown {
                    SurfaceCard(elevation: .raised) {
                        VStack(spacing: DesignSpacing.sm) {
                            breakdownRow(String(localized: "Manual taps"), "\(session.circlesTapped)", palette.success)
                            breakdownRow(String(localized: "Auto-collected"), "\(session.circlesAutoCollected)", palette.primaryAction)
                            breakdownRow(String(localized: "Wrong taps"), "\(session.wrongTaps)", palette.error)
                            breakdownRow(String(localized: "Missed"), "\(session.missedCircles)", palette.textSecondary)
                        }
                        .padding(DesignSpacing.lg)
                    }
                    .padding(.horizontal, DesignSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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

    private func breakdownRow(_ label: String, _ value: String, _ color: some ShapeStyle) -> some View {
        HStack {
            Text(label).font(.ssFootnote).foregroundStyle(palette.textSecondary)
            Spacer()
            Text(value).font(.ssBody).foregroundStyle(color)
        }
    }
}
