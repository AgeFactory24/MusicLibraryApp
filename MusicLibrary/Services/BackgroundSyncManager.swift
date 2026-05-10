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

    private let tracker = PlayHistoryTracker.shared

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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)  // 1時間後以降

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ BGTask scheduled")
        } catch {
            print("⚠️ BGTask schedule failed: \(error)")
        }
    }

    // MARK: - 実行

    private func handleRefresh(task: BGAppRefreshTask) async {
        scheduleNextRefresh()

        let operation = Task {
            await tracker.performBackgroundSync()
        }

        task.expirationHandler = {
            operation.cancel()
        }

        await operation.value

        NotificationService.scheduleEngagementIfNeeded()

        task.setTaskCompleted(success: !operation.isCancelled)
    }
}
