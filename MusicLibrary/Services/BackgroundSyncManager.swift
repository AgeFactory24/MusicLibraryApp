//
//  BackgroundSyncManager.swift
//  MusicLibrary
//
//  バックグラウンド更新で履歴を定期的に同期
//

import Foundation
import BackgroundTasks
import UIKit

@MainActor
final class BackgroundSyncManager {

    static let shared = BackgroundSyncManager()

    /// バックグラウンドタスクID（Info.plistにも登録が必要）
    static let taskIdentifier = "com.yourcompany.MusicLibrary.refresh"

    private let tracker = PlayHistoryTracker()

    /// 起動時に一度だけ呼ぶ：BGTaskを登録
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }

    /// バックグラウンド更新をスケジュール
    /// 最低15分以降に実行されるが、iOSが空き時間に判断して動かす
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)  // 30分後以降

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ BGTask scheduled")
        } catch {
            print("⚠️ BGTask schedule failed: \(error)")
        }
    }

    // MARK: - 実行

    private func handleRefresh(task: BGAppRefreshTask) async {
        // 次回の更新を予約（重要：これがないと一度しか動かない）
        scheduleNextRefresh()

        // タイムアウト時のクリーンアップ
        task.expirationHandler = {
            // 必要なら処理を中断
        }

        // 履歴同期（性能観点：非同期でブロックしない）
        await tracker.syncPlayHistory()

        task.setTaskCompleted(success: true)
    }
}
