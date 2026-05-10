//
//  YearlyReportViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct YearlyReport {
    let year: Int
    let totalPlayCount: Int
    let totalPlayTime: TimeInterval
    let topTracks: [Track]
    let topArtists: [Artist]
    let topAlbums: [Album]
    let comparedToLastYear: Double
    let monthlyCounts: [Int: Int]
    let topMonth: TopMonth?
    let personality: ListenerPersonality
    let personalityReason: String
    let genreData: [GenreData]

    var yearLabel: String {
        "\(year)年"
    }

    var totalPlayTimeFormatted: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        if hours > 0 { return "\(hours)時間\(minutes)分" }
        return "\(minutes)分"
    }

    struct TopMonth {
        let month: Int
        let playCount: Int
        let topTrack: Track?
    }
}

struct ListenerPersonality {
    let title: String
    let description: String
    let emoji: String
    let gradient: [Color]
}

@MainActor
final class YearlyReportViewModel: ObservableObject {
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var report: YearlyReport?
    @Published var availableYears: [Int] = []

    private let repository = PlayHistoryRepository()

    /// 「今年」にリセット
    func resetToCurrent() {
        let currentYear = Calendar.current.component(.year, from: Date())
        if selectedYear != currentYear {
            selectedYear = currentYear
        }
    }

    func loadAvailableYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        availableYears = Array((currentYear - 3...currentYear).reversed())
    }

    func loadReport(libraryTracks: [Track] = []) {
        let calendar = Calendar.current
        guard let from = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
              let to = calendar.date(from: DateComponents(year: selectedYear + 1, month: 1, day: 1)) else {
            return
        }

        let history = repository.fetchHistory(from: from, to: to)

        let totalPlayCount = history.count
        let totalPlayTime = history.reduce(0) { $0 + $1.duration }

        let libraryMap = Dictionary(uniqueKeysWithValues: libraryTracks.map { ($0.id, $0) })

        // TOP楽曲
        let trackGroups = Dictionary(grouping: history, by: \.trackID)
        let topTracks = trackGroups
            .map { id, entries -> Track in
                let first = entries[0]
                return Track(
                    id: id, title: first.title,
                    artistName: first.artistName, albumTitle: first.albumTitle,
                    playCount: entries.count, duration: first.duration,
                    artworkURL: nil, isLocalAsset: first.isLocalAsset,
                    lastPlayedDate: entries.first?.playedAt,
                    genre: libraryMap[id]?.genre ?? "",
                    dateAdded: libraryMap[id]?.dateAdded
                )
            }
            .sorted { $0.playCount > $1.playCount }
            .prefix(10)

        let artistGroups = Dictionary(grouping: history, by: \.artistName)
        let topArtists = artistGroups
            .map { name, entries -> Artist in
                let tracks = Dictionary(grouping: entries, by: \.trackID)
                    .map { id, group -> Track in
                        let first = group[0]
                        return Track(
                            id: first.trackID, title: first.title,
                            artistName: first.artistName, albumTitle: first.albumTitle,
                            playCount: group.count, duration: first.duration,
                            artworkURL: nil, isLocalAsset: first.isLocalAsset,
                            lastPlayedDate: group.first?.playedAt,
                            genre: libraryMap[id]?.genre ?? "",
                            dateAdded: libraryMap[id]?.dateAdded
                        )
                    }
                return Artist(id: name, name: name, artworkURL: nil, tracks: tracks)
            }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
            .prefix(10)

        let albumGroups = Dictionary(grouping: history, by: \.albumTitle)
        let topAlbums = albumGroups
            .map { title, entries -> Album in
                let tracks = Dictionary(grouping: entries, by: \.trackID)
                    .map { id, group -> Track in
                        let first = group[0]
                        return Track(
                            id: first.trackID, title: first.title,
                            artistName: first.artistName, albumTitle: first.albumTitle,
                            playCount: group.count, duration: first.duration,
                            artworkURL: nil, isLocalAsset: first.isLocalAsset,
                            lastPlayedDate: group.first?.playedAt,
                            genre: libraryMap[id]?.genre ?? "",
                            dateAdded: libraryMap[id]?.dateAdded
                        )
                    }
                return Album(
                    id: title, title: title,
                    artistName: entries.first?.artistName ?? "",
                    artworkURL: nil, tracks: tracks
                )
            }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
            .prefix(10)

        let prevFrom = calendar.date(from: DateComponents(year: selectedYear - 1, month: 1, day: 1))!
        let prevTo = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let prevHistory = repository.fetchHistory(from: prevFrom, to: prevTo)

        let comparison: Double
        if prevHistory.isEmpty {
            comparison = 0
        } else {
            comparison = (Double(history.count) - Double(prevHistory.count)) / Double(prevHistory.count) * 100
        }

        var monthlyCounts: [Int: Int] = [:]
        var monthlyEntries: [Int: [PlayHistoryEntry]] = [:]
        for entry in history {
            let month = calendar.component(.month, from: entry.playedAt)
            monthlyCounts[month, default: 0] += 1
            monthlyEntries[month, default: []].append(entry)
        }

        let topMonth: YearlyReport.TopMonth?
        if let (month, entries) = monthlyEntries.max(by: { $0.value.count < $1.value.count }) {
            let trackCounts = Dictionary(grouping: entries, by: \.trackID)
            let topTrack = trackCounts
                .map { id, list -> Track in
                    let first = list[0]
                    return Track(
                        id: id, title: first.title,
                        artistName: first.artistName, albumTitle: first.albumTitle,
                        playCount: list.count, duration: first.duration,
                        artworkURL: nil, isLocalAsset: first.isLocalAsset,
                        lastPlayedDate: list.first?.playedAt,
                        genre: libraryMap[id]?.genre ?? "",
                        dateAdded: libraryMap[id]?.dateAdded
                    )
                }
                .max { $0.playCount < $1.playCount }

            topMonth = YearlyReport.TopMonth(month: month, playCount: entries.count, topTrack: topTrack)
        } else {
            topMonth = nil
        }

        let (personality, personalityReason) = calculatePersonality(history: history, libraryTracks: libraryTracks)
        let genreData = buildGenreData(history: history, libraryTracks: libraryTracks)

        report = YearlyReport(
            year: selectedYear,
            totalPlayCount: totalPlayCount,
            totalPlayTime: totalPlayTime,
            topTracks: Array(topTracks),
            topArtists: Array(topArtists),
            topAlbums: Array(topAlbums),
            comparedToLastYear: comparison,
            monthlyCounts: monthlyCounts,
            topMonth: topMonth,
            personality: personality,
            personalityReason: personalityReason,
            genreData: genreData
        )
    }

    private func buildGenreData(history: [PlayHistoryEntry], libraryTracks: [Track]) -> [GenreData] {
        PersonalityAnalysisEngine.buildGenreData(from: history, libraryTracks: libraryTracks)
    }

    private func calculatePersonality(
        history: [PlayHistoryEntry],
        libraryTracks: [Track]
    ) -> (ListenerPersonality, String) {
        let fallback = ListenerPersonality(
            title: "ニューカマー",
            description: "これから音楽の旅が始まります",
            emoji: "🎵",
            gradient: [.purple, .pink]
        )
        guard !history.isEmpty else { return (fallback, "") }
        let metrics = PersonalityAnalysisEngine.buildMetrics(from: history, libraryTracks: libraryTracks)
        let tags = PersonalityAnalysisEngine.evaluate(metrics: metrics, topCount: 1)
        guard let tag = tags.first else { return (fallback, "") }
        return (tag.personality.toListenerPersonality(), tag.reason)
    }
}
