// Views/Sequence/SequenceResultView.swift
import SwiftUI
import UIKit
import TopDesignSystem

struct SequenceResultView: View {
    let session: SequenceSession
    let onPlayAgain: () -> Void
    var onHome: (() -> Void)? = nil

    @State private var viewModel: SequenceResultViewModel
    @Environment(\.designPalette) var palette

    init(session: SequenceSession, onPlayAgain: @escaping () -> Void, onHome: (() -> Void)? = nil) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self.onHome = onHome
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
                    VStack(spacing: DesignSpacing.xs) {
                        Text(session.penaltyCount == 0
                             ? String(localized: "Perfect! No wrong taps 👏")
                             : String(format: String(localized: "Wrong taps: %lld"), session.penaltyCount))
                            .font(.ssFootnote)
                            .foregroundStyle(palette.textSecondary)

                        VStack(spacing: DesignSpacing.xs) {
                            Text(String(localized: "Top"))
                                .font(.ssBody)
                                .foregroundStyle(palette.textSecondary)
                            Text("\(viewModel.percentile)%")
                                .font(.ssTitle1)
                                .foregroundStyle(palette.primaryAction)
                        }
                    }
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
                    shareButtons
                        .transition(.opacity)
                }

                Spacer().frame(height: DesignSpacing.xl)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.stage)
        }
    }

    private var shareButtons: some View {
        VStack(spacing: DesignSpacing.sm) {
            VStack(spacing: DesignSpacing.sm) {
                Text(String(localized: "Share"))
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                HStack(spacing: 24) {
                    Button {
                        KakaoShareService.shareSequence(
                            session: session, grade: viewModel.grade, percentile: viewModel.percentile)
                    } label: {
                        shareIcon(systemName: "bubble.left.fill",
                                  bgColor: Color(red: 0.996, green: 0.898, blue: 0.0),
                                  fgColor: .black.opacity(0.85), label: "KakaoTalk")
                    }

                    Button { shareResultText() } label: {
                        shareIcon(systemName: "square.and.arrow.up",
                                  bgColor: palette.surface, fgColor: palette.primaryAction,
                                  label: String(localized: "Other"), bordered: true)
                    }
                }
            }
            .padding(.vertical, DesignSpacing.sm)

            PillButton(String(localized: "Play Again")) { onPlayAgain() }
                .padding(.horizontal, DesignSpacing.lg)

            if let onHome {
                Button { onHome() } label: {
                    Text(String(localized: "Browse Other Games"))
                        .font(.ssBody)
                        .foregroundStyle(palette.primaryAction)
                }
                .padding(.top, DesignSpacing.xs)
            }
        }
    }

    private func shareIcon(systemName: String, bgColor: some ShapeStyle, fgColor: some ShapeStyle, label: String, bordered: Bool = false) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(bgColor).frame(width: 56, height: 56)
                    .overlay { if bordered { Circle().stroke(palette.textSecondary.opacity(0.2), lineWidth: 1) } }
                Image(systemName: systemName).font(.system(size: 22)).foregroundStyle(fgColor)
            }
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(palette.textSecondary)
        }
    }

    private func shareResultText() {
        let isKorean = Locale.current.language.languageCode?.identifier == "ko"
        let totalSec = formatMs(session.totalTimeMs)
        let name = UserNameService.name
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 순서 탭: \(totalSec) · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Sequence: \(totalSec) · Top \(viewModel.percentile)% — QuickTap"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(activityVC, animated: true)
    }

    private func formatMs(_ ms: Int) -> String {
        let s = ms / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d.%02ds", s, cs)
    }
}
