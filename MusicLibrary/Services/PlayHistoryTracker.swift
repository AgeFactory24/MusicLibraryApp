//
//  PlayHistoryTracker.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import CoreData
import MediaPlayer
import Combine

@MainActor
final class PlayHistoryTracker: ObservableObject {

    @Published var lastSyncCompletedAt: Date?
    @Published var syncProgress: SyncProgress?

    struct SyncProgress {
        let processed: Int
        let total: Int
        var percentage: Double {
            guard total > 0 else { return 0 }
            return Double(processed) / Double(total)
        }
    }

    private let context: NSManagedObjectContext
    private let container: NSPersistentContainer

    private var lastSyncedAt: Date?
    private let minSyncInterval: TimeInterval = 30

    /// 1曲あたり最大何件の履歴を生成するか（パフォーマンス対策）
    static let maxHistoryPerTrack = 50

    /// 一度に保存する履歴の件数（メモリ膨張を防ぐ）
    static let batchSaveSize = 500

    private let backfilledKey = "MusicLibrary.HasBackfilled"
    private var hasBackfilled: Bool {
        get { UserDefaults.standard.bool(forKey: backfilledKey) }
        set { UserDefaults.standard.set(newValue, forKey: backfilledKey) }
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        self.container = PersistenceController.shared.container
    }

    /// 起動時/フォアグラウンド復帰時に呼ぶ
    func syncPlayHistory(force: Bool = false) async {
        if !force, let last = lastSyncedAt,
           Date().timeIntervalSince(last) < minSyncInterval {
            return
        }
        lastSyncedAt = Date()

        let query = MPMediaQuery.songs()
        guard let items = query.items else {
            print("⚠️ MPMediaQuery: items取得失敗")
            return
        }

        print("📊 MPMediaQueryで\(items.count)件の楽曲を取得")

        let snapshots: [MediaItemSnapshot] = items.compactMap { item in
            guard let title = item.title else { return nil }
            return MediaItemSnapshot(
                trackID: String(item.persistentID),
                title: title,
                artistName: item.artist ?? "不明",
                albumTitle: item.albumTitle ?? "不明",
                playCount: Int32(item.playCount),
                duration: item.playbackDuration,
                lastPlayedDate: item.lastPlayedDate ?? Date(),
                isLocalAsset: item.assetURL != nil
            )
        }

        let needsBackfill = !hasBackfilled
        print("🔄 同期モード: \(needsBackfill ? "初回バックフィル" : "差分同期")")

        if needsBackfill {
            await performInitialBackfillBatched(snapshots: snapshots)
            hasBackfilled = true
        } else {
            await performIncrementalSyncBatched(snapshots: snapshots)
        }

        await MainActor.run {
            self.context.refreshAllObjects()
            self.lastSyncCompletedAt = Date()
            self.syncProgress = nil
        }
    }

    /// デバッグ用：履歴を全削除してバックフィルし直す
    func resetAndRebuildHistory() async {
        print("🔄 履歴リセット開始")

        hasBackfilled = false

        let bgContext = container.newBackgroundContext()
        await bgContext.perform {
            let historyRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
            let historyDelete = NSBatchDeleteRequest(fetchRequest: historyRequest)
            try? bgContext.execute(historyDelete)

            let snapshotRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayCountSnapshotEntity")
            let snapshotDelete = NSBatchDeleteRequest(fetchRequest: snapshotRequest)
            try? bgContext.execute(snapshotDelete)

            try? bgContext.save()
        }

        context.refreshAllObjects()

        lastSyncedAt = nil
        await syncPlayHistory(force: true)

        print("✅ 履歴リセット完了")
    }

    // MARK: - 初回バックフィル（バッチ処理）

    private func performInitialBackfillBatched(snapshots: [MediaItemSnapshot]) async {
        let sorted = snapshots.sorted { $0.playCount > $1.playCount }
        let total = sorted.count
        var processed = 0
        var totalCreated = 0

        let trackChunkSize = 100

        for chunkStart in stride(from: 0, to: sorted.count, by: trackChunkSize) {
            let chunkEnd = min(chunkStart + trackChunkSize, sorted.count)
            let chunk = Array(sorted[chunkStart..<chunkEnd])

            let bgContext = container.newBackgroundContext()
            bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let createdInChunk = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
                bgContext.perform {
                    let count = Self.processBackfillChunk(snapshots: chunk, in: bgContext)
                    do {
                        try bgContext.save()
                        bgContext.reset()
                    } catch {
                        print("⚠️ チャンク保存失敗: \(error)")
                    }
                    continuation.resume(returning: count)
                }
            }

            totalCreated += createdInChunk
            processed += chunk.count

            await MainActor.run {
                self.syncProgress = SyncProgress(processed: processed, total: total)
            }

            print("📦 進捗: \(processed)/\(total) 楽曲処理完了 (累計\(totalCreated)件作成)")
        }

        print("✅ バックフィル完了: 合計\(totalCreated)件の履歴を作成")
    }

    /// 1チャンク（100楽曲程度）を処理
    private static func processBackfillChunk(
        snapshots: [MediaItemSnapshot],
        in context: NSManagedObjectContext
    ) -> Int {
        var created = 0

        for snapshot in snapshots {
            updateSnapshot(trackID: snapshot.trackID, count: snapshot.playCount, in: context)

            guard snapshot.playCount > 0 else { continue }

            let existingRequest = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
            existingRequest.predicate = NSPredicate(format: "trackID == %@", snapshot.trackID)
            let existingCount = (try? context.count(for: existingRequest)) ?? 0

            if existingCount > 0 {
                continue
            }

            let entriesToCreate = min(Int(snapshot.playCount), maxHistoryPerTrack)

            for i in 0..<entriesToCreate {
                let entry = PlayHistoryEntity(context: context)
                entry.trackID = snapshot.trackID
                entry.title = snapshot.title
                entry.artistName = snapshot.artistName
                entry.albumTitle = snapshot.albumTitle
                entry.duration = snapshot.duration > 0 ? snapshot.duration : 180
                entry.isLocalAsset = snapshot.isLocalAsset
                entry.playCountSnapshot = snapshot.playCount - Int32(i)
                entry.playedAt = snapshot.lastPlayedDate.addingTimeInterval(-Double(i) * 1800)
            }
            created += entriesToCreate
        }

        return created
    }

    // MARK: - 差分同期（バッチ処理）

    private func performIncrementalSyncBatched(snapshots: [MediaItemSnapshot]) async {
        let bgContext = container.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        await bgContext.perform {
            let snapshotMap = Self.fetchAllSnapshots(in: bgContext)
            var newHistoryCount = 0
            var processedSinceLastSave = 0

            for snapshot in snapshots {
                let trackID = snapshot.trackID
                let currentCount = snapshot.playCount
                let previousCount = snapshotMap[trackID] ?? 0

                let diff = currentCount - previousCount
                if diff > 0 {
                    // ↓ 修正: Self. を付ける
                    let entriesToCreate = min(Int(diff), Self.maxHistoryPerTrack)

                    for i in 0..<entriesToCreate {
                        let entry = PlayHistoryEntity(context: bgContext)
                        entry.trackID = snapshot.trackID
                        entry.title = snapshot.title
                        entry.artistName = snapshot.artistName
                        entry.albumTitle = snapshot.albumTitle
                        entry.duration = snapshot.duration > 0 ? snapshot.duration : 180
                        entry.isLocalAsset = snapshot.isLocalAsset
                        entry.playCountSnapshot = currentCount - Int32(i)
                        entry.playedAt = snapshot.lastPlayedDate.addingTimeInterval(-Double(i) * 1800)
                    }
                    newHistoryCount += entriesToCreate
                    processedSinceLastSave += entriesToCreate
                }

                Self.updateSnapshot(trackID: trackID, count: currentCount, in: bgContext)

                // ↓ 修正: Self. を付ける
                if processedSinceLastSave >= Self.batchSaveSize {
                    do {
                        try bgContext.save()
                        bgContext.reset()
                        processedSinceLastSave = 0
                    } catch {
                        print("⚠️ 中間保存失敗: \(error)")
                    }
                }
            }

            if bgContext.hasChanges {
                do {
                    try bgContext.save()
                    if newHistoryCount > 0 {
                        print("✅ \(newHistoryCount)件の再生履歴を追加")
                    } else {
                        print("ℹ️ 差分同期: 新規履歴なし")
                    }
                } catch {
                    print("⚠️ 同期保存失敗: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    private static func fetchAllSnapshots(in context: NSManagedObjectContext) -> [String: Int32] {
        let request = NSFetchRequest<PlayCountSnapshotEntity>(entityName: "PlayCountSnapshotEntity")
        guard let results = try? context.fetch(request) else { return [:] }

        var map: [String: Int32] = [:]
        for snapshot in results {
            map[snapshot.trackID] = snapshot.playCount
        }
        return map
    }

    private static func updateSnapshot(
        trackID: String,
        count: Int32,
        in context: NSManagedObjectContext
    ) {
        let request = NSFetchRequest<PlayCountSnapshotEntity>(entityName: "PlayCountSnapshotEntity")
        request.predicate = NSPredicate(format: "trackID == %@", trackID)
        request.fetchLimit = 1

        let snapshot: PlayCountSnapshotEntity
        if let existing = try? context.fetch(request).first {
            snapshot = existing
        } else {
            snapshot = PlayCountSnapshotEntity(context: context)
            snapshot.trackID = trackID
        }
        snapshot.playCount = count
        snapshot.recordedAt = Date()
    }
}

struct MediaItemSnapshot: Sendable {
    let trackID: String
    let title: String
    let artistName: String
    let albumTitle: String
    let playCount: Int32
    let duration: Double
    let lastPlayedDate: Date
    let isLocalAsset: Bool
}
