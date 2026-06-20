//
//  RankingRowView.swift
//  MusicLibrary
//

import SwiftUI

// アニメーション対象ウィンドウ（ロードから1.2秒以内に現れた行のみアニメーション）
private let kAnimationWindow: TimeInterval = 1.2

// MARK: - 楽曲ランキング行

struct RankingRowView: View {
    let rank: Int
    let track: Track
    let loadTime: Date

    @State private var appeared = false

    private var delay: Double { Double(min(rank - 1, 20)) * 0.028 }

    var rankColor: Color {
        switch rank {
        case 1: return AppTheme.Colors.rankGold
        case 2: return AppTheme.Colors.rankSilver
        case 3: return AppTheme.Colors.rankBronze
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
                    .foregroundStyle(AppTheme.Colors.plays)
                    .scaleEffect(appeared ? 1 : 0.6)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -28)
        .onAppear {
            guard !appeared else { return }
            let elapsed = Date().timeIntervalSince(loadTime)
            if elapsed < kAnimationWindow {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            } else {
                appeared = true  // スクロール先は即表示（アニメなし）
            }
        }
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

// MARK: - アーティストランキング行

struct ArtistRankingRowView: View {
    let rank: Int
    let artist: Artist
    let loadTime: Date

    @State private var appeared = false

    private var delay: Double { Double(min(rank - 1, 20)) * 0.028 }

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
                    .foregroundStyle(AppTheme.Colors.plays)
                    .scaleEffect(appeared ? 1 : 0.6)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -28)
        .onAppear {
            guard !appeared else { return }
            let elapsed = Date().timeIntervalSince(loadTime)
            if elapsed < kAnimationWindow {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
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

// MARK: - アルバムランキング行

struct AlbumRankingRowView: View {
    let rank: Int
    let album: Album
    let loadTime: Date

    @State private var appeared = false

    private var delay: Double { Double(min(rank - 1, 20)) * 0.028 }

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
                    .foregroundStyle(AppTheme.Colors.plays)
                    .scaleEffect(appeared ? 1 : 0.6)
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -28)
        .onAppear {
            guard !appeared else { return }
            let elapsed = Date().timeIntervalSince(loadTime)
            if elapsed < kAnimationWindow {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
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
