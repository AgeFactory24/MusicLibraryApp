//
//  TrackDetailViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct TrackDetailData {
    let track: Track
    let history: [PlayHistoryEntry]
    let dailyCounts: [Date: Int]
    let firstPlayedAt: Date?
    let totalPlayTime: TimeInterval

    var totalPlayTimeFormatted: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        if hours > 0 { return "\(hours)時間\(minutes)分" }
        return "\(minutes)分"
    }
}

@MainActor
final class TrackDetailViewModel: ObservableObject {
    @Published var data: TrackDetailData?

    private let repository = PlayHistoryRepository()

    func load(track: Track) {
        let history = repository.fetchHistory(trackID: track.id)
        let calendar = Calendar.current

        var dailyCounts: [Date: Int] = [:]
        for entry in history {
            let startOfDay = calendar.startOfDay(for: entry.playedAt)
            dailyCounts[startOfDay, default: 0] += 1
        }

        // 履歴件数ではなくMPMediaItemの総再生回数で計算する
        // → 初回起動時でも正しい総再生時間が表示される
        let totalPlayTime = track.duration * Double(track.playCount)

        data = TrackDetailData(
            track: track,
            history: history,
            dailyCounts: dailyCounts,
            firstPlayedAt: history.last?.playedAt,
            totalPlayTime: totalPlayTime
        )
    }
}
