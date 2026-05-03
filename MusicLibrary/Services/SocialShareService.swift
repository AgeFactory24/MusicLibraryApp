//
//  SocialShareService.swift
//  MusicLibrary
//
//  Instagram Stories / X(Twitter) 共有処理
//

import SwiftUI
import UIKit
import Photos

enum ShareDestination {
    case instagram   // 1080x1920
    case twitter     // 1200x630

    var size: CGSize {
        switch self {
        case .instagram: return CGSize(width: 1080, height: 1920)
        case .twitter: return CGSize(width: 1200, height: 630)
        }
    }

    var label: String {
        switch self {
        case .instagram: return "Instagram Story"
        case .twitter: return "X (Twitter)"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .twitter: return "xmark.app.fill"
        }
    }
}

@MainActor
enum SocialShareService {

    /// Instagram Storyへ直接共有
    /// 画像をパステボードに渡し、 instagram-stories://share を開く
    static func shareToInstagramStory(image: UIImage) async -> Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }

        guard UIApplication.shared.canOpenURL(url) else {
            print("⚠️ Instagram がインストールされていません")
            return false
        }

        guard let pngData = image.pngData() else { return false }

        // Instagram の仕様: backgroundImage を渡すと画像Storyになる
        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": pngData,
            "com.instagram.sharedSticker.backgroundTopColor": "#FF6B9D",
            "com.instagram.sharedSticker.backgroundBottomColor": "#C44DFF"
        ]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]

        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)

        await UIApplication.shared.open(url)
        return true
    }

    /// X (Twitter) はShareSheetで画像共有 → ユーザーがX選択
    /// (TwitterはInstagramのような専用URLスキームを公式提供していないため、ShareSheet経由が現実的)
    static func presentShareSheet(image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        viewController.present(activityVC, animated: true)
    }

    /// 写真ライブラリへ保存（フォールバック）
    static func saveToPhotos(image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return false }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
