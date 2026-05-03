//
//  LibraryView.swift
//  MusicLibrary
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var searchHistory: SearchHistoryService

    @State private var isSearchActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タブ
                Picker("表示", selection: $libraryVM.selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if libraryVM.isLoading {
                    Spacer()
                    ProgressView("ライブラリを読み込み中...")
                    Spacer()
                } else if isSearching {
                    UnifiedSearchResultView(query: libraryVM.searchText)
                } else {
                    contentList
                }
            }
            .navigationTitle("ライブラリ")
            .toolbar { sortToolbar }
            .searchable(text: $libraryVM.searchText, prompt: "楽曲・アーティスト・アルバムを検索")
            .onSubmit(of: .search) {
                searchHistory.record(libraryVM.searchText)
            }
            .searchSuggestions {
                searchSuggestions
            }
        }
    }

    private var isSearching: Bool {
        !libraryVM.searchText.isEmpty
    }

    // MARK: - Sort toolbar

    @ToolbarContentBuilder
    private var sortToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                switch libraryVM.selectedTab {
                case .tracks:
                    Picker("ソート", selection: $libraryVM.trackSort) {
                        ForEach(TrackSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                case .artists:
                    Picker("ソート", selection: $libraryVM.artistSort) {
                        ForEach(CollectionSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                case .albums:
                    Picker("ソート", selection: $libraryVM.albumSort) {
                        ForEach(CollectionSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                case .favorites:
                    Picker("ソート", selection: $libraryVM.favoriteSort) {
                        ForEach(TrackSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
        }
    }

    // MARK: - 検索候補（履歴）

    @ViewBuilder
    private var searchSuggestions: some View {
        if libraryVM.searchText.isEmpty && !searchHistory.recentQueries.isEmpty {
            Section("最近の検索") {
                ForEach(searchHistory.recentQueries, id: \.self) { query in
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text(query)
                        Spacer()
                        Button {
                            searchHistory.remove(query)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .searchCompletion(query)
                }
            }
        }
    }

    // MARK: - コンテンツ一覧

    @ViewBuilder
    private var contentList: some View {
        List {
            switch libraryVM.selectedTab {
            case .tracks:
                ForEach(libraryVM.filteredTracks) { track in
                    NavigationLink {
                        TrackDetailView(track: track)
                    } label: {
                        TrackRowView(track: track)
                    }
                }
            case .artists:
                ForEach(libraryVM.filteredArtists) { artist in
                    NavigationLink {
                        ArtistDetailView(artist: artist)
                    } label: {
                        ArtistRowView(artist: artist)
                    }
                }
            case .albums:
                ForEach(libraryVM.filteredAlbums) { album in
                    NavigationLink {
                        AlbumDetailView(album: album)
                    } label: {
                        AlbumRowView(album: album)
                    }
                }
            case .favorites:
                FavoritesSection()
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - お気に入りセクション

private struct FavoritesSection: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var favoriteService: FavoriteService

    private var favoriteTracks: [Track] {
        let favorites = libraryVM.tracks.filter { favoriteService.isFavorite(trackID: $0.id) }
        return libraryVM.favoriteSort.sort(favorites)
    }

    var body: some View {
        if favoriteTracks.isEmpty {
            ContentUnavailableView(
                "お気に入りの楽曲がありません",
                systemImage: "heart.slash",
                description: Text("楽曲詳細画面でハートマークをタップしてお気に入り登録できます")
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
            ForEach(favoriteTracks) { track in
                NavigationLink {
                    TrackDetailView(track: track)
                } label: {
                    TrackRowView(track: track)
                }
            }
        }
    }
}

// MARK: - 統合検索結果

private struct UnifiedSearchResultView: View {
    let query: String
    @EnvironmentObject var libraryVM: LibraryViewModel

    private var result: UnifiedSearchResult {
        libraryVM.unifiedSearch(query: query)
    }

    var body: some View {
        if result.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List {
                if !result.artists.isEmpty {
                    Section {
                        ForEach(result.artists.prefix(5)) { artist in
                            NavigationLink {
                                ArtistDetailView(artist: artist)
                            } label: {
                                ArtistRowView(artist: artist)
                            }
                        }
                    } header: {
                        SearchSectionHeader(title: "アーティスト", count: result.artists.count)
                    }
                }

                if !result.albums.isEmpty {
                    Section {
                        ForEach(result.albums.prefix(5)) { album in
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                AlbumRowView(album: album)
                            }
                        }
                    } header: {
                        SearchSectionHeader(title: "アルバム", count: result.albums.count)
                    }
                }

                if !result.tracks.isEmpty {
                    Section {
                        ForEach(result.tracks.prefix(20)) { track in
                            NavigationLink {
                                TrackDetailView(track: track)
                            } label: {
                                TrackRowView(track: track)
                            }
                        }
                    } header: {
                        SearchSectionHeader(title: "楽曲", count: result.tracks.count)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

private struct SearchSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            Text("\(count)件")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 行ビュー（共通）

struct TrackRowView: View {
    let track: Track
    @EnvironmentObject var favoriteService: FavoriteService

    var body: some View {
        HStack(spacing: 12) {
            TrackArtworkView(track: track, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(track.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    if track.isLocalAsset {
                        Image(systemName: "opticaldisc")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    if favoriteService.isFavorite(trackID: track.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                    }
                }
                Text(track.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(track.playCount)回")
                .font(.caption)
                .foregroundStyle(.pink)
        }
        .padding(.vertical, 4)
    }
}

struct ArtistRowView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            ArtistArtworkView(artist: artist, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.subheadline.bold())
                Text("\(artist.trackCount)曲")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(artist.totalPlayCount)回")
                .font(.caption)
                .foregroundStyle(.pink)
        }
        .padding(.vertical, 4)
    }
}

struct AlbumRowView: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AlbumArtworkView(album: album, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(album.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(album.totalPlayCount)回")
                .font(.caption)
                .foregroundStyle(.pink)
        }
        .padding(.vertical, 4)
    }
}
