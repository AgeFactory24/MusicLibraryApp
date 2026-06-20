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
        let grouped = Dictionary(grouping: tracks, by: \.albumTitle)
        return grouped.map { title, tracks in
            Album(
                id: title,
                title: title,
                artistName: tracks.first?.artistName ?? "",
                artworkURL: nil,
                tracks: tracks
            )
        }
        .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
