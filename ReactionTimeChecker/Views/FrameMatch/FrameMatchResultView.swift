// Views/FrameMatch/FrameMatchResultView.swift
import SwiftUI
import UIKit
import TopDesignSystem

struct FrameMatchResultView: View {
    let session: FrameMatchSession
    let onPlayAgain: () -> Void
    var onHome: (() -> Void)? = nil
    @State private var viewModel: FrameMatchResultViewModel
    @Environment(\.designPalette) var palette

    init(session: FrameMatchSession, onPlayAgain: @escaping () -> Void, onHome: (() -> Void)? = nil) {
        self.session = session; self.onPlayAgain = onPlayAgain; self.onHome = onHome
        self._viewModel = State(initialValue: FrameMatchResultViewModel(session: session))
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    Text(String(localized: "'Frame Match' Results")).font(.ssTitle1).foregroundStyle(palette.textPrimary).padding(.top, DesignSpacing.xl)

                    if viewModel.stage >= .score {
                        SurfaceCard(elevation: .raised) {
                            VStack(spacing: DesignSpacing.sm) {
                                Text(String(localized: "Average Error")).font(.ssFootnote).foregroundStyle(palette.textSecondary)
                                Text(String(format: "%.1fpt", session.averageError)).font(.ssLargeTitle).foregroundStyle(palette.textPrimary)
                                Text(String(format: String(localized: "Best: %.1fpt"), session.bestError))
                                    .font(.ssBody).foregroundStyle(palette.success)
                                VStack(spacing: DesignSpacing.xs) {
                                    Text(String(localized: "Top")).font(.ssBody).foregroundStyle(palette.textSecondary)
                                    Text("\(viewModel.percentile)%").font(.ssTitle1).foregroundStyle(palette.primaryAction)
                                }
                            }.padding(DesignSpacing.lg)
                        }.padding(.horizontal, DesignSpacing.md).transition(.scale(scale: 0.7).combined(with: .opacity))
                    }

                    if viewModel.stage >= .breakdown {
                        SurfaceCard(elevation: .raised) {
                            VStack(spacing: DesignSpacing.sm) {
                                ForEach(Array(session.errors.enumerated()), id: \.offset) { i, err in
                                    HStack {
                                        Text("#\(i + 1)").font(.ssFootnote).foregroundStyle(palette.textSecondary).frame(width: 30, alignment: .leading)
                                        Spacer()
                                        Text(String(format: "%.1fpt", err)).font(.ssBody)
                                            .foregroundStyle(err < 10 ? palette.success : err < 30 ? palette.primaryAction : palette.error)
                                    }
                                }
                            }.padding(DesignSpacing.lg)
                        }.padding(.horizontal, DesignSpacing.md).transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if viewModel.stage >= .emoji {
                        GradeCardView(grade: viewModel.grade, showEmoji: viewModel.stage >= .emoji, showName: viewModel.stage >= .gradeName, showDescription: viewModel.stage >= .gradeDesc)
                            .padding(.horizontal, DesignSpacing.md).transition(.opacity)
                    }

                    if viewModel.stage >= .shareButton { shareButtons.transition(.opacity) }
                    Spacer().frame(height: DesignSpacing.xl)
                }.animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.stage)
            }
        }
        .onAppear { viewModel.startReveal() }.onDisappear { viewModel.cancelReveal() }
        .onChange(of: viewModel.stage) { _, s in if s == .emoji { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() } }
    }

    private var shareButtons: some View {
        VStack(spacing: DesignSpacing.sm) {
            VStack(spacing: DesignSpacing.sm) {
                Text(String(localized: "Share")).font(.ssTitle2).foregroundStyle(palette.textPrimary)
                HStack(spacing: 24) {
                    Button { KakaoShareService.shareFrameMatch(session: session, grade: viewModel.grade, percentile: viewModel.percentile) } label: {
                        shareIcon(systemName: "bubble.left.fill", bgColor: Color(red: 0.996, green: 0.898, blue: 0.0), fgColor: .black.opacity(0.85), label: "KakaoTalk")
                    }
                    Button { shareText() } label: {
                        shareIcon(systemName: "square.and.arrow.up", bgColor: palette.surface, fgColor: palette.primaryAction, label: String(localized: "Other"), bordered: true)
                    }
                }
            }.padding(.vertical, DesignSpacing.sm)
            PillButton(String(localized: "Play Again")) { onPlayAgain() }.padding(.horizontal, DesignSpacing.lg)
            if let onHome { Button { onHome() } label: { Text(String(localized: "Browse Other Games")).font(.ssBody).foregroundStyle(palette.primaryAction) }.padding(.top, DesignSpacing.xs) }
        }
    }

    private func shareIcon(systemName: String, bgColor: some ShapeStyle, fgColor: some ShapeStyle, label: String, bordered: Bool = false) -> some View {
        VStack(spacing: 6) {
            ZStack { Circle().fill(bgColor).frame(width: 56, height: 56).overlay { if bordered { Circle().stroke(palette.textSecondary.opacity(0.2), lineWidth: 1) } }; Image(systemName: systemName).font(.system(size: 22)).foregroundStyle(fgColor) }
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(palette.textSecondary)
        }
    }

    private func shareText() {
        let name = UserNameService.name; let isKorean = Locale.current.language.languageCode?.identifier == "ko"
        let text = isKorean
            ? "\(viewModel.grade.emoji) \(name)님의 액자 맞추기: 오차 \(String(format: "%.1f", session.averageError))pt · 상위 \(viewModel.percentile)% — QuickTap"
            : "\(viewModel.grade.emoji) \(name)'s Frame Match: Error \(String(format: "%.1f", session.averageError))pt · Top \(viewModel.percentile)% — QuickTap"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene, let root = ws.windows.first?.rootViewController else { return }
        var top = root; while let p = top.presentedViewController { top = p }; top.present(vc, animated: true)
    }
}
