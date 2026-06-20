//
//  MusicLibraryService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import MusicKit
import MediaPlayer
import Combine

@MainActor
final class MusicLibraryService: ObservableObject {

    // MARK: - ローカルライブラリ取得

    func fetchLocalTracks() async -> [Track] {
        let query = MPMediaQuery.songs()
        guard let items = query.items else { return [] }

        return items.compactMap { item in
            guard let title = item.title, !title.isEmpty else { return nil }

            return Track(
                id: String(item.persistentID),
                title: title,
                artistName: item.artist ?? "不明なアーティスト",
                albumTitle: item.albumTitle ?? "不明なアルバム",
                playCount: item.playCount,
                duration: item.playbackDuration,
                artworkURL: nil,
                isLocalAsset: item.isLocalAsset,
                lastPlayedDate: item.lastPlayedDate,
                genre: item.genre ?? "その他",
                dateAdded: item.dateAdded
            )
        }
    }

    // MARK: - アーティスト単位で集計

    func buildArtists(from tracks: [Track]) -> [Artist] {
        let grouped = Dictionary(grouping: tracks, by: \.artistName)
        return grouped.map { name, tracks in
            Artist(id: name, name: name, artworkURL: nil, tracks: tracks)
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }

    // MARK: - アルバム単位で集計

    func buildAlbums(from tracks: [Track]) -> [Album] {
        // アルバムタイトルだけでグループ化すると、同名アルバムが異アーティストで混在してジャケ写が混入するため
        // albumTitle + artistName の複合キーで一意に識別する
        let grouped = Dictionary(grouping: tracks) { "\($0.albumTitle)//\($0.artistName)" }
        return grouped.map { _, albumTracks in
            let first = albumTracks[0]
            return Album(
                id: "\(first.albumTitle)//\(first.artistName)",
                title: first.albumTitle,
                artistName: first.artistName,
                artworkURL: nil,
                tracks: albumTracks
            )
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
