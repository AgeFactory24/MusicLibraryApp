//
//  AlbumDetailView.swift
//  MusicLibrary
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @EnvironmentObject var libraryVM: LibraryViewModel

    private var topTracks: [Track] {
        album.tracks.sorted { $0.playCount > $1.playCount }
    }

    private var artistForDetail: Artist? {
        let tracks = libraryVM.tracks.filter { $0.artistName == album.artistName }
        guard !tracks.isEmpty else { return nil }
        return Artist(id: album.artistName, name: album.artistName, artworkURL: nil, tracks: tracks)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                headerSection

                // 統計カード
                statsSection

                // 楽曲ランキング
                tracksSection
            }
            .padding(.vertical)
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            AlbumArtworkView(album: album, size: 220, allowEdit: true)
                .shadow(radius: 6)

            VStack(spacing: 4) {
                Text(album.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                if let artist = artistForDetail {
                    NavigationLink {
                        ArtistDetailView(artist: artist)
                    } label: {
                        Text(album.artistName)
                            .font(.headline)
                            .foregroundStyle(.pink)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(album.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

        }
        .padding(.top)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statBox(value: "\(album.totalPlayCount)", label: "総再生回数", color: .pink)
            statBox(value: "\(album.trackCount)", label: "楽曲数", color: .purple)
        }
        .padding(.horizontal)
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

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "楽曲ランキング")

            VStack(spacing: 0) {
                ForEach(Array(topTracks.enumerated()), id: \.element.id) { index, track in
                    NavigationLink {
                        TrackDetailView(track: track)
                    } label: {
                        TrackRankingRow(rank: index + 1, track: track)
                    }
                    .buttonStyle(.plain)
                    if index < topTracks.count - 1 {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}
