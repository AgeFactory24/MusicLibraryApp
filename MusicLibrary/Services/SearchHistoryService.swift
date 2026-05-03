//
//  SearchHistoryService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import CoreData
import Combine

@MainActor
final class SearchHistoryService: ObservableObject {

    @Published var recentQueries: [String] = []

    private let context: NSManagedObjectContext
    private let maxHistoryCount = 5

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        reload()
    }

    func reload() {
        let request = NSFetchRequest<SearchHistoryEntity>(entityName: "SearchHistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "searchedAt", ascending: false)]
        request.fetchLimit = maxHistoryCount

        guard let results = try? context.fetch(request) else { return }
        recentQueries = results.map(\.query)
    }

    /// 検索クエリを記録
    func record(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // 同じクエリが既にあれば削除（最新位置に再追加するため）
        let request = NSFetchRequest<SearchHistoryEntity>(entityName: "SearchHistoryEntity")
        request.predicate = NSPredicate(format: "query == %@", trimmed)

        if let existing = try? context.fetch(request) {
            existing.forEach { context.delete($0) }
        }

        // 新規追加
        let entity = SearchHistoryEntity(context: context)
        entity.query = trimmed
        entity.searchedAt = Date()

        try? context.save()

        // 上限超過分を削除
        trimToLimit()
        reload()
    }

    func remove(_ query: String) {
        let request = NSFetchRequest<SearchHistoryEntity>(entityName: "SearchHistoryEntity")
        request.predicate = NSPredicate(format: "query == %@", query)

        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
            try? context.save()
        }
        reload()
    }

    func clearAll() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SearchHistoryEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(deleteRequest)
        try? context.save()
        reload()
    }

    private func trimToLimit() {
        let request = NSFetchRequest<SearchHistoryEntity>(entityName: "SearchHistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "searchedAt", ascending: false)]

        guard let all = try? context.fetch(request) else { return }
        if all.count > maxHistoryCount {
            for entity in all[maxHistoryCount...] {
                context.delete(entity)
            }
            try? context.save()
        }
    }
}
