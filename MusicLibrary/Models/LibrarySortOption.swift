//
//  LibrarySortOption.swift
//  MusicLibrary
//

import Foundation

enum TrackSortOption: String, CaseIterable, Identifiable {
    case playCount = "再生回数順"
    case title = "タイトル順"
    case lastPlayed = "最近聴いた順"
    case dateAdded = "追加日順"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .playCount: return "play.fill"
        case .title: return "textformat"
        case .lastPlayed: return "clock.fill"
        case .dateAdded: return "calendar.badge.plus"
        }
    }

    func sort(_ tracks: [Track]) -> [Track] {
        switch self {
        case .playCount:
            return tracks.sorted { $0.playCount > $1.playCount }
        case .title:
            return tracks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .lastPlayed:
            return tracks.sorted {
                ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast)
            }
        case .dateAdded:
            return tracks.sorted {
                ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast)
            }
        }
    }
}

enum CollectionSortOption: String, CaseIterable, Identifiable {
    case playCount = "再生回数順"
    case name = "名前順"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .playCount: return "play.fill"
        case .name: return "textformat"
        }
    }

    func sortArtists(_ artists: [Artist]) -> [Artist] {
        switch self {
        case .playCount:
            return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return artists.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    func sortAlbums(_ albums: [Album]) -> [Album] {
        switch self {
        case .playCount:
            return albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return albums.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
}
