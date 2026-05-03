//
//  MonthlySummaryWidget.swift
//  MusicLibraryWidget
//
//  「今月」= 1日0:00 〜 現在
//

import WidgetKit
import SwiftUI
import CoreData

struct MonthlySummaryEntry: TimelineEntry {
    let date: Date
    let totalCount: Int
    let topTracks: [(title: String, artist: String, count: Int)]
    let topArtists: [(name: String, count: Int)]
}

struct MonthlySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlySummaryEntry {
        MonthlySummaryEntry(
            date: Date(),
            totalCount: 234,
            topTracks: [
                ("夜に駆ける", "YOASOBI", 32),
                ("Pretender", "髭男", 28),
                ("炎", "LiSA", 22)
            ],
            topArtists: [("YOASOBI", 89), ("髭男", 67), ("LiSA", 45)]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlySummaryEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySummaryEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    /// 「今月」= 月初の0:00 〜 現在
    private func loadEntry() -> MonthlySummaryEntry {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let context = PersistenceController.shared.container.viewContext

        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(
            format: "playedAt >= %@ AND playedAt <= %@",
            startOfMonth as NSDate, now as NSDate
        )

        let entries = (try? context.fetch(request)) ?? []
        let totalCount = entries.count

        let trackGroups = Dictionary(grouping: entries, by: \.trackID)
        let topTracks = trackGroups
            .compactMap { _, list -> (String, String, Int)? in
                guard let first = list.first else { return nil }
                return (first.title, first.artistName, list.count)
            }
            .sorted { $0.2 > $1.2 }
            .prefix(3)
            .map { ($0.0, $0.1, $0.2) }

        let artistGroups = Dictionary(grouping: entries, by: \.artistName)
        let topArtists = artistGroups
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { ($0.0, $0.1) }

        return MonthlySummaryEntry(
            date: now,
            totalCount: totalCount,
            topTracks: Array(topTracks),
            topArtists: Array(topArtists)
        )
    }
}

struct MonthlySummaryWidgetView: View {
    let entry: MonthlySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS MONTH")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.pink)
                    Text("\(entry.totalCount)回再生")
                        .font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.pink.gradient)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("TOP TRACKS")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                ForEach(Array(entry.topTracks.enumerated()), id: \.offset) { index, track in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.pink)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(track.title)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(track.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.pink)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("TOP ARTISTS")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                ForEach(Array(entry.topArtists.enumerated()), id: \.offset) { index, artist in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.purple)
                            .frame(width: 14)
                        Text(artist.name)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Text("\(artist.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.purple)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(.systemBackground), Color.pink.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

struct MonthlySummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MonthlySummaryWidget", provider: MonthlySummaryProvider()) { entry in
            MonthlySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("月間サマリー")
        .description("今月の再生数とTOP3を表示")
        .supportedFamilies([.systemLarge])
    }
}
