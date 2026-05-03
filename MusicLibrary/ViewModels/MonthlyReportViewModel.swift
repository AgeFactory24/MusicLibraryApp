//
//  MonthlyReportViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct MonthlyReport {
    let year: Int
    let month: Int
    let totalPlayCount: Int
    let totalPlayTime: TimeInterval
    let topTracks: [Track]
    let topArtists: [Artist]
    let topAlbums: [Album]
    let comparedToLastMonth: Double
    let dailyCounts: [Int: Int]
    let personality: ListenerPersonality
    let genreData: [GenreData]
    let topDay: TopDay?

    var monthLabel: String {
        "\(year)年\(month)月"
    }

    var totalPlayTimeFormatted: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    /// 最も聴いた日（月別の場合は「日」、年間の場合は「月」に相当）
    struct TopDay {
        let day: Int
        let playCount: Int
        let topTrack: Track?
    }
}

@MainActor
final class MonthlyReportViewModel: ObservableObject {
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var report: MonthlyReport?

    private let repository = PlayHistoryRepository()

    func loadReport(libraryTracks: [Track] = []) {
        let calendar = Calendar.current
        guard let from = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let to = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: from) else {
            return
        }

        let history = repository.fetchHistory(from: from, to: to)

        let totalPlayCount = history.count
        let totalPlayTime = history.reduce(0) { $0 + $1.duration }

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
                    genre: "", dateAdded: nil
                )
            }
            .sorted { $0.playCount > $1.playCount }
            .prefix(10)

        // TOPアーティスト
        let artistGroups = Dictionary(grouping: history, by: \.artistName)
        let topArtists = artistGroups
            .map { name, entries -> Artist in
                let tracks = Dictionary(grouping: entries, by: \.trackID)
                    .map { _, group -> Track in
                        let first = group[0]
                        return Track(
                            id: first.trackID, title: first.title,
                            artistName: first.artistName, albumTitle: first.albumTitle,
                            playCount: group.count, duration: first.duration,
                            artworkURL: nil, isLocalAsset: first.isLocalAsset,
                            lastPlayedDate: group.first?.playedAt,
                            genre: "", dateAdded: nil
                        )
                    }
                return Artist(id: name, name: name, artworkURL: nil, tracks: tracks)
            }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
            .prefix(10)

        // TOPアルバム
        let albumGroups = Dictionary(grouping: history, by: \.albumTitle)
        let topAlbums = albumGroups
            .map { title, entries -> Album in
                let tracks = Dictionary(grouping: entries, by: \.trackID)
                    .map { _, group -> Track in
                        let first = group[0]
                        return Track(
                            id: first.trackID, title: first.title,
                            artistName: first.artistName, albumTitle: first.albumTitle,
                            playCount: group.count, duration: first.duration,
                            artworkURL: nil, isLocalAsset: first.isLocalAsset,
                            lastPlayedDate: group.first?.playedAt,
                            genre: "", dateAdded: nil
                        )
                    }
                return Album(
                    id: title,
                    title: title,
                    artistName: entries.first?.artistName ?? "",
                    artworkURL: nil,
                    tracks: tracks
                )
            }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
            .prefix(10)

        // 前月比較
        let prevDate = calendar.date(byAdding: .month, value: -1, to: from) ?? from
        let prevYear = calendar.component(.year, from: prevDate)
        let prevMonth = calendar.component(.month, from: prevDate)
        let prevFrom = calendar.date(from: DateComponents(year: prevYear, month: prevMonth, day: 1))!
        let prevTo = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: prevFrom)!
        let prevHistory = repository.fetchHistory(from: prevFrom, to: prevTo)

        let comparison: Double
        if prevHistory.isEmpty {
            comparison = 0
        } else {
            comparison = (Double(history.count) - Double(prevHistory.count)) / Double(prevHistory.count) * 100
        }

        // 日別再生数
        var dailyCounts: [Int: Int] = [:]
        var dailyEntries: [Int: [PlayHistoryEntry]] = [:]
        for entry in history {
            let day = calendar.component(.day, from: entry.playedAt)
            dailyCounts[day, default: 0] += 1
            dailyEntries[day, default: []].append(entry)
        }

        // 最も聴いた日
        let topDay: MonthlyReport.TopDay?
        if let (day, entries) = dailyEntries.max(by: { $0.value.count < $1.value.count }) {
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
                        genre: "", dateAdded: nil
                    )
                }
                .max { $0.playCount < $1.playCount }

            topDay = MonthlyReport.TopDay(day: day, playCount: entries.count, topTrack: topTrack)
        } else {
            topDay = nil
        }

        let personality = calculatePersonality(history: history)
        let genreData = buildGenreData(history: history, libraryTracks: libraryTracks)

        report = MonthlyReport(
            year: selectedYear,
            month: selectedMonth,
            totalPlayCount: totalPlayCount,
            totalPlayTime: totalPlayTime,
            topTracks: Array(topTracks),
            topArtists: Array(topArtists),
            topAlbums: Array(topAlbums),
            comparedToLastMonth: comparison,
            dailyCounts: dailyCounts,
            personality: personality,
            genreData: genreData,
            topDay: topDay
        )
    }

    // MARK: - ジャンル

    private static let palette: [Color] = [
        .pink, .purple, .blue, .teal, .green,
        .yellow, .orange, .red, .indigo, .mint
    ]

    private func buildGenreData(history: [PlayHistoryEntry], libraryTracks: [Track]) -> [GenreData] {
        let genreMap = Dictionary(uniqueKeysWithValues: libraryTracks.map { ($0.id, $0.genre) })

        var counts: [String: Int] = [:]
        for entry in history {
            let genre = genreMap[entry.trackID] ?? "その他"
            counts[genre, default: 0] += 1
        }

        let sorted = counts.sorted { $0.value > $1.value }

        return sorted.enumerated().map { index, pair -> GenreData in
            GenreData(
                genre: pair.key,
                playCount: pair.value,
                trackCount: 0,
                topArtists: [],
                color: Self.palette[index % Self.palette.count]
            )
        }
    }

    // MARK: - パーソナリティ

    private func calculatePersonality(history: [PlayHistoryEntry]) -> ListenerPersonality {
        guard !history.isEmpty else {
            return ListenerPersonality(
                title: "ニューカマー",
                description: "これから音楽の旅が始まります",
                emoji: "🎵",
                gradient: [.purple, .pink]
            )
        }

        let calendar = Calendar.current
        let totalPlays = history.count

        var hourCounts: [Int: Int] = [:]
        for entry in history {
            let hour = calendar.component(.hour, from: entry.playedAt)
            hourCounts[hour, default: 0] += 1
        }

        let morningCount = (5...10).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
        let dayCount = (11...17).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
        let eveningCount = (18...21).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
        let nightCount = (22...23).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
            + (0...4).reduce(0) { $0 + (hourCounts[$1] ?? 0) }

        let topTime = [
            ("morning", morningCount), ("day", dayCount),
            ("evening", eveningCount), ("night", nightCount)
        ].max(by: { $0.1 < $1.1 })?.0 ?? "day"

        let uniqueArtists = Set(history.map(\.artistName)).count
        let diversityRatio = Double(uniqueArtists) / Double(max(totalPlays, 1))
        let artistCounts = Dictionary(grouping: history, by: \.artistName).mapValues(\.count)
        let topArtistShare = Double(artistCounts.values.max() ?? 0) / Double(totalPlays)

        if topArtistShare > 0.4 {
            return ListenerPersonality(
                title: "推しが本気",
                description: "1人のアーティストを愛し抜く一途なリスナー",
                emoji: "💖",
                gradient: [.pink, .red]
            )
        }
        if diversityRatio > 0.5 {
            return ListenerPersonality(
                title: "音楽探検家",
                description: "新しい音楽を貪欲に探し続ける冒険者",
                emoji: "🗺",
                gradient: [.green, .teal]
            )
        }

        switch topTime {
        case "morning":
            return ListenerPersonality(title: "アーリーバード", description: "朝の時間に音楽を楽しむ早起きさん", emoji: "🌅", gradient: [.orange, .yellow])
        case "evening":
            return ListenerPersonality(title: "サンセット派", description: "夕暮れと共に音楽に浸るロマンチスト", emoji: "🌆", gradient: [.orange, .pink])
        case "night":
            return ListenerPersonality(title: "ナイトオウル", description: "夜の静けさに音楽が寄り添う深夜派", emoji: "🌙", gradient: [.indigo, .purple])
        default:
            return ListenerPersonality(title: "デイドリーマー", description: "日中ずっと音楽と共にある人", emoji: "☀️", gradient: [.cyan, .blue])
        }
    }
}
