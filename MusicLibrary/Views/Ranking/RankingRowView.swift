//
//  RankingRowView.swift
//  MusicLibrary
//

import SwiftUI

struct RankingRowView: View {
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

    var body: some View {
        HStack(spacing: 12) {
            Text(rankMedal)
                .font(rank <= 3 ? .title2 : .subheadline.bold())
                .foregroundStyle(rankColor)
                .frame(width: 32, alignment: .center)

            TrackArtworkView(track: track, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(track.artistName)
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
        // ※ onTapGesture は使わない（NavigationLink のタップを奪うため）
        // ハプティックは親View側のNavigationLinkで処理
    }

    private var rankMedal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

struct ArtistRankingRowView: View {
    let rank: Int
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            Text(rankMedal)
                .font(rank <= 3 ? .title2 : .subheadline.bold())
                .frame(width: 32, alignment: .center)

            ArtistArtworkView(artist: artist, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(artist.trackCount)曲")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(artist.totalPlayCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var rankMedal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

struct AlbumRankingRowView: View {
    let rank: Int
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            Text(rankMedal)
                .font(rank <= 3 ? .title2 : .subheadline.bold())
                .frame(width: 32, alignment: .center)

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

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(album.totalPlayCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var rankMedal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}
