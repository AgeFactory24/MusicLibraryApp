//
//  WeeklyTopWidget.swift
//  MusicLibraryWidget
//
//  全期間の再生数（playCountSnapshot）に基づく高精度ALL TIME TOP3
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

    /// 全期間: playCountSnapshot（Apple Music実値）でソートした高精度TOP
    private func loadEntry() -> WeeklyTopEntry {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")

        let entities = (try? context.fetch(request)) ?? []
        let grouped = Dictionary(grouping: entities, by: \.trackID)

        let top = grouped
            .compactMap { _, list -> WeeklyTopTrack? in
                guard let best = list.max(by: { $0.playCountSnapshot < $1.playCountSnapshot }),
                      best.playCountSnapshot > 0 else { return nil }
                return WeeklyTopTrack(
                    title: best.title,
                    artist: best.artistName,
                    count: Int(best.playCountSnapshot)
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(3)

        return WeeklyTopEntry(date: Date(), topTracks: Array(top))
    }
}

struct WeeklyTopWidgetView: View {
    let entry: WeeklyTopEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption.bold())
                Text("ALL TIME")
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
        .configurationDisplayName("ALL TIME TOP3")
        .description("全期間の再生数に基づくTOP3楽曲を表示")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
