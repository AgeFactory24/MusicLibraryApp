//
//  MusicLibraryWidgetBundle.swift
//  MusicLibraryWidget
//

import WidgetKit
import SwiftUI

@main
struct MusicLibraryWidgetBundle: WidgetBundle {
    var body: some Widget {
        // ホーム画面ウィジェット
        TodayPlaysWidget()
        WeeklyTopWidget()
        MonthlySummaryWidget()
        HourlyHeatmapWidget()
        // Live Activity / Dynamic Island は削除
    }
}
