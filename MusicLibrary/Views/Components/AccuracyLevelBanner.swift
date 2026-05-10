// AccuracyLevelBanner.swift
// MusicLibrary

import SwiftUI

struct AccuracyLevelBanner: View {
    let level: HistoryAccuracyLevel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(level.color)
                .font(.subheadline)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("データ精度：\(level.label)")
                    .font(.caption.bold())
                    .foregroundStyle(level.color)
                Text(level.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("詳細分析は利用継続で精度が向上します")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(level.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(level.color.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
