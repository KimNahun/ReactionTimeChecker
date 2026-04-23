// Views/Stroop/StroopResultView.swift
import SwiftUI
import UIKit
import TopDesignSystem

struct StroopResultView: View {
    let session: StroopSession
    let onPlayAgain: () -> Void
    var onHome: (() -> Void)? = nil

    @State private var viewModel: StroopResultViewModel
    @Environment(\.designPalette) var palette

    init(session: StroopSession, onPlayAgain: @escaping () -> Void, onHome: (() -> Void)? = nil) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self.onHome = onHome
        self._viewModel = State(initialValue: StroopResultViewModel(session: session))
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            if session.correctTaps.isEmpty {
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

    // MARK: - Empty Result

    private var emptyResultView: some View {
        VStack(spacing: DesignSpacing.lg) {
            Text(String(localized: "No correct taps 🤔"))
                .font(.ssTitle2)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "Tap only when the text color matches the target!"))
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)

            PillButton(String(localized: "Retry")) {
                onPlayAgain()
            }
            .padding(.horizontal, DesignSpacing.lg)
        }
        .padding(DesignSpacing.lg)
    }

    // MARK: - Main Result

    private var mainResultView: some View {
        ScrollView {
            VStack(spacing: DesignSpacing.lg) {
                Text(String(localized: "Results"))
                    .font(.ssTitle1)
                    .foregroundStyle(palette.textPrimary)
                    .padding(.top, DesignSpacing.xl)

                // Average ms card
                if viewModel.stage >= .averageMs {
                    averageMsCard
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                // Accuracy
                if viewModel.stage >= .accuracy {
                    accuracyView
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

                // Breakdown
                if viewModel.stage >= .breakdown {
                    breakdownCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                Text(String(localized: "Average Reaction Time"))
                    .font(.ssFootnote)
                    .foregroundStyle(palette.textSecondary)

                Text("\(session.averageMs) ms")
                    .font(.ssLargeTitle)
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText(value: Double(session.averageMs)))

                HStack(spacing: DesignSpacing.lg) {
                    VStack(spacing: 4) {
                        Text(String(localized: "Best"))
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(session.bestMs) ms")
                            .font(.ssBody)
                            .foregroundStyle(palette.success)
                    }

                    Divider().frame(height: 32)

                    VStack(spacing: 4) {
                        Text(String(localized: "Worst"))
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

    // MARK: - Accuracy View

    private var accuracyView: some View {
        VStack(spacing: DesignSpacing.xs) {
            Text(String(localized: "Accuracy"))
                .font(.ssBody)
                .foregroundStyle(palette.textSecondary)

            Text("\(session.accuracy)%")
                .font(.ssTitle1)
                .foregroundStyle(session.accuracy >= 80 ? palette.success : palette.error)
                .contentTransition(.numericText(value: Double(session.accuracy)))
        }
    }

    // MARK: - Breakdown Card

    private var breakdownCard: some View {
        SurfaceCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Text(String(localized: "Breakdown"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                let targetCount = session.attempts.filter { $0.wasTarget }.count
                let nonTargetCount = session.totalStimuli - targetCount

                VStack(spacing: DesignSpacing.sm) {
                    breakdownRow(
                        label: String(localized: "Correct Taps"),
                        value: "\(session.correctTaps.count) / \(targetCount)",
                        color: palette.success
                    )
                    breakdownRow(
                        label: String(localized: "Missed Targets"),
                        value: "\(session.missCount)",
                        color: Color.orange
                    )
                    breakdownRow(
                        label: String(localized: "False Taps"),
                        value: "\(session.falseAlarmCount) / \(nonTargetCount)",
                        color: palette.error
                    )
                }
            }
            .padding(DesignSpacing.lg)
        }
        .padding(.horizontal, DesignSpacing.md)
    }

    private func breakdownRow(label: String, value: String, color: some ShapeStyle) -> some View {
        HStack {
            Text(label)
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
            Spacer()
            Text(value)
                .font(.ssBody)
                .foregroundStyle(color)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSpacing.sm) {
            VStack(spacing: DesignSpacing.sm) {
                Text(String(localized: "Share"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                HStack(spacing: 24) {
                    // Kakao Share
                    Button {
                        KakaoShareService.shareStroop(
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

            PillButton(String(localized: "Play Again")) {
                onPlayAgain()
            }
            .padding(.horizontal, DesignSpacing.lg)

            if let onHome {
                Button {
                    onHome()
                } label: {
                    Text(String(localized: "Browse Other Games"))
                        .font(.ssBody)
                        .foregroundStyle(palette.primaryAction)
                }
                .padding(.top, DesignSpacing.xs)
            }
        }
    }

    // MARK: - Share Result Image

    private func shareResultImage() {
        let cardView = StroopShareCardView(
            averageMs: session.averageMs,
            bestMs: session.bestMs,
            worstMs: session.worstMs,
            accuracy: session.accuracy,
            percentile: viewModel.percentile,
            grade: viewModel.grade
        )

        guard let image = cardView.renderImage() else { return }

        let isKorean = Locale.current.language.languageCode?.identifier == "ko"
        let name = UserNameService.name
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 스트룹 테스트: \(session.averageMs)ms · 정확도 \(session.accuracy)% · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Stroop: \(session.averageMs)ms · Accuracy \(session.accuracy)% · Top \(viewModel.percentile)% — QuickTap"

        let activityVC = UIActivityViewController(
            activityItems: [text, image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(activityVC, animated: true)
    }

    // MARK: - Haptics

    private func handleStageChange(_ stage: StroopResultViewModel.RevealStage) {
        switch stage {
        case .accuracy:
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
