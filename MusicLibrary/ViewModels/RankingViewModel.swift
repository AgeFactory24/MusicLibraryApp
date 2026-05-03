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
    case allTime = "全期間"
    case recentMonth = "直近30日"
}

@MainActor
final class RankingViewModel: ObservableObject {
    @Published var rankingType: RankingType = .tracks
    @Published var rankingPeriod: RankingPeriod = .allTime
    @Published var topTracks: [Track] = []
    @Published var topArtists: [Artist] = []
    @Published var topAlbums: [Album] = []

    private let service = MusicLibraryService()
    private let limit = 50

    func buildRanking(from tracks: [Track], artists: [Artist], albums: [Album]) {
        let filteredTracks: [Track]
        if rankingPeriod == .recentMonth {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filteredTracks = tracks.filter {
                guard let date = $0.lastPlayedDate else { return false }
                return date >= thirtyDaysAgo
            }
        } else {
            filteredTracks = tracks
        }

        topTracks = Array(
            filteredTracks.sorted { $0.playCount > $1.playCount }.prefix(limit)
        )
        topArtists = Array(
            service.buildArtists(from: filteredTracks).prefix(limit)
        )
        topAlbums = Array(
            service.buildAlbums(from: filteredTracks).prefix(limit)
        )
    }
}
