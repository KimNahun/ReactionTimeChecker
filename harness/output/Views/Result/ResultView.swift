// Views/Result/ResultView.swift
import SwiftUI
import TopDesignSystem

struct ResultView: View {
    let session: TestSession
    @Binding var phase: AppPhase
    @State private var viewModel: ResultViewModel
    @Environment(\.designPalette) var palette

    init(session: TestSession, phase: Binding<AppPhase>) {
        self.session = session
        self._phase = phase
        self._viewModel = State(initialValue: ResultViewModel(session: session))
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            if session.validAttempts.isEmpty {
                emptyResultView
            } else {
                mainResultView
            }
        }
        .onAppear {
            viewModel.startReveal()
        }
        .onChange(of: viewModel.stage) { _, newStage in
            handleStageChange(newStage)
        }
    }

    // MARK: - Empty Result (All cheated)

    private var emptyResultView: some View {
        VStack(spacing: DesignSpacing.lg) {
            Text("측정 결과가 없습니다 🤔")
                .font(.ssTitle2)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            Text("빨간불에서는 탭하지 마세요!")
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)

            PillButton(title: "재도전") {
                withAnimation(.smooth(duration: 0.35)) {
                    phase = .home
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
        }
        .padding(DesignSpacing.lg)
    }

    // MARK: - Main Result

    private var mainResultView: some View {
        ScrollView {
            VStack(spacing: DesignSpacing.lg) {
                // Title — always visible
                Text("결과 발표")
                    .font(.ssTitle1)
                    .foregroundStyle(palette.textPrimary)
                    .padding(.top, DesignSpacing.xl)

                // Average ms card
                if viewModel.stage >= .averageMs {
                    averageMsCard
                        .transition(
                            .scale(scale: 0.7)
                            .combined(with: .opacity)
                        )
                }

                // Percentile
                if viewModel.stage >= .percentile {
                    percentileView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Grade card
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

                // Comparison chart
                if viewModel.stage >= .comparison {
                    comparisonCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Cheated stat
                if viewModel.stage >= .cheatedStat {
                    Text(viewModel.cheatedStatMessage())
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSpacing.lg)
                        .transition(.opacity)
                }

                // Action buttons
                if viewModel.stage >= .shareButton {
                    actionButtons
                        .transition(.opacity)
                }

                Spacer().frame(height: DesignSpacing.xl)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.stage)
        }
    }

    // MARK: - Average ms Card

    private var averageMsCard: some View {
        SurfaceCard(elevation: .raised) {
            VStack(spacing: DesignSpacing.sm) {
                Text("평균 반응속도")
                    .font(.ssFootnote)
                    .foregroundStyle(palette.textSecondary)

                Text("\(session.averageMs) ms")
                    .font(.ssLargeTitle)
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText(value: Double(session.averageMs)))

                HStack(spacing: DesignSpacing.lg) {
                    VStack(spacing: 4) {
                        Text("최고")
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(session.bestMs) ms")
                            .font(.ssBody)
                            .foregroundStyle(palette.success)
                    }

                    Divider()
                        .frame(height: 32)

                    VStack(spacing: 4) {
                        Text("최악")
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(session.worstMs) ms")
                            .font(.ssBody)
                            .foregroundStyle(palette.error)
                    }
                }
            }
            .padding(DesignSpacing.lg)
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    // MARK: - Percentile View

    private var percentileView: some View {
        VStack(spacing: DesignSpacing.xs) {
            Text("상위")
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)

            Text("\(viewModel.percentile)%")
                .font(.ssTitle1)
                .foregroundStyle(palette.accent)
                .contentTransition(.numericText(value: Double(viewModel.percentile)))
        }
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        SurfaceCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Text("다른 사람들과 비교")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                let comparisons: [(String, Int, Bool)] = [
                    ("나", session.averageMs, true),
                    ("운동선수", 180, false),
                    ("게이머", 200, false),
                    ("일반인", 250, false),
                ]

                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                        ForEach(comparisons, id: \.0) { label, ms, isMe in
                            ComparisonBarRow(
                                label: label,
                                ms: ms,
                                isMe: isMe,
                                maxWidth: geo.size.width,
                                isShown: viewModel.stage >= .comparison
                            )
                        }
                    }
                }
                .frame(height: 160)
            }
            .padding(DesignSpacing.lg)
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSpacing.sm) {
            OutlineButton(title: "결과 공유하기", action: { })
                .padding(.horizontal, DesignSpacing.lg)

            Text("공유 기능은 곧 추가됩니다")
                .font(.ssCaption)
                .foregroundStyle(palette.textSecondary)

            PillButton(title: "다시 도전하기") {
                withAnimation(.smooth(duration: 0.35)) {
                    phase = .home
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
        }
    }

    // MARK: - Stage Change Haptics

    private func handleStageChange(_ stage: ResultViewModel.RevealStage) {
        switch stage {
        case .percentile:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .emoji:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .shareButton:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default:
            break
        }
    }
}

// MARK: - ComparisonBarRow

private struct ComparisonBarRow: View {
    let label: String
    let ms: Int
    let isMe: Bool
    let maxWidth: CGFloat
    let isShown: Bool
    @Environment(\.designPalette) var palette

    private var barWidth: CGFloat {
        let ratio = min(CGFloat(ms) / 400.0, 1.0)
        return ratio * (maxWidth - 80) // leave room for labels
    }

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            Text(label)
                .font(.ssFootnote)
                .foregroundStyle(palette.textPrimary)
                .frame(width: 50, alignment: .leading)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(palette.surface)
                    .frame(height: 24)

                RoundedRectangle(cornerRadius: 4)
                    .fill(isMe ? AnyShapeStyle(palette.accent) : AnyShapeStyle(palette.textSecondary.opacity(0.5)))
                    .frame(
                        width: isShown ? barWidth : 0,
                        height: 24
                    )
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(isMe ? 0 : 0.15),
                        value: isShown
                    )
            }

            Text("\(ms)ms")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

