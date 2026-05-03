//
//  TimeOfDayViewModel.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import Combine

struct TimeOfDayData {
    let hourlyCounts: [Int: Int]    // 0-23
    let weekdayCounts: [Int: Int]   // 1-7
    let peakHour: Int
    let peakWeekday: Int

    var peakHourLabel: String {
        switch peakHour {
        case 5..<11: return "朝の人 ☀️"
        case 11..<14: return "ランチタイム派 🍙"
        case 14..<18: return "午後派 ☕"
        case 18..<22: return "夕方派 🌆"
        case 22..<24, 0..<5: return "夜更かし派 🌙"
        default: return "音楽好き 🎵"
        }
    }

    var peakWeekdayLabel: String {
        let names = ["", "日", "月", "火", "水", "木", "金", "土"]
        guard peakWeekday >= 1 && peakWeekday <= 7 else { return "—" }
        return "\(names[peakWeekday])曜日"
    }
}

@MainActor
final class TimeOfDayViewModel: ObservableObject {
    @Published var data: TimeOfDayData?

    private let repository = PlayHistoryRepository()

    func load() {
        let hourly = repository.hourlyPlayCounts()
        let weekday = repository.weekdayPlayCounts()

        let peakHour = hourly.max(by: { $0.value < $1.value })?.key ?? 0
        let peakWeekday = weekday.max(by: { $0.value < $1.value })?.key ?? 1

        data = TimeOfDayData(
            hourlyCounts: hourly,
            weekdayCounts: weekday,
            peakHour: peakHour,
            peakWeekday: peakWeekday
        )
    }
}
