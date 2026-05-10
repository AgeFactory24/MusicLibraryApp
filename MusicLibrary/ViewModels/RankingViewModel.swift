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
    @Published var rankingPeriod: RankingPeriod = .allTime
    @Published var topTracks: [Track] = []
    @Published var topArtists: [Artist] = []
    @Published var topAlbums: [Album] = []

    private let service = MusicLibraryService()
    private let limit = 50

    func buildRanking(from tracks: [Track], artists: [Artist], albums: [Album]) {
        let filteredTracks: [Track]
        if let days = rankingPeriod.days {
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            filteredTracks = tracks.filter {
                guard let date = $0.lastPlayedDate else { return false }
                return date >= cutoff
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
