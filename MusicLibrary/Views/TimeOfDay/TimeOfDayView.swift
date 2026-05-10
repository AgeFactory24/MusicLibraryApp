//
//  TimeOfDayView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct TimeOfDayView: View {
    @StateObject private var viewModel = TimeOfDayViewModel()
    @EnvironmentObject var historyTracker: PlayHistoryTracker

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let data = viewModel.data, !data.hourlyCounts.isEmpty {
                        EstimatedDataBanner()
                        peakCards(data: data)
                        hourlyChart(data: data)
                        weekdayChart(data: data)
                    } else if viewModel.data == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        emptyState
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("時間帯分析")
            .onAppear { viewModel.load() }
            .onChange(of: historyTracker.lastSyncCompletedAt) { _, _ in
                viewModel.load()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.pink.opacity(0.5))
            Text("データがまだありません")
                .font(.headline)
            Text("音楽を聴くと履歴が蓄積されます")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func peakCards(data: TimeOfDayData) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("一番聴く時間")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(data.peakHour)時")
                    .font(.title.bold())
                    .foregroundStyle(.pink)
                Text(data.peakHourLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text("一番聴く曜日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(data.peakWeekdayLabel)
                    .font(.title.bold())
                    .foregroundStyle(.purple)
                Text("ヘビロテ曜日")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal)
    }

    private func hourlyChart(data: TimeOfDayData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("時間帯別の再生数")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(0..<24, id: \.self) { hour in
                    BarMark(
                        x: .value("時間", hour),
                        y: .value("回数", data.hourlyCounts[hour] ?? 0)
                    )
                    .foregroundStyle(
                        hour == data.peakHour ? Color.pink : Color.pink.opacity(0.4)
                    )
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour)時")
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - 精度注記バナー（改善-1）

    /// Apple Music API の制約により playedAt が推定値であることをユーザーに明示する。
    private struct EstimatedDataBanner: View {
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("このデータは推定値です")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                    Text("Apple Music の制約により、再生時刻は lastPlayedDate から逆算した推定値です。時間帯・曜日の傾向は参考としてご活用ください。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func weekdayChart(data: TimeOfDayData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("曜日別の再生数")
                .font(.headline)
                .padding(.horizontal)

            let weekdayNames = ["", "日", "月", "火", "水", "木", "金", "土"]

            Chart {
                ForEach(1...7, id: \.self) { weekday in
                    BarMark(
                        x: .value("曜日", weekdayNames[weekday]),
                        y: .value("回数", data.weekdayCounts[weekday] ?? 0)
                    )
                    .foregroundStyle(
                        weekday == data.peakWeekday ? Color.purple : Color.purple.opacity(0.4)
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}
