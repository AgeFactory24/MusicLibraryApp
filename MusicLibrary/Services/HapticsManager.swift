//
//  HapticsManager.swift
//  MusicLibrary
//
//  ハプティックフィードバックの共通管理
//

import UIKit

enum HapticType {
    case light       // ランキングタップ、月切替など軽いタップ
    case medium      // お気に入りタップ、ボタン押下
    case heavy       // 重要な操作
    case success     // 成功通知
    case warning     // 警告
    case error       // エラー
}

enum Haptics {
    /// メインエントリポイント
    static func play(_ type: HapticType) {
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
