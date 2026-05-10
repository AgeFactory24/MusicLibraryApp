//
//  YearlyReportView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct YearlyReportView: View {
    @EnvironmentObject var viewModel: YearlyReportViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var artworkService: ArtworkService
    @EnvironmentObject var historyTracker: PlayHistoryTracker
    @State private var showStory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                yearSelector

                if let report = viewModel.report, report.totalPlayCount > 0 {
                    summaryCard(report: report)
                    PersonalityInlineRow(personality: report.personality, reason: report.personalityReason)
                    GenreReportSection(
                        genreData: report.genreData,
                        totalPlayCount: report.totalPlayCount
                    )
                    monthlyChart(report: report)
                    topTracksSection(report: report)
                    topArtistsSection(report: report)
                    shareButton
                } else {
                    emptyState
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("年間レポート")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadAvailableYears()
            viewModel.loadReport(libraryTracks: libraryVM.tracks)
        }
        .onChange(of: viewModel.selectedYear) { _, _ in
            Haptics.play(.light)
            viewModel.loadReport(libraryTracks: libraryVM.tracks)
        }
        .onChange(of: historyTracker.lastSyncCompletedAt) { _, _ in
            viewModel.loadReport(libraryTracks: libraryVM.tracks)
        }
        .fullScreenCover(isPresented: $showStory) {
            if let report = viewModel.report {
                ReportStoryView(data: report.toStoryData())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            if historyTracker.historyAccuracyLevel == .baseline {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green.opacity(0.8))
                Text("ライブラリを記録しました")
                    .font(.headline)
                Text("次回の同期でリスニング履歴が蓄積されます\n今後5回の同期で詳細分析が始まります")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if historyTracker.historyAccuracyLevel == .early {
                let remaining = max(0, 5 - historyTracker.diffSyncCount)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange.opacity(0.8))
                Text("データ蓄積中")
                    .font(.headline)
                Text("あと\(remaining)回の同期で詳細な年間分析が始まります")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.pink.opacity(0.5))
                Text("\(String(viewModel.selectedYear))年のデータはまだありません")
                    .font(.headline)
                Text("音楽を聴くと履歴が蓄積されます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var yearSelector: some View {
        HStack {
            Button { changeYear(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
            }
            Spacer()
            Text("\(String(viewModel.selectedYear))年")
                .font(.title2.bold())
            Spacer()
            Button { changeYear(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
            }
        }
        .padding(.horizontal)
    }

    private func changeYear(_ delta: Int) {
        viewModel.selectedYear += delta
    }

    private func summaryCard(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.totalPlayCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.pink)
                Text("回再生")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if report.comparedToLastYear != 0 {
                    Label(
                        String(format: "%.0f%%", abs(report.comparedToLastYear)),
                        systemImage: report.comparedToLastYear >= 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(report.comparedToLastYear >= 0 ? .green.opacity(0.2) : .red.opacity(0.2))
                    .foregroundStyle(report.comparedToLastYear >= 0 ? .green : .red)
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label(report.totalPlayTimeFormatted, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func monthlyChart(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("月別再生数")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(Array(report.monthlyCounts.sorted(by: { $0.key < $1.key })), id: \.key) { month, count in
                    BarMark(
                        x: .value("月", month),
                        y: .value("回数", count)
                    )
                    .foregroundStyle(.pink.gradient)
                }
            }
            .chartXAxis {
                AxisMarks(values: [1, 4, 7, 10, 12]) { value in
                    AxisValueLabel {
                        if let m = value.as(Int.self) {
                            Text("\(m)月")
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
    }

    private func topTracksSection(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今年のTOP楽曲")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(report.topTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    NavigationLink {
                        TrackDetailView(track: track)
                    } label: {
                        HStack(spacing: 12) {
                            Text(rankLabel(index))
                                .font(.title3)
                                .frame(width: 30)
                            TrackArtworkView(track: track, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                Text(track.artistName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(track.playCount)回")
                                .font(.caption.bold())
                                .foregroundStyle(.pink)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    if index < 4 { Divider().padding(.leading, 100) }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func topArtistsSection(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今年のTOPアーティスト")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(report.topArtists.prefix(3).enumerated()), id: \.element.id) { index, artist in
                    NavigationLink {
                        ArtistDetailView(artist: artist)
                    } label: {
                        HStack(spacing: 12) {
                            Text(rankLabel(index))
                                .font(.title3)
                                .frame(width: 30)
                            Text(artist.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(artist.totalPlayCount)回")
                                .font(.caption.bold())
                                .foregroundStyle(.pink)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    if index < 2 { Divider().padding(.leading, 56) }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private var shareButton: some View {
        Button {
            Haptics.play(.medium)
            showStory = true
        } label: {
            Label("レポートを共有", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
        }
    }

    private func rankLabel(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)"
        }
    }
}
