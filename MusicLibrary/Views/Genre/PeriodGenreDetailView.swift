//
//  PeriodGenreDetailView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct PeriodGenreDetailView: View {
    let genreData: [GenreData]
    let totalPlayCount: Int
    let title: String

    @State private var selectedGenre: GenreData?

    private var displayData: [GenreData] { Array(genreData.prefix(10)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pieChart
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(displayData) { data in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedGenre = selectedGenre?.id == data.id ? nil : data
                            }
                        } label: {
                            PeriodGenreRow(
                                data: data,
                                totalPlayCount: totalPlayCount,
                                isSelected: selectedGenre?.id == data.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pieChart: some View {
        Chart(displayData) { data in
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
        .chartBackground { _ in
            GeometryReader { geo in
                VStack(spacing: 2) {
                    Text(selectedGenre?.genre ?? "TOTAL")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(selectedGenre?.playCount ?? totalPlayCount)")
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
}

private struct PeriodGenreRow: View {
    let data: GenreData
    let totalPlayCount: Int
    let isSelected: Bool

    private var ratio: Double {
        guard totalPlayCount > 0 else { return 0 }
        return Double(data.playCount) / Double(totalPlayCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(data.color)
                        .frame(width: 12, height: 12)
                    Text(data.genre)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(data.playCount)回")
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                    Text(String(format: "%.1f%%", ratio * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isSelected ? 90 : 0))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(data.color.gradient)
                            .frame(width: max(geo.size.width * ratio, 4))
                    }
                }
                .frame(height: 6)
            }
            .padding()

            if isSelected && !data.topArtists.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("この期間の代表アーティスト")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(Array(data.topArtists.enumerated()), id: \.element.id) { index, artist in
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
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
