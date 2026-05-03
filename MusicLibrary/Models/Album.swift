//
//  Album.swift
//  MusicLibrary
//

import Foundation

struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: URL?
    var tracks: [Track]

    var totalPlayCount: Int {
        tracks.reduce(0) { $0 + $1.playCount }
    }

    var trackCount: Int {
        tracks.count
    }
}
