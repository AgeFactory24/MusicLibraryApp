//
//  NowPlayingActivityManager.swift
//  MusicLibrary
//
//  Live Activity / Dynamic Island 機能は無効化
//  （仕様変更により削除）
//

import Foundation

@MainActor
final class NowPlayingActivityManager {
    static let shared = NowPlayingActivityManager()

    private init() {}

    /// 何もしない（旧コード互換のため残置）
    func start() {
        // Live Activity 機能は削除されました
    }

    func stop() {
        // Live Activity 機能は削除されました
    }
}
