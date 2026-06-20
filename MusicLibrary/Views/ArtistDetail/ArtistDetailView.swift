//
//  ArtistDetailView.swift
//  MusicLibrary
//

import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist

    @EnvironmentObject var artworkService: ArtworkService

    // このアーティストに属するアルバムを集計
    private var albums: [Album] {
        let grouped = Dictionary(grouping: artist.tracks, by: \.albumTitle)
        return grouped.map { title, tracks in
            Album(
                id: "\(artist.name)__\(title)",
                title: title,
                artistName: artist.name,
                artworkURL: nil,
                tracks: tracks
            )
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }

    // アーティストの全楽曲ランキング
    private var topTracks: [Track] {
        artist.tracks.sorted { $0.playCount > $1.playCount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                headerSection

                // 統計カード
                statsSection

                // アルバム一覧
                albumsSection

                // 楽曲ランキング
                tracksSection
            }
            .padding(.vertical)
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ArtistArtworkView(artist: artist, size: 180, allowEdit: true)
                .shadow(radius: 4)

            Text(artist.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

        }
        .padding(.top)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statBox(value: "\(artist.totalPlayCount)", label: "総再生回数", color: .pink)
            statBox(value: "\(artist.trackCount)", label: "楽曲数", color: .purple)
            statBox(value: "\(albums.count)", label: "アルバム数", color: .teal)
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

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "アルバム")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                        NavigationLink {
                            AlbumDetailView(album: album)
                        } label: {
                            AlbumCardView(rank: index + 1, album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
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

// MARK: - アルバムカード（横スクロール用）

struct AlbumCardView: View {
    let rank: Int
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                AlbumArtworkView(album: album, size: 140)
                    .shadow(radius: 2)

                Text("#\(rank)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(6)
            }

            Text(album.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            Text("\(album.totalPlayCount)回 ・ \(album.trackCount)曲")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 楽曲ランキング行（共通化）

struct TrackRankingRow: View {
    let rank: Int
    let track: Track

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
        default: return .primary
        }
    }

    var rankLabel: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(rankLabel)
                .font(rank <= 3 ? .title3 : .subheadline.bold())
                .foregroundStyle(rankColor)
                .frame(width: 32, alignment: .center)

            TrackArtworkView(track: track, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    if track.isLocalAsset {
                        Image(systemName: "opticaldisc")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                Text(track.albumTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(track.playCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}
