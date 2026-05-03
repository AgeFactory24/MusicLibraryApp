//
//  WeeklyTopWidget.swift
//  MusicLibraryWidget
//
//  「今週」= 今週月曜0:00 〜 現在
//

import WidgetKit
import SwiftUI
import CoreData

struct WeeklyTopEntry: TimelineEntry {
    let date: Date
    let topTracks: [WeeklyTopTrack]
}

struct WeeklyTopTrack: Hashable {
    let title: String
    let artist: String
    let count: Int
}

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

    /// 「今週」= 月曜0:00 〜 現在
    private func loadEntry() -> WeeklyTopEntry {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // 月曜始まり

        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(
            format: "playedAt >= %@ AND playedAt <= %@",
            startOfWeek as NSDate, now as NSDate
        )

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

        return WeeklyTopEntry(date: now, topTracks: Array(top))
    }
}

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

            if entry.topTracks.isEmpty {
                Spacer()
                Text("再生なし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
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
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct WeeklyTopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeeklyTopWidget", provider: WeeklyTopProvider()) { entry in
            WeeklyTopWidgetView(entry: entry)
        }
        .configurationDisplayName("今週TOP3")
        .description("今週の月曜以降のTOP3楽曲を表示")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
