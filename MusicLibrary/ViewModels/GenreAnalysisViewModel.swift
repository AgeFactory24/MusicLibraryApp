//
//  GenreAnalysisViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct GenreData: Identifiable {
    let id = UUID()
    let genre: String
    let playCount: Int
    let trackCount: Int
    let topArtists: [Artist]  // ジャンル代表アーティストTOP3
    let color: Color
}

@MainActor
final class GenreAnalysisViewModel: ObservableObject {
    @Published var genreData: [GenreData] = []
    @Published var totalPlayCount: Int = 0

    /// パステル系のカラーパレット（円グラフ用）
    private static let palette: [Color] = [
        .pink, .purple, .blue, .teal, .green,
        .yellow, .orange, .red, .indigo, .mint,
        .cyan, .brown
    ]

    func build(from tracks: [Track]) {
        // ジャンルごとに楽曲を集計
        let grouped = Dictionary(grouping: tracks, by: \.genre)

        let allData = grouped.map { genre, list -> GenreData in
            let playCount = list.reduce(0) { $0 + $1.playCount }

            // 代表アーティストTOP3（ジャンル内）
            let artistGroups = Dictionary(grouping: list, by: \.artistName)
            let artists = artistGroups
                .map { name, tracks in
                    Artist(id: name, name: name, artworkURL: nil, tracks: tracks)
                }
                .sorted { $0.totalPlayCount > $1.totalPlayCount }
                .prefix(3)

            return GenreData(
                genre: genre,
                playCount: playCount,
                trackCount: list.count,
                topArtists: Array(artists),
                color: .pink  // 後で割り当て
            )
        }
        .sorted { $0.playCount > $1.playCount }

        // カラーを割り当て
        genreData = allData.enumerated().map { index, data in
            GenreData(
                genre: data.genre,
                playCount: data.playCount,
                trackCount: data.trackCount,
                topArtists: data.topArtists,
                color: Self.palette[index % Self.palette.count]
            )
        }

        totalPlayCount = genreData.reduce(0) { $0 + $1.playCount }
    }
}
