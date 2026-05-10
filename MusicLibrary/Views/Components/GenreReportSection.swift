// GenreReportSection.swift
// 月別・年別レポートで使用するジャンル分布の横バー表示コンポーネント

import SwiftUI

/// 月別・年別レポート向けシンプルジャンルバーセクション。
/// GenreAnalysisView（全ライブラリ用円グラフ）とは別に、
/// 期間限定のジャンル傾向を横バーで簡潔に見せる。
struct GenreReportSection: View {
    let genreData: [GenreData]
    let totalPlayCount: Int
    var displayCount: Int = 5

    private var topGenres: [GenreData] {
        Array(genreData.prefix(displayCount))
    }

    var body: some View {
        guard !topGenres.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("ジャンル分布（TOP\(displayCount)）")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(topGenres) { data in
                        GenreBarRow(data: data, totalPlayCount: totalPlayCount)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        )
    }
}

// MARK: - 1行分のジャンルバー

private struct GenreBarRow: View {
    let data: GenreData
    let totalPlayCount: Int

    private var ratio: Double {
        guard totalPlayCount > 0 else { return 0 }
        return Double(data.playCount) / Double(totalPlayCount)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(data.color)
                    .frame(width: 10, height: 10)
                Text(data.genre)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(ratio * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(data.color)
                    .frame(width: 42, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(data.color.gradient)
                        .frame(width: max(geo.size.width * ratio, 4))
                }
            }
            .frame(height: 6)
        }
    }
}
