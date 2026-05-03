//
//  TodayPlaysWidget.swift
//  MusicLibraryWidget
//

import WidgetKit
import SwiftUI
import CoreData

struct TodayPlaysEntry: TimelineEntry {
    let date: Date
    let playCount: Int
    let topTrackTitle: String
    let topArtistName: String
}

struct TodayPlaysProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodayPlaysEntry {
        TodayPlaysEntry(
            date: Date(),
            playCount: 23,
            topTrackTitle: "夜に駆ける",
            topArtistName: "YOASOBI"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayPlaysEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayPlaysEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// 「今日」= 今日の00:00 〜 現在
    private func loadEntry() -> TodayPlaysEntry {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let context = PersistenceController.shared.container.viewContext

        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        request.predicate = NSPredicate(
            format: "playedAt >= %@ AND playedAt <= %@",
            startOfDay as NSDate, now as NSDate
        )

        let entries = (try? context.fetch(request)) ?? []
        let count = entries.count

        let grouped = Dictionary(grouping: entries, by: \.trackID)
        let top = grouped.max(by: { $0.value.count < $1.value.count })?.value.first

        return TodayPlaysEntry(
            date: now,
            playCount: count,
            topTrackTitle: top?.title ?? "再生なし",
            topArtistName: top?.artistName ?? ""
        )
    }
}

struct TodayPlaysWidgetView: View {
    let entry: TodayPlaysEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "music.note")
                    .font(.caption.bold())
                Text("TODAY")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2)
                Spacer()
            }
            .foregroundStyle(.pink)

            Spacer()

            Text("\(entry.playCount)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("回再生")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(.systemBackground), Color.pink.opacity(0.1)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.pink)
                Text("\(entry.playCount)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("回再生")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("もっとも聴いた曲")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.topTrackTitle)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(entry.topArtistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(.systemBackground), Color.pink.opacity(0.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

struct TodayPlaysWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayPlaysWidget", provider: TodayPlaysProvider()) { entry in
            TodayPlaysWidgetView(entry: entry)
        }
        .configurationDisplayName("今日の再生")
        .description("今日聴いた音楽を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
