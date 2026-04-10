// App/ReactionTimeCheckerApp.swift
import SwiftUI
import TopDesignSystem

@main
struct ReactionTimeCheckerApp: App {
    @State private var phase: AppPhase = .home

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch phase {
                case .home:
                    HomeView(phase: $phase)
                        .transition(
                            .opacity.combined(with: .scale(scale: 0.98))
                        )

                case .testing(let rounds):
                    TestView(rounds: rounds, phase: $phase)
                        .transition(
                            .opacity.combined(with: .scale(scale: 0.98))
                        )

                case .result(let session):
                    ResultView(session: session, phase: $phase)
                        .transition(
                            .opacity.combined(with: .scale(scale: 0.98))
                        )
                }
            }
            .animation(.smooth(duration: 0.35), value: phaseIdentifier)
            .designTheme(.airbnb)
        }
    }

    // Helper to give phase an equatable identifier for animation
    private var phaseIdentifier: String {
        switch phase {
        case .home:        return "home"
        case .testing:     return "testing"
        case .result:      return "result"
        }
    }
}
