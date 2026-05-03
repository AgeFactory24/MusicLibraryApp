//
//  WeeklyTopWidget.swift
//  MusicLibraryWidget
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Entry

struct WeeklyTopEntry: TimelineEntry {
    let date: Date
    let topTracks: [WeeklyTopTrack]
}

struct WeeklyTopTrack: Hashable {
    let title: String
    let artist: String
    let count: Int
}

// MARK: - Provider

struct WeeklyTopProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeeklyTopEntry {
        WeeklyTopEntry(date: Date(), topTracks: [
            WeeklyTopTrack(title: "夜に駆ける", artist: "YOASOBI", count: 12),
            WeeklyTopTrack(title: "Pretender", artist: "髭男", count: 8),
            WeeklyTopTrack(title: "炎", artist: "LiSA", count: 6)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyTopEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyTopEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> WeeklyTopEntry {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(format: "playedAt >= %@", weekAgo as NSDate)

        let entries = (try? context.fetch(request)) ?? []
        let grouped = Dictionary(grouping: entries, by: \.trackID)

        let top = grouped
            .compactMap { _, list -> WeeklyTopTrack? in
                guard let first = list.first else { return nil }
                return WeeklyTopTrack(
                    title: first.title,
                    artist: first.artistName,
                    count: list.count
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(3)

        return WeeklyTopEntry(date: Date(), topTracks: Array(top))
    }
}

// MARK: - Views

struct WeeklyTopWidgetView: View {
    let entry: WeeklyTopEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption.bold())
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2)
                Spacer()
            }
            .foregroundStyle(.pink)

            ForEach(Array(entry.topTracks.enumerated()), id: \.offset) { index, track in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.pink)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(track.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.pink)
                }
            }

            Spacer()
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget

struct WeeklyTopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeeklyTopWidget", provider: WeeklyTopProvider()) { entry in
            WeeklyTopWidgetView(entry: entry)
        }
        .configurationDisplayName("週間TOP3")
        .description("過去7日間のTOP3楽曲を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
