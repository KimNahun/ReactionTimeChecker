// Views/TimeSense/TimeSenseResultView.swift
import SwiftUI
import TopDesignSystem

struct TimeSenseResultView: View {
    let session: TimeSenseSession
    let onPlayAgain: () -> Void
    var onHome: (() -> Void)? = nil

    @State private var viewModel: TimeSenseResultViewModel
    @Environment(\.designPalette) var palette

    init(session: TimeSenseSession, onPlayAgain: @escaping () -> Void, onHome: (() -> Void)? = nil) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self.onHome = onHome
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
                Text(String(localized: "'Time Sense' Results"))
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

                if viewModel.stage >= .averageError {
                    VStack(spacing: DesignSpacing.xs) {
                        Text(String(localized: "Top"))
                            .font(.ssBody)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(viewModel.percentile)%")
                            .font(.ssTitle1)
                            .foregroundStyle(palette.primaryAction)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                        KakaoShareService.shareTimeSense(
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
        let errorSec = formatErrorMs(session.averageErrorMs)
        let name = UserNameService.name
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 시간 감각: 오차 \(errorSec) · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Time Sense: Error \(errorSec) · Top \(viewModel.percentile)% — QuickTap"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(activityVC, animated: true)
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
