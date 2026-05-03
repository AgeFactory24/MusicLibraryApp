//
//  MoreView.swift
//  MusicLibrary
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        YearlyReportView()
                    } label: {
                        MoreItemRow(
                            icon: "calendar.badge.clock",
                            color: .pink,
                            title: "年間レポート",
                            subtitle: "1年間のリスニング履歴を振り返る"
                        )
                    }

                    NavigationLink {
                        LibraryView()
                    } label: {
                        MoreItemRow(
                            icon: "music.note.list",
                            color: .purple,
                            title: "ライブラリ",
                            subtitle: "楽曲・アーティスト・アルバム一覧"
                        )
                    }

                    NavigationLink {
                        StatisticsView()
                    } label: {
                        MoreItemRow(
                            icon: "chart.pie.fill",
                            color: .orange,
                            title: "統計",
                            subtitle: "全体統計とジャンル分析"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        MoreItemRow(
                            icon: "gearshape.fill",
                            color: .gray,
                            title: "設定",
                            subtitle: "通知設定など"
                        )
                    }
                }
            }
            .navigationTitle("more")
        }
    }
}

private struct MoreItemRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
