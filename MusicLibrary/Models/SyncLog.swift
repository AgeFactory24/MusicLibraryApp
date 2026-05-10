//
//  SyncLog.swift
//  MusicLibrary
//

import Foundation

enum SyncTrigger: String, Codable {
    case initial    = "初回"
    case foreground = "FG復帰"
    case background = "BGTask"
    case widget     = "Widget"
    case manual     = "手動"

    var icon: String {
        switch self {
        case .initial:    return "📸"
        case .foreground: return "📱"
        case .background: return "⏰"
        case .widget:     return "🔲"
        case .manual:     return "🔧"
        }
    }
}

struct SyncLogEntry: Codable, Identifiable {
    var id: UUID = UUID()
    let date: Date
    let trigger: SyncTrigger
    let tracksScanned: Int
    let newHistoryCount: Int
    let durationSeconds: Double
}

struct SyncLogStore {
    static let key = "MusicLibrary.SyncLog"
    static let maxEntries = 100

    static func record(_ entry: SyncLogEntry) {
        var entries = load()
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [SyncLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([SyncLogEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
