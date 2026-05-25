//
//  RankingViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

enum RankingType: String, CaseIterable {
    case tracks = "楽曲"
    case artists = "アーティスト"
    case albums = "アルバム"
}

enum RankingPeriod: String, CaseIterable {
    case allTime      = "全期間"
    case recentWeek   = "7日"
    case recentMonth  = "30日"
    case recent3Month = "3ヶ月"

    var days: Int? {
        switch self {
        case .allTime:      return nil
        case .recentWeek:   return 7
        case .recentMonth:  return 30
        case .recent3Month: return 90
        }
    }
}

@MainActor
final class RankingViewModel: ObservableObject {
    @Published var rankingType: RankingType = .tracks
    @Published var rankingPeriod: RankingPeriod = .recentWeek
    @Published var topTracks: [Track] = []
    @Published var topArtists: [Artist] = []
    @Published var topAlbums: [Album] = []

    // ホーム画面用（ランキング画面と独立）
    @Published var homeRankingPeriod: RankingPeriod = .recentWeek
    @Published var homeTopTracks: [Track] = []
    @Published var homeTopArtists: [Artist] = []
    @Published var homePersonalityTag: PersonalityTag?

    private let service = MusicLibraryService()
    private let repository = PlayHistoryRepository()
    private let limit = 50

    // MARK: - ランキング画面用

    func buildRanking(libraryTracks: [Track]) {
        let result = buildRankingData(period: rankingPeriod, libraryTracks: libraryTracks)
        topTracks = result.tracks
        topArtists = result.artists
        topAlbums = result.albums
    }

    // MARK: - ホーム画面用

    func buildHomeRanking(libraryTracks: [Track]) {
        let data = buildRankingData(period: homeRankingPeriod, libraryTracks: libraryTracks)
        homeTopTracks = Array(data.tracks.prefix(5))
        homeTopArtists = Array(data.artists.prefix(10))

        let analysisSource = homeRankingPeriod == .allTime ? libraryTracks : data.tracks
        if !analysisSource.isEmpty {
            let metrics = PersonalityAnalysisEngine.buildMetrics(from: analysisSource)
            homePersonalityTag = PersonalityAnalysisEngine.evaluate(metrics: metrics, topCount: 1).first
        } else {
            homePersonalityTag = nil
        }
    }

    // MARK: - 共通ロジック

    private func buildRankingData(
        period: RankingPeriod,
        libraryTracks: [Track]
    ) -> (tracks: [Track], artists: [Artist], albums: [Album]) {
        // 全期間はApple Musicの累積再生数をそのまま使用
        if period == .allTime {
            let sorted = libraryTracks.sorted { $0.playCount > $1.playCount }
            return (
                tracks:  Array(sorted.prefix(limit)),
                artists: Array(service.buildArtists(from: libraryTracks).prefix(limit)),
                albums:  Array(service.buildAlbums(from: libraryTracks).prefix(limit))
            )
        }

        // 7日 / 30日 / 3ヶ月: アプリが記録した再生履歴を集計
        let days = period.days!
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let history = repository.fetchHistory(from: cutoff, to: Date())

        let periodTracks = buildTracksFromHistory(history, libraryTracks: libraryTracks)
        return (
            tracks:  Array(periodTracks.prefix(limit)),
            artists: Array(service.buildArtists(from: periodTracks).prefix(limit)),
            albums:  Array(service.buildAlbums(from: periodTracks).prefix(limit))
        )
    }

    private func buildTracksFromHistory(
        _ history: [PlayHistoryEntry],
        libraryTracks: [Track]
    ) -> [Track] {
        let libraryMap = Dictionary(uniqueKeysWithValues: libraryTracks.map { ($0.id, $0) })
        return Dictionary(grouping: history, by: \.trackID)
            .map { id, entries -> Track in
                let first = entries[0]
                return Track(
                    id: id,
                    title: first.title,
                    artistName: first.artistName,
                    albumTitle: first.albumTitle,
                    playCount: entries.count,
                    duration: first.duration,
                    artworkURL: nil,
                    isLocalAsset: first.isLocalAsset,
                    lastPlayedDate: entries.first?.playedAt,
                    genre: libraryMap[id]?.genre ?? "",
                    dateAdded: libraryMap[id]?.dateAdded
                )
            }
            .sorted { $0.playCount > $1.playCount }
    }
}
