//
//  MoreView.swift
//  MusicLibrary
//

import SwiftUI

struct MoreView: View {
    @StateObject private var yearlyVM = YearlyReportViewModel()
    @EnvironmentObject var libraryVM: LibraryViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PersonalityAnalysisView()
                            .environmentObject(libraryVM)
                    } label: {
                        MoreItemRow(
                            icon: "person.crop.circle.badge.checkmark",
                            color: .pink,
                            title: "音楽パーソナリティ",
                            subtitle: "あなたのリスニングスタイルを分析"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        YearlyReportView()
                            .environmentObject(yearlyVM)
                            .onAppear {
                                yearlyVM.resetToCurrent()
                            }
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
                        CDvsStreamingView()
                            .environmentObject(libraryVM)
                    } label: {
                        MoreItemRow(
                            icon: "opticaldisc",
                            color: .blue,
                            title: "CD vs Apple Music",
                            subtitle: "音源別の再生統計を比較"
                        )
                    }

                    NavigationLink {
                        TimeOfDayView()
                    } label: {
                        MoreItemRow(
                            icon: "clock.fill",
                            color: .indigo,
                            title: "時間帯分析",
                            subtitle: "参考データ（推定値）"
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
