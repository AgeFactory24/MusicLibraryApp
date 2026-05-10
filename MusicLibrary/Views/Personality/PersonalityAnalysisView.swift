// PersonalityAnalysisView.swift
// MusicLibrary

import SwiftUI
import UIKit

struct PersonalityAnalysisView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var vm = PersonalityAnalysisViewModel()
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if vm.isLoading {
                        ProgressView("分析中...")
                            .padding(.top, 60)
                    } else if vm.tags.isEmpty {
                        EmptyPersonalityView()
                    } else {
                        PersonalityHeaderView(tags: vm.tags)
                        TagListSection(tags: vm.tags)
                        if let metrics = vm.metrics {
                            MetricsSummarySection(metrics: metrics)
                        }
                        PrecisionNoticeView()
                        if let top = vm.tags.first {
                            shareButton(tag: top)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("あなたの音楽性格")
            .onAppear {
                vm.analyze(tracks: libraryVM.tracks)
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = shareImage {
                    ActivityShareSheet(items: [img])
                }
            }
        }
    }

    @MainActor
    private func shareButton(tag: PersonalityTag) -> some View {
        Button {
            Haptics.play(.medium)
            let card = PersonalityShareCard(tag: tag)
            shareImage = ShareImageRenderer().render(card, size: CGSize(width: 600, height: 400))
            showShareSheet = shareImage != nil
        } label: {
            Label("パーソナリティをシェア", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
        }
    }
}

// MARK: - ヘッダー（上位タグをまとめて表示）

private struct PersonalityHeaderView: View {
    let tags: [PersonalityTag]

    var body: some View {
        VStack(spacing: 8) {
            if let top = tags.first {
                Text(top.personality.icon)
                    .font(.system(size: 64))
                Text(top.personality.rawValue)
                    .font(.title.bold())
                Text("あなたの聴き方を分析しました")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // 全タグをコンパクトに横並び
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags) { tag in
                        Text("\(tag.personality.icon) \(tag.personality.rawValue)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.pink.opacity(0.15))
                            .foregroundStyle(.pink)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - タグリスト（判定理由付き）

private struct TagListSection: View {
    let tags: [PersonalityTag]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "あなたのパーソナリティ")
            ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
                PersonalityTagCard(rank: index + 1, tag: tag)
            }
        }
        .padding(.horizontal)
    }
}

private struct PersonalityTagCard: View {
    let rank: Int
    let tag: PersonalityTag

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return .orange
        default: return .secondary.opacity(0.6)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // ランク番号
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Text("#\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(rankColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tag.personality.icon)
                    Text(tag.personality.rawValue)
                        .font(.subheadline.bold())
                    if tag.precision == .estimated {
                        EstimatedBadge()
                    }
                }
                Text(tag.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // スコアバー
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * tag.score)
                    }
                }
                .frame(height: 4)
                .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - メトリクスサマリー

private struct MetricsSummarySection: View {
    let metrics: ListeningMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "分析データ")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricCard(
                    label: "TOP1アーティスト集中度",
                    value: percentString(metrics.top1ArtistRatio),
                    icon: "person.fill",
                    color: .pink
                )
                MetricCard(
                    label: "TOP10楽曲リピート率",
                    value: percentString(metrics.top10TrackRatio),
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange
                )
                MetricCard(
                    label: "ユニークアーティスト",
                    value: "\(metrics.uniqueArtistCount)組",
                    icon: "music.mic",
                    color: .purple
                )
                MetricCard(
                    label: "ジャンル集中度",
                    value: percentString(metrics.topGenreRatio),
                    icon: "music.note.list",
                    color: .teal
                )
                MetricCard(
                    label: "ローカル音源（CD）",
                    value: percentString(metrics.localPlayRatio),
                    icon: "opticaldisc",
                    color: .blue
                )
                MetricCard(
                    label: "Apple Musicストリーミング",
                    value: percentString(metrics.streamingPlayRatio),
                    icon: "applelogo",
                    color: .gray
                )
            }
        }
        .padding(.horizontal)
    }

    private func percentString(_ ratio: Double) -> String {
        "\(Int(ratio * 100))%"
    }
}

private struct MetricCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 精度注記

private struct PrecisionNoticeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("データ精度について")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text("「推定」マーク付きのタグは、楽曲の追加日（dateAdded）を基に算出しています。Apple Musicの制約により正確な再生履歴は取得できないため、推定値として参考にしてください。その他のタグは再生回数（playCount）から直接算出した高精度データです。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

// MARK: - 推定バッジ

struct EstimatedBadge: View {
    var body: some View {
        Text("推定")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.2))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }
}

// MARK: - 空状態

private struct EmptyPersonalityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("データが不足しています")
                .font(.headline)
            Text("楽曲を再生すると、あなたのリスニングパーソナリティが分析されます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
}

// MARK: - シェア用カード

private struct PersonalityShareCard: View {
    let tag: PersonalityTag

    var body: some View {
        ZStack {
            LinearGradient(
                colors: tag.personality.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                PersonalityIconSymbol(personality: tag.personality, size: 120)
                Text(tag.personality.rawValue)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(tag.personality.personalityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("MusicLibrary")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

// MARK: - UIActivityViewController ラッパー

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
