// CDvsStreamingView.swift
// MusicLibrary

import SwiftUI

struct CDvsStreamingView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel

    private var localTracks: [Track] {
        libraryVM.tracks.filter { $0.isLocalAsset }.sorted { $0.playCount > $1.playCount }
    }

    private var streamingTracks: [Track] {
        libraryVM.tracks.filter { !$0.isLocalAsset }.sorted { $0.playCount > $1.playCount }
    }

    private var localPlayCount: Int { localTracks.reduce(0) { $0 + $1.playCount } }
    private var streamingPlayCount: Int { streamingTracks.reduce(0) { $0 + $1.playCount } }

    private var localPlayTime: TimeInterval {
        localTracks.reduce(0) { $0 + Double($1.playCount) * $1.duration }
    }
    private var streamingPlayTime: TimeInterval {
        streamingTracks.reduce(0) { $0 + Double($1.playCount) * $1.duration }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ratioBar
                comparisonCards
                topTracksSection(title: "CD取り込み TOP5", tracks: localTracks, color: .blue)
                topTracksSection(title: "Apple Music TOP5", tracks: streamingTracks, color: .pink)
            }
            .padding(.vertical)
        }
        .navigationTitle("CD vs Apple Music")
        .navigationBarTitleDisplayMode(.large)
    }

    private var ratioBar: some View {
        let total = localPlayCount + streamingPlayCount
        let localRatio = total > 0 ? Double(localPlayCount) / Double(total) : 0.5

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("再生数の比率", systemImage: "play.fill")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * localRatio)
                    Rectangle()
                        .fill(Color.pink)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
            .padding(.horizontal)

            HStack {
                Circle().fill(.blue).frame(width: 10, height: 10)
                Text("CD \(Int(localRatio * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Text("Apple Music \(Int((1 - localRatio) * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(.pink)
                Circle().fill(.pink).frame(width: 10, height: 10)
            }
            .padding(.horizontal)
        }
    }

    private var comparisonCards: some View {
        HStack(spacing: 12) {
            sourceCard(
                title: "CD取り込み",
                icon: "opticaldisc",
                color: .blue,
                trackCount: localTracks.count,
                playCount: localPlayCount,
                playTime: localPlayTime
            )
            sourceCard(
                title: "Apple Music",
                icon: "applelogo",
                color: .pink,
                trackCount: streamingTracks.count,
                playCount: streamingPlayCount,
                playTime: streamingPlayTime
            )
        }
        .padding(.horizontal)
    }

    private func sourceCard(
        title: String,
        icon: String,
        color: Color,
        trackCount: Int,
        playCount: Int,
        playTime: TimeInterval
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            Divider()
            statRow(label: "曲数", value: "\(trackCount)曲")
            statRow(label: "再生数", value: "\(playCount)回")
            statRow(label: "再生時間", value: formatTime(playTime))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
        }
    }

    private func topTracksSection(title: String, tracks: [Track], color: Color) -> some View {
        let top = Array(tracks.prefix(5))
        guard !top.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(Array(top.enumerated()), id: \.element.id) { index, track in
                        NavigationLink {
                            TrackDetailView(track: track)
                        } label: {
                            HStack(spacing: 12) {
                                Text(rankLabel(index))
                                    .font(.title3)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.subheadline.bold())
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                    Text(track.artistName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(track.playCount)回")
                                    .font(.caption.bold())
                                    .foregroundStyle(color)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        if index < top.count - 1 { Divider().padding(.leading, 56) }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        )
    }

    private func rankLabel(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)時間\(minutes)分" }
        return "\(minutes)分"
    }
}
