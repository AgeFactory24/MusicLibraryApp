//
//  LibraryViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

enum LibraryTab: String, CaseIterable {
    case tracks = "楽曲"
    case artists = "アーティスト"
    case albums = "アルバム"
    case favorites = "お気に入り"
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var artists: [Artist] = []
    @Published var albums: [Album] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedTab: LibraryTab = .tracks

    // ソートオプション
    @Published var trackSort: TrackSortOption = .playCount
    @Published var artistSort: CollectionSortOption = .playCount
    @Published var albumSort: CollectionSortOption = .playCount
    @Published var favoriteSort: TrackSortOption = .playCount

    private let service = MusicLibraryService()

    // MARK: - 通常タブ用フィルタ + ソート

    var filteredTracks: [Track] {
        let base = tracks.filter(matchesSearch)
        return trackSort.sort(base)
    }

    var filteredArtists: [Artist] {
        let base = artists.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return artistSort.sortArtists(base)
    }

    var filteredAlbums: [Album] {
        let base = albums.filter {
            searchText.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artistName.localizedCaseInsensitiveContains(searchText)
        }
        return albumSort.sortAlbums(base)
    }

    private func matchesSearch(_ track: Track) -> Bool {
        guard !searchText.isEmpty else { return true }
        return track.title.localizedCaseInsensitiveContains(searchText) ||
               track.artistName.localizedCaseInsensitiveContains(searchText)
    }

    // MARK: - 統合検索（横断検索）

    /// 検索バーから3カテゴリ全部を検索
    func unifiedSearch(query: String) -> UnifiedSearchResult {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            return UnifiedSearchResult(tracks: [], artists: [], albums: [])
        }

        let matchTracks = tracks.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.artistName.localizedCaseInsensitiveContains(q) ||
            $0.albumTitle.localizedCaseInsensitiveContains(q)
        }
        .sorted { $0.playCount > $1.playCount }

        let matchArtists = artists.filter {
            $0.name.localizedCaseInsensitiveContains(q)
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }

        let matchAlbums = albums.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.artistName.localizedCaseInsensitiveContains(q)
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }

        return UnifiedSearchResult(
            tracks: matchTracks,
            artists: matchArtists,
            albums: matchAlbums
        )
    }

    // MARK: - ライブラリ読み込み

    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        let fetchedTracks = await service.fetchLocalTracks()
        tracks = fetchedTracks.sorted { $0.playCount > $1.playCount }
        artists = service.buildArtists(from: fetchedTracks)
        albums = service.buildAlbums(from: fetchedTracks)
    }
}

// MARK: - 統合検索結果

struct UnifiedSearchResult {
    let tracks: [Track]
    let artists: [Artist]
    let albums: [Album]

    var isEmpty: Bool {
        tracks.isEmpty && artists.isEmpty && albums.isEmpty
    }

    var totalCount: Int {
        tracks.count + artists.count + albums.count
    }
}
