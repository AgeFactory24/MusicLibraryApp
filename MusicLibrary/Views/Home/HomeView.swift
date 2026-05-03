//
//  HomeView.swift
//  MusicLibrary
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var rankingVM: RankingViewModel
    @EnvironmentObject var statsVM: StatisticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    if let stats = statsVM.stats {
                        SummarySection(stats: stats)
                    }

                    TopTracksSection(tracks: rankingVM.topTracks)

                    TopArtistsSection(artists: rankingVM.topArtists)
                }
                .padding(.vertical)
            }
            .navigationTitle("MusicLibrary")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct SummarySection: View {
    let stats: ListeningStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "リスニングサマリ")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCardView(title: "総再生回数", value: "\(stats.totalPlayCount)回",
                             icon: "play.fill", color: .pink)
                StatCardView(title: "総再生時間", value: stats.totalPlayTimeFormatted,
                             icon: "clock.fill", color: .orange)
                StatCardView(title: "アーティスト数", value: "\(stats.uniqueArtistCount)人",
                             icon: "music.mic", color: .purple)
                StatCardView(title: "CD取り込み曲", value: "\(stats.localAssetCount)曲",
                             icon: "opticaldisc", color: .blue)
            }
            .padding(.horizontal)
        }
    }
}

private struct TopTracksSection: View {
    let tracks: [Track]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "再生回数TOP5")

            VStack(spacing: 0) {
                ForEach(Array(tracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    NavigationLink {
                        TrackDetailView(track: track)
                    } label: {
                        RankingRowView(rank: index + 1, track: track)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < 4 { Divider().padding(.leading, 70) }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}

private struct TopArtistsSection: View {
    let artists: [Artist]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "トップアーティスト")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(artists.prefix(10).enumerated()), id: \.element.id) { index, artist in
                        NavigationLink {
                            ArtistDetailView(artist: artist)
                        } label: {
                            ArtistChipView(rank: index + 1, artist: artist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct ArtistChipView: View {
    let rank: Int
    let artist: Artist

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                ArtistArtworkView(artist: artist, size: 70)

                Text("#\(rank)")
                    .font(.caption2.bold())
                    .padding(4)
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Text(artist.name)
                .font(.caption.bold())
                .lineLimit(1)
                .frame(width: 80)

            Text("\(artist.totalPlayCount)回")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
