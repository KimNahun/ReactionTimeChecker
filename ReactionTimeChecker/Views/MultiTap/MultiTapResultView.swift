// Views/MultiTap/MultiTapResultView.swift
import SwiftUI
import UIKit
import TopDesignSystem

struct MultiTapResultView: View {
    let session: MultiTapSession
    let onPlayAgain: () -> Void
    var onHome: (() -> Void)? = nil

    @State private var viewModel: MultiTapResultViewModel
    @Environment(\.designPalette) var palette

    init(session: MultiTapSession, onPlayAgain: @escaping () -> Void, onHome: (() -> Void)? = nil) {
        self.session = session
        self.onPlayAgain = onPlayAgain
        self.onHome = onHome
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
                    VStack(spacing: DesignSpacing.xs) {
                        Text(String(localized: "Top"))
                            .font(.ssBody)
                            .foregroundStyle(palette.textSecondary)
                        Text("\(viewModel.percentile)%")
                            .font(.ssTitle1)
                            .foregroundStyle(palette.primaryAction)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

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
                        KakaoShareService.shareMultiTap(
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
        let total = viewModel.totalCollected
        let name = UserNameService.name
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 멀티 탭: \(total)개 · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Multi-Tap: \(total) tapped · Top \(viewModel.percentile)% — QuickTap"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(activityVC, animated: true)
    }

    private func breakdownRow(_ label: String, _ value: String, _ color: some ShapeStyle) -> some View {
        HStack {
            Text(label).font(.ssFootnote).foregroundStyle(palette.textSecondary)
            Spacer()
            Text(value).font(.ssBody).foregroundStyle(color)
        }
    }
}
