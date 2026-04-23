// Views/MultiTap/MultiTapTestView.swift
import SwiftUI
import TopDesignSystem

struct MultiTapTestView: View {
    let onComplete: (MultiTapSession) -> Void
    let onCancel: () -> Void

    @State private var viewModel = MultiTapViewModel()
    @Environment(\.designPalette) var palette
    @State private var shakeTrigger: CGFloat = 0

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            // Wrong tap red flash
            if viewModel.showWrongFlash {
                Color.red.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            switch viewModel.state {
            case .idle:
                EmptyView()

            case .countdown(let n):
                VStack(spacing: DesignSpacing.lg) {
                    CountdownView(seconds: n)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: n)
                    Text(String(localized: "Tap circles only!"))
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)
                }

            case .playing:
                playingView

            case .completed:
                Text(String(localized: "Done!"))
                    .font(.ssTitle1)
                    .foregroundStyle(palette.textPrimary)
                    .onAppear {
                        let session = viewModel.buildSession()
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            onComplete(session)
                        }
                    }
            }
        }
        .modifier(ShakeEffect(animatableData: shakeTrigger))
        .animation(.easeInOut(duration: 0.1), value: viewModel.showWrongFlash)
        .onChange(of: viewModel.state) { _, newState in
            if case .countdown = newState {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onChange(of: viewModel.wrongTaps) { _, _ in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.linear(duration: 0.3)) {
                shakeTrigger += 1
            }
        }
        .onAppear { viewModel.startTest() }
        .onDisappear { viewModel.cancelAll() }
    }

    // MARK: - Playing View

    private var playingView: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(viewModel.shapes.filter { !$0.isCollected }) { shape in
                    shapeView(shape)
                        .position(
                            x: shape.x * geo.size.width,
                            y: shape.y * geo.size.height
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                        .onTapGesture {
                            viewModel.handleTap(
                                at: CGPoint(x: shape.x * geo.size.width, y: shape.y * geo.size.height),
                                in: geo.size
                            )
                        }
                }
            }
            .animation(.easeOut(duration: 0.12), value: viewModel.shapes.map { $0.id })

            // HUD
            VStack {
                hud
                    .padding(.top, DesignSpacing.sm)
                Spacer()
            }
        }
    }

    private var hud: some View {
        HStack {
            // Back button
            Button {
                viewModel.cancelAll()
                onCancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.ssBody)
                    .foregroundStyle(palette.primaryAction)
            }

            // Timer
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.ssCaption)
                    .foregroundStyle(palette.textSecondary)
                Text(String(format: "%.1f", viewModel.remainingTime))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(viewModel.remainingTime < 5 ? palette.error : palette.textPrimary)
                    .contentTransition(.numericText())
            }

            Spacer()

            HStack(spacing: 8) {
                Text("○ \(viewModel.circlesTapped)")
                    .font(.ssFootnote)
                    .foregroundStyle(palette.success)
                if viewModel.wrongTaps > 0 {
                    Text("✗ \(viewModel.wrongTaps)")
                        .font(.ssCaption)
                        .foregroundStyle(palette.error)
                }
            }
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.horizontal, DesignSpacing.md)
    }

    @ViewBuilder
    private func shapeView(_ shape: SpawnedShape) -> some View {
        let size: CGFloat = 44
        let shapeColor = palette.primaryAction
        switch shape.kind {
        case .circle:
            Circle()
                .fill(shapeColor)
                .frame(width: size, height: size)

        case .triangle:
            TriangleShape()
                .fill(shapeColor)
                .frame(width: size, height: size)

        case .square:
            RoundedRectangle(cornerRadius: 6)
                .fill(shapeColor)
                .frame(width: size - 4, height: size - 4)
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
