//
//  PlayHistoryRepository.swift
//  MusicLibrary
//

import Foundation
import CoreData

@MainActor
final class PlayHistoryRepository {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - 期間内の全履歴

    func fetchHistory(from: Date, to: Date) -> [PlayHistoryEntry] {
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(
            format: "playedAt >= %@ AND playedAt <= %@",
            from as NSDate, to as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]

        guard let results = try? context.fetch(request) else { return [] }
        return results.map(toEntry)
    }

    // MARK: - 楽曲別履歴

    func fetchHistory(trackID: String) -> [PlayHistoryEntry] {
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(format: "trackID == %@", trackID)
        request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]

        guard let results = try? context.fetch(request) else { return [] }
        return results.map(toEntry)
    }

    // MARK: - 月別集計

    func monthlyPlayCounts(year: Int) -> [Int: Int] {
        let calendar = Calendar.current
        guard let from = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let to = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return [:]
        }

        let history = fetchHistory(from: from, to: to)
        var counts: [Int: Int] = [:]
        for entry in history {
            let month = calendar.component(.month, from: entry.playedAt)
            counts[month, default: 0] += 1
        }
        return counts
    }

    // MARK: - 時間帯別集計（0-23時）

    func hourlyPlayCounts() -> [Int: Int] {
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        guard let all = try? context.fetch(request) else { return [:] }

        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for entry in all {
            let hour = calendar.component(.hour, from: entry.playedAt)
            counts[hour, default: 0] += 1
        }
        return counts
    }

    // MARK: - 曜日別集計（1=日曜...7=土曜）

    func weekdayPlayCounts() -> [Int: Int] {
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        guard let all = try? context.fetch(request) else { return [:] }

        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for entry in all {
            let weekday = calendar.component(.weekday, from: entry.playedAt)
            counts[weekday, default: 0] += 1
        }
        return counts
    }

    // MARK: - Helpers

    private func toEntry(_ entity: PlayHistoryEntity) -> PlayHistoryEntry {
        PlayHistoryEntry(
            id: entity.objectID,
            trackID: entity.trackID,
            title: entity.title,
            artistName: entity.artistName,
            albumTitle: entity.albumTitle,
            playedAt: entity.playedAt,
            duration: entity.duration,
            isLocalAsset: entity.isLocalAsset
        )
    }
}
