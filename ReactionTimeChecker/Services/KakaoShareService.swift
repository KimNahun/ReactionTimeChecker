// Services/KakaoShareService.swift
import UIKit
import KakaoSDKShare
import KakaoSDKTemplate

@MainActor
struct KakaoShareService {

    static func share(session: TestSession, grade: Grade, percentile: Int) {
        let emoji = grade.emoji
        let avgMs = session.averageMs
        let bestMs = session.bestMs

        let isKorean = Locale.current.language.languageCode?.identifier == "ko"

        let title = isKorean ? "당신의 반응속도는?" : "What's your reaction time?"

        let description: String
        if isKorean {
            description = "\(emoji) \(avgMs)ms · \(grade.name) · 상위 \(percentile)% · 최고 \(bestMs)ms"
        } else {
            description = "\(emoji) \(avgMs)ms · \(grade.name) · Top \(percentile)% · Best \(bestMs)ms"
        }

        let buttonTitle = isKorean ? "측정하기" : "Try it"

        let storeUrl = URL(string: "https://itunes.apple.com/app/id6762595451")

        let appLink = Link(
            webUrl: storeUrl,
            mobileWebUrl: storeUrl,
            iosExecutionParams: ["challenge": "true", "targetMs": "\(avgMs)"]
        )

        // 결과 카드 이미지 렌더링
        let cardView = ShareCardView(
            averageMs: avgMs,
            bestMs: bestMs,
            worstMs: session.worstMs,
            percentile: percentile,
            grade: grade
        )

        guard let cardImage = cardView.renderImage() else {
            // 이미지 렌더링 실패 시 이미지 없이 공유
            sendFeedTemplate(title: title, imageUrl: nil, description: description,
                             buttonTitle: buttonTitle, appLink: appLink)
            return
        }

        // 카카오 서버에 이미지 업로드 → URL 받아서 FeedTemplate에 사용
        ShareApi.shared.imageUpload(image: cardImage) { result, error in
            let imageUrl: URL?
            if let result {
                imageUrl = result.infos.original.url
            } else {
                print("[KakaoShare] Image upload failed: \(error?.localizedDescription ?? "unknown")")
                imageUrl = nil
            }

            sendFeedTemplate(title: title, imageUrl: imageUrl, description: description,
                             buttonTitle: buttonTitle, appLink: appLink)
        }
    }

    // MARK: - Stroop Share

    static func shareStroop(session: StroopSession, grade: Grade, percentile: Int) {
        let emoji = grade.emoji
        let avgMs = session.averageMs
        let accuracy = session.accuracy

        let isKorean = Locale.current.language.languageCode?.identifier == "ko"

        let title = isKorean ? "스트룹 테스트 결과" : "Stroop Test Result"

        let description: String
        if isKorean {
            description = "\(emoji) \(avgMs)ms · \(grade.name) · 정확도 \(accuracy)% · 상위 \(percentile)%"
        } else {
            description = "\(emoji) \(avgMs)ms · \(grade.name) · Accuracy \(accuracy)% · Top \(percentile)%"
        }

        let buttonTitle = isKorean ? "도전하기" : "Try it"

        let storeUrl = URL(string: "https://itunes.apple.com/app/id6762595451")

        let appLink = Link(
            webUrl: storeUrl,
            mobileWebUrl: storeUrl,
            iosExecutionParams: ["challenge": "true", "mode": "stroop", "targetMs": "\(avgMs)"]
        )

        let cardView = StroopShareCardView(
            averageMs: avgMs,
            bestMs: session.bestMs,
            worstMs: session.worstMs,
            accuracy: accuracy,
            percentile: percentile,
            grade: grade
        )

        guard let cardImage = cardView.renderImage() else {
            sendFeedTemplate(title: title, imageUrl: nil, description: description,
                             buttonTitle: buttonTitle, appLink: appLink)
            return
        }

        ShareApi.shared.imageUpload(image: cardImage) { result, error in
            let imageUrl: URL?
            if let result {
                imageUrl = result.infos.original.url
            } else {
                print("[KakaoShare] Image upload failed: \(error?.localizedDescription ?? "unknown")")
                imageUrl = nil
            }

            sendFeedTemplate(title: title, imageUrl: imageUrl, description: description,
                             buttonTitle: buttonTitle, appLink: appLink)
        }
    }

    // MARK: - Common

    private static func sendFeedTemplate(title: String, imageUrl: URL?, description: String,
                                          buttonTitle: String, appLink: Link) {
        let content = Content(
            title: title,
            imageUrl: imageUrl,
            description: description,
            link: appLink
        )

        let feedTemplate = FeedTemplate(
            content: content,
            buttonTitle: buttonTitle
        )

        if ShareApi.isKakaoTalkSharingAvailable() {
            ShareApi.shared.shareDefault(templatable: feedTemplate) { sharingResult, error in
                if let error {
                    print("[KakaoShare] Error: \(error.localizedDescription)")
                    fallbackWebShare(feedTemplate: feedTemplate)
                    return
                }
                guard let sharingResult else { return }
                UIApplication.shared.open(sharingResult.url, options: [:])
            }
        } else {
            fallbackWebShare(feedTemplate: feedTemplate)
        }
    }

    private static func fallbackWebShare(feedTemplate: FeedTemplate) {
        if let url = ShareApi.shared.makeDefaultUrl(templatable: feedTemplate) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}
