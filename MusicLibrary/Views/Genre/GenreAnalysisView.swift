//
//  GenreAnalysisView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct GenreAnalysisView: View {
    @StateObject private var viewModel = GenreAnalysisViewModel()
    @EnvironmentObject var libraryVM: LibraryViewModel
    @State private var selectedGenre: GenreData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "ジャンル別再生分布")

            if viewModel.genreData.isEmpty {
                ContentUnavailableView(
                    "ジャンルデータがありません",
                    systemImage: "music.note.list"
                )
                .frame(height: 200)
            } else {
                // 円グラフ
                pieChart
                    .padding(.horizontal)

                // 凡例 + 詳細
                genreList
            }
        }
        .onAppear {
            viewModel.build(from: libraryVM.tracks)
        }
    }

    // MARK: - 円グラフ

    private var pieChart: some View {
        Chart(viewModel.genreData.prefix(10)) { data in
            SectorMark(
                angle: .value("回数", data.playCount),
                innerRadius: .ratio(0.55),
                angularInset: 2
            )
            .foregroundStyle(data.color)
            .opacity(selectedGenre == nil || selectedGenre?.id == data.id ? 1.0 : 0.3)
            .cornerRadius(4)
        }
        .frame(height: 240)
        .chartBackground { proxy in
            // 中央に総再生数を表示
            GeometryReader { geo in
                VStack(spacing: 2) {
                    Text(selectedGenre?.genre ?? "TOTAL")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(selectedGenre?.playCount ?? viewModel.totalPlayCount)")
                        .font(.title.bold())
                        .foregroundStyle(.pink)
                    Text("回")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }

    // MARK: - ジャンル一覧

    private var genreList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.genreData.prefix(10)) { data in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedGenre?.id == data.id {
                            selectedGenre = nil
                        } else {
                            selectedGenre = data
                        }
                    }
                } label: {
                    GenreRow(data: data, totalCount: viewModel.totalPlayCount, isSelected: selectedGenre?.id == data.id)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ジャンル行（折りたたみ可能）

private struct GenreRow: View {
    let data: GenreData
    let totalCount: Int
    let isSelected: Bool

    private var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(data.playCount) / Double(totalCount) * 100
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(data.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.genre)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("\(data.trackCount)曲")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(data.playCount)回")
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isSelected ? 90 : 0))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 代表アーティスト（展開時のみ）
            if isSelected && !data.topArtists.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("代表アーティスト")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    ForEach(Array(data.topArtists.enumerated()), id: \.element.id) { index, artist in
                        NavigationLink {
                            ArtistDetailView(artist: artist)
                        } label: {
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(data.color)
                                    .frame(width: 18)
                                ArtistArtworkView(artist: artist, size: 32)
                                Text(artist.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(artist.totalPlayCount)回")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
