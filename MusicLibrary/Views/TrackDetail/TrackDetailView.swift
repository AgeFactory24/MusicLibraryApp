//
//  TrackDetailView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct TrackDetailView: View {
    let track: Track
    @StateObject private var viewModel = TrackDetailViewModel()
    @EnvironmentObject var favoriteService: FavoriteService

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 14) {
                    TrackArtworkView(track: track, size: 220, allowEdit: true)
                        .shadow(radius: 6)

                    VStack(spacing: 4) {
                        HStack {
                            Text(track.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                            if track.isLocalAsset {
                                Image(systemName: "opticaldisc")
                                    .foregroundStyle(.blue)
                            }
                        }
                        Text(track.artistName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(track.albumTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("画像を長押しで変更")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                if let data = viewModel.data {
                    HStack(spacing: 12) {
                        statBox(value: "\(track.playCount)", label: "総再生回数", color: .pink)
                        statBox(value: data.totalPlayTimeFormatted, label: "総再生時間", color: .orange)
                    }
                    .padding(.horizontal)

                    if let first = data.firstPlayedAt {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("初回再生: \(first.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    if !data.dailyCounts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("再生履歴")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart {
                                ForEach(data.dailyCounts.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                                    LineMark(
                                        x: .value("日付", date),
                                        y: .value("回数", count)
                                    )
                                    .foregroundStyle(.pink)
                                    .interpolationMethod(.catmullRom)

                                    PointMark(
                                        x: .value("日付", date),
                                        y: .value("回数", count)
                                    )
                                    .foregroundStyle(.pink)
                                }
                            }
                            .frame(height: 180)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }

                    if !data.history.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近の再生")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(Array(data.history.prefix(10))) { entry in
                                    HStack {
                                        Image(systemName: "play.fill")
                                            .font(.caption)
                                            .foregroundStyle(.pink)
                                        Text(entry.playedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    Divider()
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
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
