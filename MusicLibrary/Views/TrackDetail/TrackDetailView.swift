//
//  TrackDetailView.swift
//  MusicLibrary
//

import SwiftUI

struct TrackDetailView: View {
    let track: Track
    @StateObject private var viewModel = TrackDetailViewModel()
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var libraryVM: LibraryViewModel

    private var libraryRank: Int? {
        let sorted = libraryVM.tracks.sorted { $0.playCount > $1.playCount }
        guard let idx = sorted.firstIndex(where: { $0.id == track.id }) else { return nil }
        return idx + 1
    }

    private var artistForDetail: Artist? {
        let artistTracks = libraryVM.tracks.filter { $0.artistName == track.artistName }
        guard !artistTracks.isEmpty else { return nil }
        return Artist(id: track.artistName, name: track.artistName, artworkURL: nil, tracks: artistTracks)
    }

    private var albumForDetail: Album? {
        if let found = libraryVM.albums.first(where: {
            $0.title == track.albumTitle && $0.artistName == track.artistName
        }) { return found }
        let albumTracks = libraryVM.tracks.filter {
            $0.albumTitle == track.albumTitle && $0.artistName == track.artistName
        }
        guard !albumTracks.isEmpty else { return nil }
        return Album(id: track.albumTitle, title: track.albumTitle,
                     artistName: track.artistName, artworkURL: nil, tracks: albumTracks)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // アートワーク・タイトル
                VStack(spacing: 14) {
                    TrackArtworkView(track: track, size: 220, allowEdit: true)
                        .shadow(radius: 6)

                    VStack(spacing: 4) {
                        Text(track.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        if let artist = artistForDetail {
                            NavigationLink {
                                ArtistDetailView(artist: artist)
                            } label: {
                                Text(track.artistName)
                                    .font(.headline)
                                    .foregroundStyle(.pink)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(track.artistName)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }

                        if let album = albumForDetail {
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                Text(track.albumTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.pink.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(track.albumTitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                }
                .padding(.top)

                if let data = viewModel.data {
                    // 再生統計
                    HStack(spacing: 12) {
                        statBox(value: "\(track.playCount)", label: "総再生回数", color: .pink)
                        statBox(value: data.totalPlayTimeFormatted, label: "総再生時間", color: .orange)
                    }
                    .padding(.horizontal)

                    // ライブラリ内ランキング
                    if let rank = libraryRank {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.pink)
                            Text("ライブラリ内ランキング")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("#\(rank)位")
                                .font(.subheadline.bold())
                                .foregroundStyle(.pink)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // 楽曲情報
                    trackInfoCard


                }
            }
            .padding(.vertical)
        }
        .navigationTitle("楽曲詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton
            }
        }
        .onAppear { viewModel.load(track: track) }
    }

    // MARK: - 楽曲情報カード

    private var trackInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("楽曲情報")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                infoRow(label: "曲の長さ", value: track.formattedDuration, icon: "clock")
                Divider().padding(.leading, 16)
                infoRow(label: "ジャンル",
                        value: track.genre.isEmpty ? "不明" : track.genre,
                        icon: "music.note")
                Divider().padding(.leading, 16)
                infoRow(label: "音源種別",
                        value: track.isLocalAsset ? "CD取り込み" : "Apple Music",
                        icon: track.isLocalAsset ? "opticaldisc" : "applelogo")
                if let added = track.dateAdded {
                    Divider().padding(.leading, 16)
                    infoRow(label: "ライブラリ追加日",
                            value: Self.dateFormatter.string(from: added),
                            icon: "plus.circle")
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
    }

    // MARK: - サブビュー

    private var favoriteButton: some View {
        Button {
            Haptics.play(.medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoriteService.toggle(track: track)
            }
        } label: {
            Image(systemName: favoriteService.isFavorite(trackID: track.id) ? "heart.fill" : "heart")
                .symbolEffect(.bounce, value: favoriteService.isFavorite(trackID: track.id))
                .foregroundStyle(.pink)
                .font(.title3)
        }
    }

    private func statBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
