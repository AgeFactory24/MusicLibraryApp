//
//  SyncStatusView.swift
//  MusicLibrary
//

import SwiftUI

struct SyncStatusView: View {
    let lastSyncDate: Date?
    let accuracyLevel: HistoryAccuracyLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: accuracyLevel.iconName)
                .font(.caption2)
                .foregroundStyle(accuracyLevel.color)

            Text(lastSyncLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Text(accuracyLevel.shortLabel)
                .font(.caption2.bold())
                .foregroundStyle(accuracyLevel.color)
        }
        .padding(.horizontal)
    }

    private var lastSyncLabel: String {
        guard let date = lastSyncDate else { return "最終同期: 未取得" }
        let elapsed = Date().timeIntervalSince(date)
        switch elapsed {
        case ..<60:         return "最終同期: たった今"
        case ..<3600:       return "最終同期: \(Int(elapsed / 60))分前"
        case ..<86400:      return "最終同期: \(Int(elapsed / 3600))時間前"
        default:            return "最終同期: \(Int(elapsed / 86400))日前"
        }
    }
}

private extension HistoryAccuracyLevel {
    var iconName: String {
        switch self {
        case .baseline:    return "clock.arrow.circlepath"
        case .early:       return "chart.bar"
        case .developing:  return "chart.bar.fill"
        case .established: return "checkmark.seal.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .baseline:    return "初期同期中"
        case .early:       return "精度向上中"
        case .developing:  return "標準精度"
        case .established: return "高精度"
        }
    }
}
