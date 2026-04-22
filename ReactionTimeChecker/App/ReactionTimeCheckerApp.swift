// App/ReactionTimeCheckerApp.swift
import SwiftUI
import TopDesignSystem
import KakaoSDKCommon

@main
struct ReactionTimeCheckerApp: App {
    @State private var phase: AppPhase = .home

    init() {
        KakaoSDK.initSDK(appKey: Secrets.kakaoAppKey)
    }

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
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("[DeepLink] Received URL: \(url.absoluteString)")

        // 카카오 딥링크 URL 형식 예시:
        //   kakaob7a...://kakaolink?challenge=true&targetMs=215
        //   kakaob7a...://challenge=true&targetMs=215
        //   kakaob7a...://?challenge=true&targetMs=215

        // URLComponents로 query 파싱 시도
        let urlString = url.absoluteString
        var params: [String: String] = [:]

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }

        // URLComponents 파싱 실패 시 수동 파싱 (카카오가 비표준 형식을 쓸 수 있음)
        if params.isEmpty, let range = urlString.range(of: "?") {
            let queryString = String(urlString[range.upperBound...])
            for pair in queryString.split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                if kv.count == 2 {
                    params[String(kv[0])] = String(kv[1])
                }
            }
        }

        print("[DeepLink] Parsed params: \(params)")

        if params["challenge"] == "true" {
            withAnimation(.smooth(duration: 0.35)) {
                phase = .home
            }
        }
    }

    private var phaseIdentifier: String {
        switch phase {
        case .home:        return "home"
        case .testing:     return "testing"
        case .result:      return "result"
        }
    }
}
