//
//  FavoriteService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import CoreData
import Combine

@MainActor
final class FavoriteService: ObservableObject {

    @Published private var favoriteIDs: Set<String> = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        reload()
    }

    /// 起動時/操作後に呼ぶ：お気に入りIDの一覧を再読込
    func reload() {
        let request = NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
        let results = (try? context.fetch(request)) ?? []
        favoriteIDs = Set(results.map(\.trackID))
    }

    /// お気に入り判定
    func isFavorite(trackID: String) -> Bool {
        favoriteIDs.contains(trackID)
    }

    /// お気に入りトグル
    func toggle(track: Track) {
        if isFavorite(trackID: track.id) {
            remove(trackID: track.id)
        } else {
            add(track: track)
        }
    }

    private func add(track: Track) {
        let entity = FavoriteEntity(context: context)
        entity.trackID = track.id
        entity.title = track.title
        entity.artistName = track.artistName
        entity.albumTitle = track.albumTitle
        entity.favoritedAt = Date()

        try? context.save()
        favoriteIDs.insert(track.id)
    }

    private func remove(trackID: String) {
        let request = NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
        request.predicate = NSPredicate(format: "trackID == %@", trackID)

        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
            try? context.save()
        }
        favoriteIDs.remove(trackID)
    }

    /// お気に入り済みの楽曲一覧を取得（Trackリストから絞り込み）
    func filteredFavorites(from tracks: [Track]) -> [Track] {
        tracks.filter { favoriteIDs.contains($0.id) }
              .sorted { $0.playCount > $1.playCount }
    }

    /// 全お気に入りエントリを取得（通知用：Trackリストと突合できないケース向け）
    func allFavorites() -> [(trackID: String, title: String, artistName: String)] {
        let request = NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "favoritedAt", ascending: false)]

        guard let results = try? context.fetch(request) else { return [] }
        return results.map { ($0.trackID, $0.title, $0.artistName) }
    }
}
