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

    /// 1曲あたり最大何件の履歴を生成するか
    /// 300件 → 大半の楽曲が正確に反映される
    static let maxHistoryPerTrack = 300

    static let batchSaveSize = 500

    private let initialSnapshotKey = "MusicLibrary.HasInitialSnapshot"
    private var hasInitialSnapshot: Bool {
        get { UserDefaults.standard.bool(forKey: initialSnapshotKey) }
        set { UserDefaults.standard.set(newValue, forKey: initialSnapshotKey) }
    }

    private let diffSyncCountKey = "MusicLibrary.DiffSyncCount"
    var diffSyncCount: Int {
        get { UserDefaults.standard.integer(forKey: diffSyncCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: diffSyncCountKey) }
    }

    static let lastSyncDateKey = "MusicLibrary.LastSyncDate"
    static let lastSyncSongCountKey = "MusicLibrary.LastSyncSongCount"
    static let lastSyncNewHistoryKey = "MusicLibrary.LastSyncNewHistory"

    var historyAccuracyLevel: HistoryAccuracyLevel {
        HistoryAccuracyLevel.level(for: diffSyncCount)
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        self.container = PersistenceController.shared.container
    }

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

        if !hasInitialSnapshot {
            print("📸 初回起動: スナップショットのみ記録（履歴生成なし）")
            await performInitialSnapshotOnly(snapshots: snapshots)
            hasInitialSnapshot = true
        } else {
            print("🔄 差分同期")
            await performIncrementalSyncBatched(snapshots: snapshots)
            diffSyncCount += 1
        }

        await MainActor.run {
            self.context.refreshAllObjects()
            self.lastSyncCompletedAt = Date()
            self.syncProgress = nil
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastSyncDateKey)
            UserDefaults.standard.set(snapshots.count, forKey: Self.lastSyncSongCountKey)
        }
    }

    func resetAndRebuildHistory() async {
        print("🔄 履歴リセット開始")
        hasInitialSnapshot = false
        diffSyncCount = 0

        let bgContext = container.newBackgroundContext()
        await bgContext.perform {
            let historyRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
            try? bgContext.execute(NSBatchDeleteRequest(fetchRequest: historyRequest))

            let snapshotRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayCountSnapshotEntity")
            try? bgContext.execute(NSBatchDeleteRequest(fetchRequest: snapshotRequest))

            try? bgContext.save()
        }

        context.refreshAllObjects()
        lastSyncedAt = nil
        await syncPlayHistory(force: true)

        print("✅ 履歴リセット完了")
    }

    // 初回起動: playCount のスナップショットのみ記録。PlayHistoryEntity は生成しない。
    private func performInitialSnapshotOnly(snapshots: [MediaItemSnapshot]) async {
        let total = snapshots.count
        var processed = 0
        let chunkSize = 200

        for chunkStart in stride(from: 0, to: snapshots.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, snapshots.count)
            let chunk = Array(snapshots[chunkStart..<chunkEnd])

            let bgContext = container.newBackgroundContext()
            bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                bgContext.perform {
                    for snapshot in chunk {
                        Self.updateSnapshot(trackID: snapshot.trackID, count: snapshot.playCount, in: bgContext)
                    }
                    do {
                        try bgContext.save()
                        bgContext.reset()
                    } catch {
                        print("⚠️ スナップショット保存失敗: \(error)")
                    }
                    continuation.resume()
                }
            }

            processed += chunk.count
            await MainActor.run {
                self.syncProgress = SyncProgress(processed: processed, total: total)
            }
        }

        print("✅ 初回スナップショット完了: \(total)件")
    }

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
                    }
                } catch {
                    print("⚠️ 同期保存失敗: \(error)")
                }
            }
            let count = newHistoryCount
            Task { @MainActor in
                UserDefaults.standard.set(count, forKey: Self.lastSyncNewHistoryKey)
            }
        }
    }

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
        trackID: String, count: Int32, in context: NSManagedObjectContext
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
