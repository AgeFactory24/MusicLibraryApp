//
//  ListeningProfile.swift
//  MusicLibrary
//

import Foundation

struct ListeningProfile: Codable {
    let version: Int
    let displayName: String
    let personalityType: String
    let topArtistNames: [String]
    let topGenres: [ProfileGenre]
    let cdRatio: Double
    let totalPlayCount: Int
    let generatedAt: Date
}

struct ProfileGenre: Codable {
    let name: String
    let ratio: Double
}

// MARK: - StoryReportData → ListeningProfile

extension StoryReportData {
    var cdRatio: Double {
        let total = topTracks.reduce(0) { $0 + $1.playCount }
        guard total > 0 else { return 0 }
        let local = topTracks.filter(\.isLocalAsset).reduce(0) { $0 + $1.playCount }
        return Double(local) / Double(total)
    }

    func toListeningProfile(displayName: String) -> ListeningProfile {
        let genres = genreData.prefix(5).map { g -> ProfileGenre in
            let ratio = totalPlayCount > 0 ? Double(g.playCount) / Double(totalPlayCount) : 0
            return ProfileGenre(name: g.genre, ratio: ratio)
        }
        return ListeningProfile(
            version: 1,
            displayName: displayName,
            personalityType: personality.title,
            topArtistNames: topArtists.prefix(5).map(\.name),
            topGenres: Array(genres),
            cdRatio: cdRatio,
            totalPlayCount: totalPlayCount,
            generatedAt: Date()
        )
    }
}
