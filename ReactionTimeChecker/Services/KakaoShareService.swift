// Services/KakaoShareService.swift
import UIKit
import KakaoSDKShare
import KakaoSDKTemplate

@MainActor
struct KakaoShareService {

    private static var userName: String { UserNameService.name }
    private static var isKorean: Bool { Locale.current.language.languageCode?.identifier == "ko" }
    private static var storeUrl: URL? { URL(string: "https://itunes.apple.com/app/id6762595451") }

    // MARK: - Reaction Test

    static func share(session: TestSession, grade: Grade, percentile: Int) {
        let title = isKorean
            ? "\(userName)님의 반응속도 테스트"
            : "\(userName)'s Reaction Test"

        let items = [
            ItemInfo(item: isKorean ? "반응속도" : "Speed", itemOp: "\(session.averageMs)ms"),
            ItemInfo(item: isKorean ? "최고기록" : "Best", itemOp: "\(session.bestMs)ms"),
            ItemInfo(item: isKorean ? "상위" : "Top", itemOp: "\(percentile)%"),
            ItemInfo(item: isKorean ? "등급" : "Grade", itemOp: "\(grade.emoji) \(grade.name)"),
        ]

        let itemContent = ItemContent(
            profileText: "\(userName)님의 기록",
            items: items
        )

        let appLink = Link(
            webUrl: storeUrl, mobileWebUrl: storeUrl,
            iosExecutionParams: ["challenge": "true", "targetMs": "\(session.averageMs)"]
        )

        // Render share card image
        let cardView = ShareCardView(
            averageMs: session.averageMs,
            bestMs: session.bestMs,
            worstMs: session.worstMs,
            percentile: percentile,
            grade: grade
        )

        sendWithImage(cardView.renderImage(), title: title, itemContent: itemContent,
                      buttonTitle: isKorean ? "도전하기" : "Try it", appLink: appLink)
    }

    // MARK: - Stroop Test

    static func shareStroop(session: StroopSession, grade: Grade, percentile: Int) {
        let title = isKorean
            ? "\(userName)님의 스트룹 테스트"
            : "\(userName)'s Stroop Test"

        let items = [
            ItemInfo(item: isKorean ? "반응속도" : "Speed", itemOp: "\(session.averageMs)ms"),
            ItemInfo(item: isKorean ? "정확도" : "Accuracy", itemOp: "\(session.accuracy)%"),
            ItemInfo(item: isKorean ? "상위" : "Top", itemOp: "\(percentile)%"),
            ItemInfo(item: isKorean ? "등급" : "Grade", itemOp: "\(grade.emoji) \(grade.name)"),
        ]

        let itemContent = ItemContent(
            profileText: "\(userName)님의 기록",
            items: items
        )

        let appLink = Link(
            webUrl: storeUrl, mobileWebUrl: storeUrl,
            iosExecutionParams: ["challenge": "true", "mode": "stroop"]
        )

        let cardView = StroopShareCardView(
            averageMs: session.averageMs,
            bestMs: session.bestMs,
            worstMs: session.worstMs,
            accuracy: session.accuracy,
            percentile: percentile,
            grade: grade
        )

        sendWithImage(cardView.renderImage(), title: title, itemContent: itemContent,
                      buttonTitle: isKorean ? "도전하기" : "Try it", appLink: appLink)
    }

    // MARK: - Sequence Test

    static func shareSequence(session: SequenceSession, grade: Grade, percentile: Int) {
        let totalSec = String(format: "%.2fs", Double(session.totalTimeMs) / 1000.0)

        let title = isKorean
            ? "\(userName)님의 순서 탭 테스트"
            : "\(userName)'s Sequence Test"

        var items = [
            ItemInfo(item: isKorean ? "소요시간" : "Time", itemOp: totalSec),
            ItemInfo(item: isKorean ? "상위" : "Top", itemOp: "\(percentile)%"),
            ItemInfo(item: isKorean ? "등급" : "Grade", itemOp: "\(grade.emoji) \(grade.name)"),
        ]
        if session.penaltyCount > 0 {
            items.insert(
                ItemInfo(item: isKorean ? "오탭" : "Wrong", itemOp: "\(session.penaltyCount)"),
                at: 1
            )
        }

        let itemContent = ItemContent(profileText: "\(userName)님의 기록", items: items)
        let appLink = Link(webUrl: storeUrl, mobileWebUrl: storeUrl,
                           iosExecutionParams: ["challenge": "true", "mode": "sequence"])

        sendFeedTemplate(title: title, imageUrl: nil, itemContent: itemContent,
                         buttonTitle: isKorean ? "도전하기" : "Try it", appLink: appLink)
    }

    // MARK: - MultiTap Test

    static func shareMultiTap(session: MultiTapSession, grade: Grade, percentile: Int) {
        let total = session.circlesTapped + session.circlesAutoCollected

        let title = isKorean
            ? "\(userName)님의 멀티 탭 테스트"
            : "\(userName)'s Multi-Tap Test"

        let items = [
            ItemInfo(item: isKorean ? "탭한 원" : "Circles", itemOp: isKorean ? "\(total)개" : "\(total)"),
            ItemInfo(item: isKorean ? "상위" : "Top", itemOp: "\(percentile)%"),
            ItemInfo(item: isKorean ? "등급" : "Grade", itemOp: "\(grade.emoji) \(grade.name)"),
        ]

        let itemContent = ItemContent(profileText: "\(userName)님의 기록", items: items)
        let appLink = Link(webUrl: storeUrl, mobileWebUrl: storeUrl,
                           iosExecutionParams: ["challenge": "true", "mode": "multitap"])

        sendFeedTemplate(title: title, imageUrl: nil, itemContent: itemContent,
                         buttonTitle: isKorean ? "도전하기" : "Try it", appLink: appLink)
    }

    // MARK: - TimeSense Test

    static func shareTimeSense(session: TimeSenseSession, grade: Grade, percentile: Int) {
        let errorSec = String(format: "%.2fs", Double(session.averageErrorMs) / 1000.0)
        let modeText = isKorean
            ? (session.timerVisible ? "보이기 모드" : "숨기기 모드")
            : (session.timerVisible ? "Visible" : "Hidden")

        let title = isKorean
            ? "\(userName)님의 시간 감각 테스트"
            : "\(userName)'s Time Sense Test"

        let items = [
            ItemInfo(item: isKorean ? "오차" : "Error", itemOp: errorSec),
            ItemInfo(item: isKorean ? "상위" : "Top", itemOp: "\(percentile)%"),
            ItemInfo(item: isKorean ? "등급" : "Grade", itemOp: "\(grade.emoji) \(grade.name)"),
            ItemInfo(item: isKorean ? "모드" : "Mode", itemOp: modeText),
        ]

        let itemContent = ItemContent(profileText: "\(userName)님의 기록", items: items)
        let appLink = Link(webUrl: storeUrl, mobileWebUrl: storeUrl,
                           iosExecutionParams: ["challenge": "true", "mode": "timesense"])

        sendFeedTemplate(title: title, imageUrl: nil, itemContent: itemContent,
                         buttonTitle: isKorean ? "도전하기" : "Try it", appLink: appLink)
    }

    // MARK: - Common

    private static func sendWithImage(_ image: UIImage?, title: String, itemContent: ItemContent,
                                       buttonTitle: String, appLink: Link) {
        guard let image else {
            sendFeedTemplate(title: title, imageUrl: nil, itemContent: itemContent,
                             buttonTitle: buttonTitle, appLink: appLink)
            return
        }

        ShareApi.shared.imageUpload(image: image) { result, error in
            let imageUrl = result?.infos.original.url
            if error != nil {
                print("[KakaoShare] Image upload failed: \(error?.localizedDescription ?? "")")
            }
            sendFeedTemplate(title: title, imageUrl: imageUrl, itemContent: itemContent,
                             buttonTitle: buttonTitle, appLink: appLink)
        }
    }

    private static func sendFeedTemplate(title: String, imageUrl: URL?, itemContent: ItemContent?,
                                          buttonTitle: String, appLink: Link) {
        let content = Content(
            title: title,
            imageUrl: imageUrl,
            description: isKorean ? "당신도 도전해보세요!" : "Can you beat this?",
            link: appLink
        )

        let feedTemplate = FeedTemplate(
            content: content,
            itemContent: itemContent,
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
