//
//  StatisticsViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct ListeningStats {
    let totalPlayCount: Int
    let totalPlayTimeSeconds: TimeInterval
    let uniqueArtistCount: Int
    let uniqueAlbumCount: Int
    let uniqueTrackCount: Int
    let localAssetCount: Int   // CD取り込み楽曲数
    let streamingCount: Int    // Apple Music配信楽曲数

    var totalPlayTimeFormatted: String {
        let hours = Int(totalPlayTimeSeconds) / 3600
        let minutes = (Int(totalPlayTimeSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var localAssetRatio: Double {
        guard uniqueTrackCount > 0 else { return 0 }
        return Double(localAssetCount) / Double(uniqueTrackCount)
    }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var stats: ListeningStats?
    @Published var mostPlayedTrack: Track?
    @Published var mostPlayedArtist: Artist?
    @Published var monthlyPlayCounts: [String: Int] = [:]

    func buildStats(from tracks: [Track], artists: [Artist]) {
        let totalPlayCount = tracks.reduce(0) { $0 + $1.playCount }
        let totalPlayTime = tracks.reduce(0) { $0 + $1.totalPlayTime }
        let uniqueArtists = Set(tracks.map(\.artistName)).count
        let uniqueAlbums = Set(tracks.map(\.albumTitle)).count
        let localCount = tracks.filter(\.isLocalAsset).count

        stats = ListeningStats(
            totalPlayCount: totalPlayCount,
            totalPlayTimeSeconds: totalPlayTime,
            uniqueArtistCount: uniqueArtists,
            uniqueAlbumCount: uniqueAlbums,
            uniqueTrackCount: tracks.count,
            localAssetCount: localCount,
            streamingCount: tracks.count - localCount
        )

        mostPlayedTrack = tracks.max(by: { $0.playCount < $1.playCount })
        mostPlayedArtist = artists.max(by: { $0.totalPlayCount < $1.totalPlayCount })

        buildMonthlyPlayCounts(from: tracks)
    }

    private func buildMonthlyPlayCounts(from tracks: [Track]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"

        var counts: [String: Int] = [:]
        for track in tracks {
            guard let date = track.lastPlayedDate else { continue }
            let key = formatter.string(from: date)
            counts[key, default: 0] += track.playCount
        }
        monthlyPlayCounts = counts
    }
}
