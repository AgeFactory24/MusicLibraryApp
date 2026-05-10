//
//  StatisticsViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine
// PersonalityAnalysisEngine を同モジュール内から参照

struct ListeningStats {
    let totalPlayCount: Int
    let totalPlayTimeSeconds: TimeInterval
    let uniqueArtistCount: Int
    let uniqueAlbumCount: Int
    let uniqueTrackCount: Int
    let localAssetCount: Int   // CD取り込み楽曲数（曲数ベース）
    let streamingCount: Int    // Apple Music配信楽曲数（曲数ベース）
    let localPlayCount: Int    // ローカル音源の総再生数（再生数ベース）

    var totalPlayTimeFormatted: String {
        let hours = Int(totalPlayTimeSeconds) / 3600
        let minutes = (Int(totalPlayTimeSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    /// 楽曲数ベースの比率（ライブラリ内の曲の何%がCD取り込みか）
    var localAssetRatio: Double {
        guard uniqueTrackCount > 0 else { return 0 }
        return Double(localAssetCount) / Double(uniqueTrackCount)
    }

    /// 再生数ベースの比率（総再生の何%がローカル音源か）— PersonalityAnalysisEngine と同一基準
    var localPlayRatio: Double {
        guard totalPlayCount > 0 else { return 0 }
        return Double(localPlayCount) / Double(totalPlayCount)
    }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var stats: ListeningStats?
    @Published var mostPlayedTrack: Track?
    @Published var mostPlayedArtist: Artist?
    @Published var monthlyPlayCounts: [String: Int] = [:]
    /// ホーム画面バッジ表示用：TOP1パーソナリティタグ
    @Published var topPersonalityTag: PersonalityTag?

    func buildStats(from tracks: [Track], artists: [Artist]) {
        let totalPlayCount = tracks.reduce(0) { $0 + $1.playCount }
        let totalPlayTime = tracks.reduce(0) { $0 + $1.totalPlayTime }
        let uniqueArtists = Set(tracks.map(\.artistName)).count
        let uniqueAlbums = Set(tracks.map(\.albumTitle)).count
        let localCount = tracks.filter(\.isLocalAsset).count
        let localPlayCount = tracks.filter(\.isLocalAsset).reduce(0) { $0 + $1.playCount }

        stats = ListeningStats(
            totalPlayCount: totalPlayCount,
            totalPlayTimeSeconds: totalPlayTime,
            uniqueArtistCount: uniqueArtists,
            uniqueAlbumCount: uniqueAlbums,
            uniqueTrackCount: tracks.count,
            localAssetCount: localCount,
            streamingCount: tracks.count - localCount,
            localPlayCount: localPlayCount
        )

        mostPlayedTrack = tracks.max(by: { $0.playCount < $1.playCount })
        mostPlayedArtist = artists.max(by: { $0.totalPlayCount < $1.totalPlayCount })

        buildMonthlyPlayCounts(from: tracks)

        if !tracks.isEmpty {
            let metrics = PersonalityAnalysisEngine.buildMetrics(from: tracks)
            topPersonalityTag = PersonalityAnalysisEngine.evaluate(metrics: metrics, topCount: 1).first
        }
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
