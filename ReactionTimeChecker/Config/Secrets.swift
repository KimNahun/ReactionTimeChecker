// Config/Secrets.swift
import Foundation
// Info.plist → xcconfig에서 값을 읽어옵니다.
// 실제 키 값은 Secrets.xcconfig에 정의되어 있습니다.

enum Secrets {
    static let kakaoAppKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String, !key.isEmpty else {
            fatalError("KAKAO_APP_KEY not found. Copy Secrets.template.xcconfig → Secrets.xcconfig and fill in your keys.")
        }
        return key
    }()

    static let shareImageUrl: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SHARE_IMAGE_URL") as? String, !url.isEmpty else {
            return ""
        }
        return url
    }()
}
