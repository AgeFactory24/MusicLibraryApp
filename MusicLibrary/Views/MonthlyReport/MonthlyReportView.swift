//
//  MonthlyReportView.swift
//  MusicLibrary
//

import SwiftUI
import Charts

struct MonthlyReportView: View {
    @EnvironmentObject var viewModel: MonthlyReportViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var artworkService: ArtworkService
    @EnvironmentObject var historyTracker: PlayHistoryTracker
    @State private var showStory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector

                    SyncStatusView(
                        lastSyncDate: historyTracker.lastSyncCompletedAt,
                        accuracyLevel: historyTracker.historyAccuracyLevel
                    )

                    if historyTracker.historyAccuracyLevel < .developing {
                        AccuracyLevelBanner(level: historyTracker.historyAccuracyLevel)
                    }

                    if let report = viewModel.report, report.totalPlayCount > 0 {
                        summaryCard(report: report)
                        PersonalityInlineRow(personality: report.personality, reason: report.personalityReason)
                        NavigationLink {
                            PeriodGenreDetailView(
                                genreData: report.genreData,
                                totalPlayCount: report.totalPlayCount,
                                title: "\(viewModel.selectedYear)年\(viewModel.selectedMonth)月のジャンル"
                            )
                        } label: {
                            GenreReportSection(
                                genreData: report.genreData,
                                totalPlayCount: report.totalPlayCount,
                                showNavigationArrow: true
                            )
                        }
                        .buttonStyle(.plain)
                        dailyChart(report: report)
                        topTracksSection(report: report)
                        topArtistsSection(report: report)
                        shareButton
                    } else {
                        emptyState
                    }
                }
                .padding(.vertical)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 40, coordinateSpace: .local)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                        Haptics.play(.light)
                        if value.translation.width < 0 { changeMonth(1) }
                        else { changeMonth(-1) }
                    }
            )
            .navigationTitle("月別レポート")
            .onAppear { viewModel.loadReport(libraryTracks: libraryVM.tracks) }
            .onChange(of: viewModel.selectedMonth) { _, _ in
                Haptics.play(.light)
                viewModel.loadReport(libraryTracks: libraryVM.tracks)
            }
            .onChange(of: viewModel.selectedYear) { _, _ in
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
                Text("あと\(remaining)回の同期で詳細な月別分析が始まります")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "music.note.list")
                    .font(.system(size: 50))
                    .foregroundStyle(.pink.opacity(0.5))
                Text("この月のデータはまだありません")
                    .font(.headline)
                Text("音楽を聴くと履歴が蓄積されます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var monthSelector: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
            }
            Spacer()
            Text("\(String(viewModel.selectedYear))年\(viewModel.selectedMonth)月")
                .font(.title2.bold())
            Spacer()
            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
            }
        }
        .padding(.horizontal)
    }

    private func changeMonth(_ delta: Int) {
        let calendar = Calendar.current
        var components = DateComponents(
            year: viewModel.selectedYear,
            month: viewModel.selectedMonth
        )
        components.month! += delta
        guard let date = calendar.date(from: components) else { return }
        viewModel.selectedYear = calendar.component(.year, from: date)
        viewModel.selectedMonth = calendar.component(.month, from: date)
    }

    private func summaryCard(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.totalPlayCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.pink)
                Text("回再生")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if report.comparedToLastMonth != 0 {
                    Label(
                        String(format: "%.0f%%", abs(report.comparedToLastMonth)),
                        systemImage: report.comparedToLastMonth >= 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(report.comparedToLastMonth >= 0 ? .green.opacity(0.2) : .red.opacity(0.2))
                    .foregroundStyle(report.comparedToLastMonth >= 0 ? .green : .red)
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label(report.totalPlayTimeFormatted, systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func dailyChart(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日別再生数")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(Array(report.dailyCounts.sorted(by: { $0.key < $1.key })), id: \.key) { day, count in
                    BarMark(
                        x: .value("日", day),
                        y: .value("回数", count)
                    )
                    .foregroundStyle(.pink.gradient)
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
    }

    private func topTracksSection(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今月のTOP楽曲")
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

    private func topArtistsSection(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今月のTOPアーティスト")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(report.topArtists.prefix(5).enumerated()), id: \.element.id) { index, artist in
                        NavigationLink {
                            ArtistDetailView(artist: artist)
                        } label: {
                            ArtistChipView(rank: index + 1, artist: artist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
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
