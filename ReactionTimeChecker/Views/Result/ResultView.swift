// Views/Result/ResultView.swift
import SwiftUI
import UIKit
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
        .onDisappear {
            viewModel.cancelReveal()
        }
        .onChange(of: viewModel.stage) { _, newStage in
            handleStageChange(newStage)
        }
    }

    // MARK: - Empty Result (All cheated)

    private var emptyResultView: some View {
        VStack(spacing: DesignSpacing.lg) {
            Text("No results 🤔")
                .font(.ssTitle2)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            Text("Don't tap on the red screen!")
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)

            PillButton(String(localized: "Retry")) {
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
                Text(String(localized: "'Reaction' Results"))
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
                Text("Average Reaction Time")
                    .font(.ssFootnote)
                    .foregroundStyle(palette.textSecondary)

                Text("\(session.averageMs) ms")
                    .font(.ssLargeTitle)
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText(value: Double(session.averageMs)))

                HStack(spacing: DesignSpacing.lg) {
                    VStack(spacing: 4) {
                        Text("Best")
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(session.bestMs) ms")
                            .font(.ssBody)
                            .foregroundStyle(palette.success)
                    }

                    Divider()
                        .frame(height: 32)

                    VStack(spacing: 4) {
                        Text("Worst")
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
            Text("Top")
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)

            Text("\(viewModel.percentile)%")
                .font(.ssTitle1)
                .foregroundStyle(palette.primaryAction)
                .contentTransition(.numericText(value: Double(viewModel.percentile)))
        }
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        SurfaceCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Text("Compare with Others")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                let comparisons: [(String, Int, Bool)] = [
                    (String(localized: "Me"), session.averageMs, true),
                    (String(localized: "Athlete"), 180, false),
                    (String(localized: "Gamer"), 200, false),
                    (String(localized: "Average"), 250, false),
                ]

                VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                    ForEach(comparisons, id: \.0) { label, ms, isMe in
                        ComparisonBarRow(
                            label: label,
                            ms: ms,
                            isMe: isMe,
                            isShown: viewModel.stage >= .comparison
                        )
                    }
                }
            }
            .padding(DesignSpacing.lg)
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSpacing.sm) {
            // Share section
            VStack(spacing: DesignSpacing.sm) {
                Text(String(localized: "Share"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                HStack(spacing: 24) {
                    // Kakao Share
                    Button {
                        KakaoShareService.share(
                            session: session,
                            grade: viewModel.grade,
                            percentile: viewModel.percentile
                        )
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.996, green: 0.898, blue: 0.0))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.black.opacity(0.85))
                            }
                            Text("KakaoTalk")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(palette.textSecondary)
                        }
                    }

                    // General share (image + text)
                    Button {
                        shareResultImage()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(palette.surface)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Circle().stroke(palette.textSecondary.opacity(0.2), lineWidth: 1)
                                    )
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .foregroundStyle(palette.primaryAction)
                            }
                            Text(String(localized: "Other"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                }
            }
            .padding(.vertical, DesignSpacing.sm)

            // Play Again
            PillButton(String(localized: "Play Again")) {
                withAnimation(.smooth(duration: 0.35)) {
                    phase = .home
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
        }
    }

    // MARK: - Share Result Image

    private func shareResultImage() {
        let cardView = ShareCardView(
            averageMs: session.averageMs,
            bestMs: session.bestMs,
            worstMs: session.worstMs,
            percentile: viewModel.percentile,
            grade: viewModel.grade
        )

        guard let image = cardView.renderImage() else { return }

        let isKorean = Locale.current.language.languageCode?.identifier == "ko"
        let name = UserNameService.name
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 반응속도: \(session.averageMs)ms · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Reaction: \(session.averageMs)ms · Top \(viewModel.percentile)% — QuickTap"

        let activityVC = UIActivityViewController(
            activityItems: [text, image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        // Find the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(activityVC, animated: true)
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
    let isShown: Bool
    @Environment(\.designPalette) var palette

    private var ratio: CGFloat {
        min(CGFloat(ms) / 400.0, 1.0)
    }

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            Text(label)
                .font(.ssFootnote)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(palette.surface)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(isMe ? AnyShapeStyle(palette.primaryAction) : AnyShapeStyle(palette.textSecondary.opacity(0.5)))
                        .frame(width: isShown ? ratio * geo.size.width : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(isMe ? 0 : 0.15),
                            value: isShown
                        )
                }
            }
            .frame(height: 24)

            Text("\(ms)ms")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 56, alignment: .trailing)
        }
    }
}

