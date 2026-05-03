//
//  NowPlayingActivityAttributes.swift
//  MusicLibrary
//
//  Live Activity 共有定義（メインアプリ + Widget Extension 両方で使用）
//

import Foundation
import ActivityKit

struct NowPlayingActivityAttributes: ActivityAttributes {
    public typealias ContentState = NowPlayingState

    /// 楽曲固有情報（変更されない）
    let trackID: String
    let title: String
    let artistName: String

    /// 動的に変わる情報
    public struct NowPlayingState: Codable, Hashable {
        let totalPlayCount: Int   // 通算再生回数
        let monthlyPlayCount: Int // 今月の再生回数
        let isPlaying: Bool
    }
}
