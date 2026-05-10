// HistoryAccuracyLevel.swift
// MusicLibrary

import Foundation
import SwiftUI

enum HistoryAccuracyLevel: Int, Comparable {
    case baseline    = 0  // 初回起動直後: スナップショットのみ
    case early       = 1  // 差分1〜4回: 傾向把握開始
    case developing  = 2  // 差分5〜14回: 月別・日別分析が成立
    case established = 3  // 差分15回以上: 精度十分

    static func < (lhs: HistoryAccuracyLevel, rhs: HistoryAccuracyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func level(for diffSyncCount: Int) -> HistoryAccuracyLevel {
        switch diffSyncCount {
        case 0:      return .baseline
        case 1..<5:  return .early
        case 5..<15: return .developing
        default:     return .established
        }
    }

    var label: String {
        switch self {
        case .baseline:    return "導入直後"
        case .early:       return "精度向上中"
        case .developing:  return "分析可能"
        case .established: return "高精度"
        }
    }

    var color: Color {
        switch self {
        case .baseline:    return .red
        case .early:       return .orange
        case .developing:  return .yellow
        case .established: return .green
        }
    }

    var description: String {
        switch self {
        case .baseline:
            return "アプリ導入直後です。利用継続で月別・日別分析の精度が向上します。"
        case .early:
            return "データ蓄積中です。引き続き使うことで詳細分析が有効になります。"
        case .developing:
            return "月別・日別分析が利用可能になりました。"
        case .established:
            return "十分なデータが蓄積されています。"
        }
    }
}
