//
//  RankingView.swift
//  MusicLibrary
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject var rankingVM: RankingViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @FocusState private var isSearchFocused: Bool
    /// 行アニメーション基準時刻（表示直後の行のみアニメーション、スクロール先は即表示）
    @State private var rankingLoadTime: Date = Date()

    // MARK: - Filtered data

    private var filteredTracks: [Track] {
        guard !searchText.isEmpty else { return rankingVM.topTracks }
        let q = searchText.lowercased()
        return libraryVM.tracks.filter {
            $0.title.lowercased().hasPrefix(q) || $0.artistName.lowercased().hasPrefix(q)
        }.sorted { $0.playCount > $1.playCount }
    }

    private var filteredArtists: [Artist] {
        guard !searchText.isEmpty else { return rankingVM.topArtists }
        let q = searchText.lowercased()
        return libraryVM.artists.filter {
            $0.name.lowercased().hasPrefix(q)
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }

    private var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return rankingVM.topAlbums }
        let q = searchText.lowercased()
        return libraryVM.albums.filter {
            $0.title.lowercased().hasPrefix(q) || $0.artistName.lowercased().hasPrefix(q)
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("ランキング種別", selection: $rankingVM.rankingType) {
                    ForEach(RankingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if isSearchPresented {
                    searchBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    periodPicker
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollViewReader { proxy in
                    List {
                        switch rankingVM.rankingType {
                        case .tracks:
                            ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in
                                NavigationLink {
                                    TrackDetailView(track: track)
                                } label: {
                                    RankingRowView(rank: index + 1, track: track, loadTime: rankingLoadTime)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .id("row_\(index)")
                            }
                        case .artists:
                            ForEach(Array(filteredArtists.enumerated()), id: \.element.id) { index, artist in
                                NavigationLink {
                                    ArtistDetailView(artist: artist)
                                } label: {
                                    ArtistRankingRowView(rank: index + 1, artist: artist, loadTime: rankingLoadTime)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .id("row_\(index)")
                            }
                        case .albums:
                            ForEach(Array(filteredAlbums.enumerated()), id: \.element.id) { index, album in
                                NavigationLink {
                                    AlbumDetailView(album: album)
                                } label: {
                                    AlbumRankingRowView(rank: index + 1, album: album, loadTime: rankingLoadTime)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .id("row_\(index)")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 40, coordinateSpace: .local)
                            .onEnded { value in
                                guard !isSearchPresented else { return }
                                guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                                if value.translation.width < 0 {
                                    switchRankingType(by: 1)
                                } else {
                                    switchRankingType(by: -1)
                                }
                            }
                    )
                    .onChange(of: rankingVM.rankingType) { _, _ in
                        rankingLoadTime = Date()
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(50))
                            proxy.scrollTo("row_0", anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("ランキング")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isSearchPresented {
                        Button {
                            Haptics.play(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchPresented = true
                            }
                            isSearchFocused = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
            }
            .onChange(of: rankingVM.rankingPeriod) { _, _ in
                rankingVM.buildRanking(libraryTracks: libraryVM.tracks)
                rankingLoadTime = Date()
            }
            .onAppear {
                rankingLoadTime = Date()
            }
        }
    }

    private func switchRankingType(by offset: Int) {
        let types = RankingType.allCases
        guard let current = types.firstIndex(of: rankingVM.rankingType) else { return }
        let next = current + offset
        guard next >= 0 && next < types.count else { return }
        Haptics.play(.light)
        withAnimation(.easeInOut(duration: 0.2)) {
            rankingVM.rankingType = types[next]
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 15))

            TextField("楽曲・アーティスト・アルバムを検索", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Button("キャンセル") {
                Haptics.play(.light)
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearchPresented = false
                }
                isSearchFocused = false
                searchText = ""
            }
            .foregroundStyle(.pink)
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var periodPicker: some View {
        HStack {
            Text("期間")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("期間", selection: $rankingVM.rankingPeriod) {
                ForEach(RankingPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.menu)
            .tint(.pink)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
