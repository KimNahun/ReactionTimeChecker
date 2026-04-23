// Views/FrameMatch/FrameMatchTestView.swift
import SwiftUI
import TopDesignSystem

struct FrameMatchTestView: View {
    let onComplete: (FrameMatchSession) -> Void
    let onCancel: () -> Void
    @State private var viewModel = FrameMatchViewModel()
    @State private var touchProcessed = false
    @Environment(\.designPalette) var palette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // HUD
                HStack {
                    Button { viewModel.cancelAll(); onCancel() } label: {
                        Image(systemName: "chevron.left").font(.ssBody).foregroundStyle(palette.primaryAction)
                    }
                    Spacer()
                    Text("\(viewModel.completedRounds) / \(viewModel.totalRounds)")
                        .font(.ssFootnote).foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, DesignSpacing.md).padding(.vertical, DesignSpacing.sm)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal, DesignSpacing.md).padding(.top, DesignSpacing.sm)

                Spacer()
                stateContent
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !touchProcessed else { return }
                    touchProcessed = true
                    if case .moving = viewModel.state { viewModel.handleTap() }
                }
                .onEnded { _ in touchProcessed = false }
        )
        .onChange(of: viewModel.state) { _, s in handleStateChange(s) }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .countdown(let n):
            CountdownView(seconds: n).animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
        case .moving, .stopped:
            frameView
        case .completed:
            Text(String(localized: "Done!")).font(.ssTitle1).foregroundStyle(palette.textPrimary)
                .onAppear {
                    let session = viewModel.buildSession()
                    Task { try? await Task.sleep(nanoseconds: 300_000_000); onComplete(session) }
                }
        }
    }

    private var frameView: some View {
        let size = viewModel.frameSize
        return ZStack {
            // Center frame (target)
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.primaryAction, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                .frame(width: size, height: size)

            // Moving box
            RoundedRectangle(cornerRadius: 8)
                .fill(movingBoxColor)
                .frame(width: size, height: size)
                .offset(x: viewModel.squareOffset)

            // Error display when stopped
            if case .stopped(_, let error) = viewModel.state {
                VStack(spacing: DesignSpacing.sm) {
                    Text(String(format: "%dpt", Int(error)))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(error < 10 ? palette.success : error < 30 ? palette.primaryAction : palette.error)
                }
                .offset(y: -80)
            }
        }
    }

    private var movingBoxColor: some ShapeStyle {
        if case .stopped(_, let error) = viewModel.state {
            return AnyShapeStyle(error < 10 ? palette.success.opacity(0.8) : error < 30 ? palette.primaryAction.opacity(0.6) : palette.error.opacity(0.5))
        }
        return AnyShapeStyle(palette.textPrimary.opacity(0.7))
    }

    private func handleStateChange(_ s: FrameMatchState) {
        switch s {
        case .countdown: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .stopped(_, let error):
            if error < 10 { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        default: break
        }
    }
}
