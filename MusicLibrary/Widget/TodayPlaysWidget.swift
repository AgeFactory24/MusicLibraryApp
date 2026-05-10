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

    /// 累計: playCountSnapshot（Apple Music実値）の合計と全期間TOPトラック
    private func loadEntry() -> TodayPlaysEntry {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        let entities = (try? context.fetch(request)) ?? []

        let grouped = Dictionary(grouping: entities, by: \.trackID)

        var totalPlayCount: Int = 0
        var topEntity: PlayHistoryEntity?
        var topCount: Int32 = 0

        for (_, list) in grouped {
            guard let best = list.max(by: { $0.playCountSnapshot < $1.playCountSnapshot }) else { continue }
            totalPlayCount += Int(best.playCountSnapshot)
            if best.playCountSnapshot > topCount {
                topCount = best.playCountSnapshot
                topEntity = best
            }
        }

        return TodayPlaysEntry(
            date: Date(),
            playCount: totalPlayCount,
            topTrackTitle: topEntity?.title ?? "再生なし",
            topArtistName: topEntity?.artistName ?? ""
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
                Text("TOTAL")
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
                Text("TOTAL")
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
                Text("もっとも聴いた曲（累計）")
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
        .configurationDisplayName("累計再生数")
        .description("ライブラリ全体の累計再生数とTOP楽曲を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
