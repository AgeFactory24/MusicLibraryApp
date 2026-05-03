//
//  NowPlayingActivityManager.swift
//  MusicLibrary
//
//  Apple Music の再生状態を監視 → Live Activity を制御
//  安定性重視：エラー時はサイレントに無効化
//

import Foundation
import CoreData
import MediaPlayer
import ActivityKit
import Combine

@MainActor
final class NowPlayingActivityManager: ObservableObject {

    static let shared = NowPlayingActivityManager()

    private var currentActivity: Activity<NowPlayingActivityAttributes>?
    private var observers: [NSObjectProtocol] = []
    private let player = MPMusicPlayerController.systemMusicPlayer
    private var isStarted = false
    private var isAvailable: Bool = false

    private init() {}

    /// 監視開始（多重起動防止）
    func start() {
        guard !isStarted else { return }

        // Live Activity 利用可能性を確認
        guard #available(iOS 16.1, *) else {
            print("⚠️ Live Activity は iOS 16.1+ が必要")
            return
        }

        // 認可状態を確認
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else {
            print("⚠️ Live Activity が無効化されています（設定→アプリ→Live Activity）")
            return
        }

        isAvailable = true
        isStarted = true

        // Apple Music の再生通知を購読（try-catchで保護）
        do {
            player.beginGeneratingPlaybackNotifications()
        }

        let nowPlayingObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleNowPlayingChanged()
            }
        }

        let stateObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackStateChanged()
            }
        }

        observers = [nowPlayingObserver, stateObserver]

        // 初期状態確認（再生中なら開始）
        handleNowPlayingChanged()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false

        player.endGeneratingPlaybackNotifications()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()

        Task { await endCurrentActivity() }
    }

    // MARK: - イベントハンドラ

    private func handleNowPlayingChanged() {
        guard isAvailable else { return }

        guard let item = player.nowPlayingItem else {
            Task { await endCurrentActivity() }
            return
        }

        let trackID = String(item.persistentID)
        let title = item.title ?? "不明"
        let artist = item.artist ?? "不明"
        let totalPlayCount = item.playCount
        let monthlyCount = calculateMonthlyPlayCount(trackID: trackID)
        let isPlaying = player.playbackState == .playing

        Task { @MainActor in
            if let activity = currentActivity, activity.attributes.trackID == trackID {
                let newState = NowPlayingActivityAttributes.NowPlayingState(
                    totalPlayCount: totalPlayCount,
                    monthlyPlayCount: monthlyCount,
                    isPlaying: isPlaying
                )
                await activity.update(ActivityContent(state: newState, staleDate: nil))
            } else {
                await endCurrentActivity()
                await startActivity(
                    trackID: trackID,
                    title: title,
                    artist: artist,
                    totalPlayCount: totalPlayCount,
                    monthlyPlayCount: monthlyCount,
                    isPlaying: isPlaying
                )
            }
        }
    }

    private func handlePlaybackStateChanged() {
        guard isAvailable, let activity = currentActivity else { return }

        let isPlaying = player.playbackState == .playing
        Task { @MainActor in
            let state = activity.content.state
            let newState = NowPlayingActivityAttributes.NowPlayingState(
                totalPlayCount: state.totalPlayCount,
                monthlyPlayCount: state.monthlyPlayCount,
                isPlaying: isPlaying
            )
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
    }

    // MARK: - Activity の開始・終了（エラー時は無効化）

    private func startActivity(
        trackID: String, title: String, artist: String,
        totalPlayCount: Int, monthlyPlayCount: Int, isPlaying: Bool
    ) async {
        // 容量・権限チェック
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = NowPlayingActivityAttributes(
            trackID: trackID,
            title: title,
            artistName: artist
        )
        let initialState = NowPlayingActivityAttributes.NowPlayingState(
            totalPlayCount: totalPlayCount,
            monthlyPlayCount: monthlyPlayCount,
            isPlaying: isPlaying
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            // エラー時は無効化してログ出力のみ
            print("⚠️ Live Activity 開始失敗（無効化）: \(error.localizedDescription)")
            isAvailable = false
        }
    }

    private func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(activity.content, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    // MARK: - 今月の再生回数計算

    private func calculateMonthlyPlayCount(trackID: String) -> Int {
        let context = PersistenceController.shared.container.viewContext

        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()

        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(
            format: "trackID == %@ AND playedAt >= %@",
            trackID, startOfMonth as NSDate
        )

        return (try? context.count(for: request)) ?? 0
    }
}
