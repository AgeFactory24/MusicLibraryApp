//
//  Artist.swift
//  MusicLibrary
//

import Foundation

struct Artist: Identifiable, Hashable {
    let id: String
    let name: String
    let artworkURL: URL?
    var tracks: [Track]

    var totalPlayCount: Int {
        tracks.reduce(0) { $0 + $1.playCount }
    }

    var totalPlayTime: TimeInterval {
        tracks.reduce(0) { $0 + $1.totalPlayTime }
    }

    var trackCount: Int {
        tracks.count
    }
}
