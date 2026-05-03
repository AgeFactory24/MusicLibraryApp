//
//  Track.swift
//  MusicLibrary
//

import Foundation

struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String
    let playCount: Int
    let duration: TimeInterval
    let artworkURL: URL?
    let isLocalAsset: Bool
    let lastPlayedDate: Date?
    let genre: String         // ジャンル分析用（NEW）
    let dateAdded: Date?      // 追加日順ソート用（NEW）

    var totalPlayTime: TimeInterval {
        duration * Double(playCount)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
