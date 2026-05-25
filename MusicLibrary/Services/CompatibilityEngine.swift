//
//  CompatibilityEngine.swift
//  MusicLibrary
//

import SwiftUI

struct CompatibilityResult {
    let score: Int
    let level: CompatibilityLevel
    let myProfile: ListeningProfile
    let partnerProfile: ListeningProfile
    let commonArtists: [String]
    let artistScore: Double
    let personalityScore: Double
    let genreScore: Double
    let trendScore: Double
    let reason: String
}

enum CompatibilityLevel {
    case perfect, high, moderate, low

    var label: String {
        switch self {
        case .perfect:  return "最高の相性"
        case .high:     return "相性抜群"
        case .moderate: return "まあまあ"
        case .low:      return "好みが違うかも"
        }
    }

    var color: Color {
        switch self {
        case .perfect:  return .pink
        case .high:     return .purple
        case .moderate: return .orange
        case .low:      return .blue
        }
    }

    var emoji: String {
        switch self {
        case .perfect:  return "🎵"
        case .high:     return "🎸"
        case .moderate: return "🎹"
        case .low:      return "🎲"
        }
    }
}

enum CompatibilityEngine {

    static func calculate(me: ListeningProfile, partner: ListeningProfile) -> CompatibilityResult {
        // 共通アーティスト（40%）
        let myArtists = Set(me.topArtistNames)
        let partnerArtists = Set(partner.topArtistNames)
        let common = myArtists.intersection(partnerArtists)
        let unionCount = max(1, myArtists.union(partnerArtists).count)
        let artistScore = Double(common.count) / Double(unionCount)

        // パーソナリティ相性（20%）
        let personalityScore = personalityCompatibility(me.personalityType, partner.personalityType)

        // ジャンル相性（20%）- コサイン類似度
        let genreScore = genreSimilarity(me.topGenres, partner.topGenres)

        // リスニング傾向（20%）- CD比率の近さ
        let trendScore = 1.0 - abs(me.cdRatio - partner.cdRatio)

        let raw = artistScore * 0.40 + personalityScore * 0.20 + genreScore * 0.20 + trendScore * 0.20
        let score = min(100, max(0, Int((raw * 100).rounded())))

        let level: CompatibilityLevel
        switch score {
        case 80...: level = .perfect
        case 60..<80: level = .high
        case 40..<60: level = .moderate
        default: level = .low
        }

        return CompatibilityResult(
            score: score,
            level: level,
            myProfile: me,
            partnerProfile: partner,
            commonArtists: Array(common),
            artistScore: artistScore,
            personalityScore: personalityScore,
            genreScore: genreScore,
            trendScore: trendScore,
            reason: generateReason(
                score: score, level: level,
                commonArtists: Array(common),
                me: me, partner: partner
            )
        )
    }

    // MARK: - Personality compatibility matrix

    private static func personalityCompatibility(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        let groups: [[String]] = [
            ["ヘビロテ職人", "固定ファン"],
            ["音楽探検家", "ジャンル職人"],
            ["バランス派", "コレクター"],
            ["伝道師", "レジェンドウォッチャー"]
        ]
        for group in groups {
            if group.contains(a) && group.contains(b) { return 0.75 }
        }
        return 0.45
    }

    // MARK: - Genre cosine similarity

    private static func genreSimilarity(_ a: [ProfileGenre], _ b: [ProfileGenre]) -> Double {
        let allGenres = Set(a.map(\.name)).union(b.map(\.name))
        guard !allGenres.isEmpty else { return 0 }

        let aMap = Dictionary(uniqueKeysWithValues: a.map { ($0.name, $0.ratio) })
        let bMap = Dictionary(uniqueKeysWithValues: b.map { ($0.name, $0.ratio) })

        var dot = 0.0, normA = 0.0, normB = 0.0
        for genre in allGenres {
            let av = aMap[genre] ?? 0
            let bv = bMap[genre] ?? 0
            dot += av * bv
            normA += av * av
            normB += bv * bv
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }

    // MARK: - Reason text

    private static func generateReason(
        score: Int,
        level: CompatibilityLevel,
        commonArtists: [String],
        me: ListeningProfile,
        partner: ListeningProfile
    ) -> String {
        var parts: [String] = []

        if !commonArtists.isEmpty {
            let names = commonArtists.prefix(2).joined(separator: "・")
            parts.append("\(names)が共通のお気に入り")
        }

        if me.personalityType == partner.personalityType {
            parts.append("リスニングスタイルがそっくり（\(me.personalityType)）")
        }

        let cdDiff = abs(me.cdRatio - partner.cdRatio)
        if cdDiff < 0.15 {
            parts.append("音源へのこだわりも似ている")
        }

        if parts.isEmpty {
            switch level {
            case .perfect, .high: parts.append("ジャンルの好みが近い")
            case .moderate: parts.append("音楽の趣味は少し違うが、新しい発見があるかも")
            case .low: parts.append("異なる音楽世界を持つ二人。互いに影響しあえる関係")
            }
        }

        return parts.joined(separator: "。")
    }
}
