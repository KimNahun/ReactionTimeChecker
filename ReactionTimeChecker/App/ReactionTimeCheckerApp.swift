// App/ReactionTimeCheckerApp.swift
import SwiftUI
import TopDesignSystem
import KakaoSDKCommon

@main
struct ReactionTimeCheckerApp: App {
    @State private var deepLinkMode: String?

    init() {
        KakaoSDK.initSDK(appKey: Secrets.kakaoAppKey)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(deepLinkMode: $deepLinkMode)
                .designTheme(.airbnb)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("[DeepLink] Received URL: \(url.absoluteString)")

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
                deepLinkMode = params["mode"] // nil = reaction, "stroop" = stroop
            }
        }
    }
}
