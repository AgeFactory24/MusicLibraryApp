//
//  NotificationService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import UserNotifications
import Combine

enum NotificationKind: String, CaseIterable, Identifiable {
    case weeklyReport = "weekly_report"
    case monthlyReport = "monthly_report"
    case rediscoverFavorite = "rediscover_favorite"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weeklyReport: return "週次レポート通知"
        case .monthlyReport: return "月次レポート通知"
        case .rediscoverFavorite: return "久しぶりの曲を発見"
        }
    }

    var description: String {
        switch self {
        case .weeklyReport:
            return "毎週月曜9時に先週の再生数を通知"
        case .monthlyReport:
            return "毎月1日10時に月次レポート完成を通知"
        case .rediscoverFavorite:
            return "30日以上聴いていないお気に入り楽曲を通知"
        }
    }

    var icon: String {
        switch self {
        case .weeklyReport: return "calendar.badge.clock"
        case .monthlyReport: return "calendar"
        case .rediscoverFavorite: return "heart.text.square"
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {

    /// 各通知の有効/無効状態（UserDefaultsに保存）
    @Published var enabledKinds: Set<NotificationKind> = [] {
        didSet { saveEnabled() }
    }

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let userDefaults = UserDefaults.standard
    private let enabledKey = "MusicLibrary.NotificationEnabled"

    init() {
        loadEnabled()
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - 認証

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorization()
            return granted
        } catch {
            print("⚠️ 通知認証エラー: \(error)")
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - トグル

    func toggle(_ kind: NotificationKind, enabled: Bool) {
        if enabled {
            enabledKinds.insert(kind)
            scheduleNotification(kind)
        } else {
            enabledKinds.remove(kind)
            cancelNotification(kind)
        }
    }

    func isEnabled(_ kind: NotificationKind) -> Bool {
        enabledKinds.contains(kind)
    }

    // MARK: - スケジュール

    private func scheduleNotification(_ kind: NotificationKind) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        let trigger: UNNotificationTrigger

        switch kind {
        case .weeklyReport:
            content.title = "📊 週間レポート"
            content.body = "先週聴いた音楽を振り返ろう！"
            content.userInfo = ["destination": "weekly"]

            // 毎週月曜9時
            var components = DateComponents()
            components.weekday = 2  // 月曜（1=日曜）
            components.hour = 9
            components.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        case .monthlyReport:
            content.title = "🎵 月間レポート"
            content.body = "先月のリスニングレポートが完成しました"
            content.userInfo = ["destination": "monthly"]

            // 毎月1日10時
            var components = DateComponents()
            components.day = 1
            components.hour = 10
            components.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        case .rediscoverFavorite:
            content.title = "💖 久しぶりの曲"
            content.body = "30日以上聴いていないお気に入り楽曲があります"
            content.userInfo = ["destination": "favorites"]

            // 毎週日曜18時にチェック
            var components = DateComponents()
            components.weekday = 1
            components.hour = 18
            components.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: kind.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 通知スケジュール失敗 [\(kind.rawValue)]: \(error)")
            } else {
                print("✅ 通知スケジュール成功: \(kind.rawValue)")
            }
        }
    }

    private func cancelNotification(_ kind: NotificationKind) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [kind.rawValue])
    }

    // MARK: - 起動誘導通知（同期精度向上目的）

    static func scheduleEngagementIfNeeded() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            let lastOpenTs = UserDefaults.standard.double(forKey: "MusicLibrary.LastAppOpen")
            guard lastOpenTs > 0,
                  Date().timeIntervalSince(Date(timeIntervalSince1970: lastOpenTs)) > 48 * 3600 else { return }

            guard UserDefaults.standard.integer(forKey: PlayHistoryTracker.lastSyncNewHistoryKey) > 0 else { return }

            let lastEngagementTs = UserDefaults.standard.double(forKey: "MusicLibrary.LastEngagementNotification")
            if lastEngagementTs > 0,
               Date().timeIntervalSince(Date(timeIntervalSince1970: lastEngagementTs)) < 72 * 3600 { return }

            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "MusicLibrary.LastEngagementNotification")

            let messages: [(String, String)] = [
                ("今週のTOP楽曲が更新されました", "アプリを開いて最新のランキングを確認しよう"),
                ("新しい音楽パーソナリティが判定されました", "最近のリスニング傾向をチェックしよう"),
                ("月別レポートが更新されています", "先月の音楽履歴を振り返ってみよう")
            ]
            let picked = messages[Int(Date().timeIntervalSince1970 / 86400) % messages.count]

            let content = UNMutableNotificationContent()
            content.title = picked.0
            content.body = picked.1
            content.sound = .default
            content.userInfo = ["destination": "home", "kind": "engagement"]

            let request = UNNotificationRequest(
                identifier: "engagement_sync",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            try? await center.add(request)
        }
    }

    // MARK: - UserDefaults

    private func saveEnabled() {
        let strings = enabledKinds.map(\.rawValue)
        userDefaults.set(strings, forKey: enabledKey)
    }

    private func loadEnabled() {
        guard let strings = userDefaults.array(forKey: enabledKey) as? [String] else { return }
        enabledKinds = Set(strings.compactMap { NotificationKind(rawValue: $0) })
    }
}
