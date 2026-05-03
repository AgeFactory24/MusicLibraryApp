//
//  HourlyHeatmapWidget.swift
//  MusicLibraryWidget
//
//  Mediumサイズ：時間帯別ヒートマップ（24時間）
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Entry

struct HourlyHeatmapEntry: TimelineEntry {
    let date: Date
    let hourlyCounts: [Int: Int]   // 0-23 -> count
    let peakHour: Int
}

// MARK: - Provider

struct HourlyHeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> HourlyHeatmapEntry {
        var counts: [Int: Int] = [:]
        for hour in 0..<24 {
            counts[hour] = (3 + (hour * 7) % 15)
        }
        return HourlyHeatmapEntry(date: Date(), hourlyCounts: counts, peakHour: 21)
    }

    func getSnapshot(in context: Context, completion: @escaping (HourlyHeatmapEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HourlyHeatmapEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> HourlyHeatmapEntry {
        let context = PersistenceController.shared.container.viewContext

        let request = NSFetchRequest<PlayHistoryEntity>(entityName: "PlayHistoryEntity")
        let entries = (try? context.fetch(request)) ?? []

        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for entry in entries {
            let hour = calendar.component(.hour, from: entry.playedAt)
            counts[hour, default: 0] += 1
        }

        let peak = counts.max(by: { $0.value < $1.value })?.key ?? 0
        return HourlyHeatmapEntry(date: Date(), hourlyCounts: counts, peakHour: peak)
    }
}

// MARK: - View

struct HourlyHeatmapWidgetView: View {
    let entry: HourlyHeatmapEntry

    private var maxCount: Int {
        entry.hourlyCounts.values.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HEATMAP")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.pink)
                    Text("時間帯別の再生数")
                        .font(.caption.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ピーク")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("\(entry.peakHour)時")
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                }
            }

            // ヒートマップグリッド（24時間）
            GeometryReader { geo in
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0..<24, id: \.self) { hour in
                            let count = entry.hourlyCounts[hour] ?? 0
                            let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.pink.opacity(0.15 + intensity * 0.85))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(hour == entry.peakHour ? Color.pink : Color.clear, lineWidth: 1.5)
                                }
                        }
                    }
                    .frame(height: 36)

                    // 時間ラベル（4時間ごと）
                    HStack(spacing: 0) {
                        ForEach([0, 6, 12, 18], id: \.self) { hour in
                            Text("\(hour)時")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text("23時")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 56)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(.systemBackground), Color.pink.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Widget

struct HourlyHeatmapWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HourlyHeatmapWidget", provider: HourlyHeatmapProvider()) { entry in
            HourlyHeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("時間帯ヒートマップ")
        .description("24時間別の再生分布を表示")
        .supportedFamilies([.systemMedium])
    }
}
