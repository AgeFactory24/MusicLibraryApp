//
//  StatisticsView.swift
//  MusicLibrary
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var statsVM: StatisticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let stats = statsVM.stats {
                        OverallStatsSection(stats: stats)
                        LocalVsStreamingSection(stats: stats)
                    }

                    if let track = statsVM.mostPlayedTrack {
                        MostPlayedTrackSection(track: track)
                    }

                    if let artist = statsVM.mostPlayedArtist {
                        MostPlayedArtistSection(artist: artist)
                    }

                    // ジャンル分析（NEW）
                    GenreAnalysisView()
                }
                .padding(.vertical)
            }
            .navigationTitle("統計")
        }
    }
}

private struct OverallStatsSection: View {
    let stats: ListeningStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "全体統計")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCardView(title: "総再生回数", value: "\(stats.totalPlayCount)回",
                             icon: "play.fill", color: .pink)
                StatCardView(title: "総再生時間", value: stats.totalPlayTimeFormatted,
                             icon: "clock.fill", color: .orange)
                StatCardView(title: "アーティスト数", value: "\(stats.uniqueArtistCount)人",
                             icon: "music.mic", color: .purple)
                StatCardView(title: "アルバム数", value: "\(stats.uniqueAlbumCount)枚",
                             icon: "square.stack", color: .teal)
            }
            .padding(.horizontal)
        }
    }
}

private struct LocalVsStreamingSection: View {
    let stats: ListeningStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "音源の内訳")
            HStack(spacing: 12) {
                StatCardView(
                    title: "CD取り込み",
                    value: "\(stats.localAssetCount)曲",
                    icon: "opticaldisc",
                    color: .blue
                )
                StatCardView(
                    title: "Apple Music",
                    value: "\(stats.streamingCount)曲",
                    icon: "applelogo",
                    color: .pink
                )
            }
            .padding(.horizontal)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.blue)
                        .frame(width: geo.size.width * stats.localAssetRatio)
                    Rectangle()
                        .fill(.pink)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .padding(.horizontal)
        }
    }
}

private struct MostPlayedTrackSection: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "最も聴いた楽曲")
            NavigationLink {
                TrackDetailView(track: track)
            } label: {
                HStack(spacing: 16) {
                    TrackArtworkView(track: track, size: 70)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(track.playCount)回再生")
                            .font(.subheadline.bold())
                            .foregroundStyle(.pink)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MostPlayedArtistSection: View {
    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "最も聴いたアーティスト")
            NavigationLink {
                ArtistDetailView(artist: artist)
            } label: {
                HStack(spacing: 16) {
                    ArtistArtworkView(artist: artist, size: 70)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(artist.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(artist.trackCount)曲")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(artist.totalPlayCount)回再生")
                            .font(.subheadline.bold())
                            .foregroundStyle(.pink)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }
}
