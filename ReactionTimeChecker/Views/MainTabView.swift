// Views/MainTabView.swift
import SwiftUI
import TopDesignSystem

struct MainTabView: View {
    @Binding var deepLinkMode: String?
    @Environment(\.designPalette) var palette

    enum Destination: Sendable, Equatable {
        case none
        // Reaction
        case reactionHome, reactionTest(rounds: Int), reactionResult(session: TestSession)
        // Stroop
        case stroopHome, stroopTest(stimuli: Int), stroopResult(session: StroopSession)
        // Sequence
        case sequenceHome, sequenceTest, sequenceResult(session: SequenceSession)
        // MultiTap
        case multiTapHome, multiTapTest, multiTapResult(session: MultiTapSession)
        // TimeSense
        case timeSenseHome, timeSenseTest(timerVisible: Bool), timeSenseResult(session: TimeSenseSession)

        static func == (lhs: Destination, rhs: Destination) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none),
                 (.reactionHome, .reactionHome),
                 (.stroopHome, .stroopHome),
                 (.sequenceHome, .sequenceHome),
                 (.sequenceTest, .sequenceTest),
                 (.multiTapHome, .multiTapHome),
                 (.multiTapTest, .multiTapTest),
                 (.timeSenseHome, .timeSenseHome),
                 (.reactionResult, .reactionResult),
                 (.stroopResult, .stroopResult),
                 (.sequenceResult, .sequenceResult),
                 (.multiTapResult, .multiTapResult),
                 (.timeSenseResult, .timeSenseResult):
                return true
            case (.reactionTest(let a), .reactionTest(let b)): return a == b
            case (.stroopTest(let a), .stroopTest(let b)): return a == b
            case (.timeSenseTest(let a), .timeSenseTest(let b)): return a == b
            default: return false
            }
        }
    }

    @State private var destination: Destination = .none
    @State private var reactionPhase: AppPhase = .home
    @State private var showNameInput: Bool = false

    var body: some View {
        ZStack {
            switch destination {
            case .none:
                mainMenuView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // MARK: Reaction
            case .reactionHome:
                HomeView(phase: $reactionPhase, onBack: { goHome() })
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .reactionTest(let rounds):
                TestView(rounds: rounds, phase: $reactionPhase)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .reactionResult(let session):
                ResultView(session: session, phase: $reactionPhase)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // MARK: Stroop
            case .stroopHome:
                StroopHomeView(
                    onStart: { n in go(.stroopTest(stimuli: n)) },
                    onBack: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .stroopTest(let n):
                StroopTestView(
                    totalStimuli: n,
                    onComplete: { s in go(.stroopResult(session: s)) },
                    onCancel: { go(.stroopHome) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .stroopResult(let s):
                StroopResultView(
                    session: s,
                    onPlayAgain: { go(.stroopTest(stimuli: 30)) },
                    onHome: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // MARK: Sequence
            case .sequenceHome:
                SequenceHomeView(
                    onStart: { go(.sequenceTest) },
                    onBack: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .sequenceTest:
                SequenceTestView(
                    onComplete: { s in go(.sequenceResult(session: s)) },
                    onCancel: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .sequenceResult(let s):
                SequenceResultView(
                    session: s,
                    onPlayAgain: { go(.sequenceTest) },
                    onHome: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // MARK: MultiTap
            case .multiTapHome:
                MultiTapHomeView(
                    onStart: { go(.multiTapTest) },
                    onBack: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .multiTapTest:
                MultiTapTestView(
                    onComplete: { s in go(.multiTapResult(session: s)) },
                    onCancel: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .multiTapResult(let s):
                MultiTapResultView(
                    session: s,
                    onPlayAgain: { go(.multiTapTest) },
                    onHome: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // MARK: TimeSense
            case .timeSenseHome:
                TimeSenseHomeView(
                    onStart: { visible in go(.timeSenseTest(timerVisible: visible)) },
                    onBack: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .timeSenseTest(let visible):
                TimeSenseTestView(
                    timerVisible: visible,
                    onComplete: { s in go(.timeSenseResult(session: s)) },
                    onCancel: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .timeSenseResult(let s):
                TimeSenseResultView(
                    session: s,
                    onPlayAgain: { go(.timeSenseHome) },
                    onHome: { goHome() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            // Name input overlay
            if showNameInput {
                NameInputView { _ in
                    withAnimation(.smooth(duration: 0.35)) {
                        showNameInput = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.smooth(duration: 0.35), value: destinationId)
        .onAppear {
            if !UserNameService.hasName {
                showNameInput = true
            }
        }
        .onChange(of: reactionPhase) { _, newPhase in
            withAnimation(.smooth(duration: 0.35)) {
                switch newPhase {
                case .home:
                    destination = .none
                    reactionPhase = .home
                case .testing(let rounds):
                    destination = .reactionTest(rounds: rounds)
                case .result(let session):
                    destination = .reactionResult(session: session)
                }
            }
        }
        .onChange(of: deepLinkMode) { _, mode in
            withAnimation(.smooth(duration: 0.35)) {
                if mode == "stroop" { destination = .stroopHome }
                else { reactionPhase = .home; destination = .reactionHome }
                deepLinkMode = nil
            }
        }
    }

    // MARK: - Navigation Helpers

    private func go(_ dest: Destination) {
        withAnimation(.smooth(duration: 0.35)) { destination = dest }
    }

    private func goHome() {
        withAnimation(.smooth(duration: 0.35)) { destination = .none }
    }

    // MARK: - Main Menu Grid

    private var mainMenuView: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    Spacer().frame(height: DesignSpacing.xl)

                    Text("QuickTap")
                        .font(.ssTitle1)
                        .foregroundStyle(palette.textPrimary)

                    Text(String(localized: "Choose a test"))
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: DesignSpacing.sm), count: 3),
                        spacing: DesignSpacing.sm
                    ) {
                        testCard(emoji: "⚡️", title: String(localized: "Reaction"), subtitle: String(localized: "Tap on green"), isEnabled: true) {
                            reactionPhase = .home; go(.reactionHome)
                        }
                        testCard(emoji: "🎨", title: String(localized: "Color Stroop"), subtitle: String(localized: "Read the color"), isEnabled: true) {
                            go(.stroopHome)
                        }
                        testCard(emoji: "🔢", title: String(localized: "Sequence"), subtitle: String(localized: "Tap in order"), isEnabled: true) {
                            go(.sequenceHome)
                        }
                        testCard(emoji: "👆", title: String(localized: "Multi-Tap"), subtitle: String(localized: "Tap circles"), isEnabled: true) {
                            go(.multiTapHome)
                        }
                        testCard(emoji: "⏱️", title: String(localized: "Time Sense"), subtitle: String(localized: "Hit 10.00s"), isEnabled: true) {
                            go(.timeSenseHome)
                        }
                        // Coming soon
                        testCard(emoji: "🚫", title: String(localized: "Go/No-Go"), subtitle: String(localized: "Coming soon"), isEnabled: false) {}
                        testCard(emoji: "🔊", title: String(localized: "Sound"), subtitle: String(localized: "Coming soon"), isEnabled: false) {}
                        testCard(emoji: "🧠", title: String(localized: "Memory"), subtitle: String(localized: "Coming soon"), isEnabled: false) {}
                        testCard(emoji: "🎯", title: String(localized: "Aim"), subtitle: String(localized: "Coming soon"), isEnabled: false) {}
                    }
                    .padding(.horizontal, DesignSpacing.md)

                    Spacer().frame(height: DesignSpacing.xl)
                }
            }
        }
    }

    // MARK: - Test Card

    private func testCard(emoji: String, title: String, subtitle: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.xs) {
                Text(emoji).font(.system(size: 36))
                Text(title)
                    .font(.ssFootnote)
                    .foregroundStyle(isEnabled ? palette.textPrimary : palette.textSecondary.opacity(0.5))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.ssCaption)
                    .foregroundStyle(palette.textSecondary.opacity(isEnabled ? 0.8 : 0.4))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.md)
            .background(RoundedRectangle(cornerRadius: DesignCornerRadius.lg).fill(isEnabled ? palette.surface : palette.surface.opacity(0.4)))
            .overlay(RoundedRectangle(cornerRadius: DesignCornerRadius.lg).stroke(palette.textSecondary.opacity(isEnabled ? 0.1 : 0.05), lineWidth: 1))
        }
        .buttonStyle(.pressScale)
        .disabled(!isEnabled)
    }

    private var destinationId: String {
        switch destination {
        case .none: "none"
        case .reactionHome: "rHome"
        case .reactionTest: "rTest"
        case .reactionResult: "rResult"
        case .stroopHome: "sHome"
        case .stroopTest: "sTest"
        case .stroopResult: "sResult"
        case .sequenceHome: "seqHome"
        case .sequenceTest: "seqTest"
        case .sequenceResult: "seqResult"
        case .multiTapHome: "mtHome"
        case .multiTapTest: "mtTest"
        case .multiTapResult: "mtResult"
        case .timeSenseHome: "tsHome"
        case .timeSenseTest: "tsTest"
        case .timeSenseResult: "tsResult"
        }
    }
}
