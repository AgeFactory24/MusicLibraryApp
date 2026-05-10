// PersonalityAnalysisEngine.swift
// Apple Musicの制約（playCount/lastPlayedDate/isLocalAsset のみ）を前提とした
// パーソナリティ判定エンジン。擬似履歴に依存せず、スナップショット集計のみで動作する。

import Foundation
import SwiftUI

// MARK: - パーソナリティ定義

enum Personality: String, CaseIterable {
    case legend          = "レジェンド"
    case obsessedFan     = "推しが本気"
    case singleFocus     = "一点集中型"
    case heavyRotator    = "ヘビロテ職人"
    case explorer        = "音楽探検家"
    case loyalListener   = "固定リスナー"
    case growingListener = "成長型リスナー"
    case nostalgic       = "懐古リスナー"
    case genreAddict     = "ジャンル偏愛家"
    case balanced        = "バランス型"
    case collector       = "コレクター（CD）"
    case streamingFan    = "サブスク派"

    var icon: String {
        switch self {
        case .legend:          return "🥇"
        case .obsessedFan:     return "💖"
        case .singleFocus:     return "🎯"
        case .heavyRotator:    return "🔁"
        case .explorer:        return "🗺"
        case .loyalListener:   return "🔒"
        case .growingListener: return "📈"
        case .nostalgic:       return "📀"
        case .genreAddict:     return "🎼"
        case .balanced:        return "🧠"
        case .collector:       return "💿"
        case .streamingFan:    return "🌐"
        }
    }

    // 排他グループ: 同グループ内は同時付与不可
    // スコアが高い方を採用する
    var exclusionGroup: Int? {
        switch self {
        case .explorer, .loyalListener:       return 1
        case .growingListener, .nostalgic:    return 2
        case .collector, .streamingFan:       return 3
        default:                              return nil
        }
    }

    var gradient: [Color] {
        switch self {
        case .legend:          return [.yellow, .orange]
        case .obsessedFan:     return [.pink, .red]
        case .singleFocus:     return [.red, .orange]
        case .heavyRotator:    return [.purple, .pink]
        case .explorer:        return [.green, .teal]
        case .loyalListener:   return [.blue, .indigo]
        case .growingListener: return [.green, .mint]
        case .nostalgic:       return [.brown, .orange]
        case .genreAddict:     return [Color(red: 0.863, green: 0.149, blue: 0.149), Color(red: 0.486, green: 0.176, blue: 0.071)]
        case .balanced:        return [.teal, .cyan]
        case .collector:       return [.blue, .purple]
        case .streamingFan:    return [.pink, .purple]
        }
    }

    var personalityDescription: String {
        switch self {
        case .legend:          return "圧倒的な再生数を誇る音楽の達人"
        case .obsessedFan:     return "1人のアーティストを愛し抜く一途なリスナー"
        case .singleFocus:     return "お気に入りに全力を注ぐ集中リスナー"
        case .heavyRotator:    return "同じ曲を繰り返し聴き込む熟成派"
        case .explorer:        return "新しい音楽を貪欲に探し続ける冒険者"
        case .loyalListener:   return "信頼のラインナップを守り続けるコア派"
        case .growingListener: return "常に新曲でアップデートし続ける進化型"
        case .nostalgic:       return "時間をかけて育てた名曲を愛でるクラシック派"
        case .genreAddict:     return "特定ジャンルへの深い愛を持つ偏愛家"
        case .balanced:        return "ジャンルもアーティストも偏りなく楽しむ万能型"
        case .collector:       return "CDで音楽を所有する本格コレクター"
        case .streamingFan:    return "Apple Musicを使い倒すサブスクマスター"
        }
    }

    var catchphrase: String {
        switch self {
        case .legend:          return "圧倒的な再生数が、すべてを語る"
        case .obsessedFan:     return "推しがいれば、それだけでいい"
        case .singleFocus:     return "一曲に宇宙がある"
        case .heavyRotator:    return "同じ曲が、今日も違う顔を見せる"
        case .explorer:        return "まだ聴いていない音楽が、無限にある"
        case .loyalListener:   return "信じたサウンドに、ぶれない芯"
        case .growingListener: return "音楽と共に、自分もアップデートされる"
        case .nostalgic:       return "名曲には、帰れる場所がある"
        case .genreAddict:     return "このジャンルが、自分の言語だ"
        case .balanced:        return "あらゆる音楽が、等しく美しい"
        case .collector:       return "CDを手に取る瞬間、音楽が始まる"
        case .streamingFan:    return "33億曲の海を、自由に泳ぐ"
        }
    }

    func toListenerPersonality() -> ListenerPersonality {
        ListenerPersonality(
            title: rawValue,
            description: personalityDescription,
            emoji: icon,
            gradient: gradient
        )
    }
}

// MARK: - 判定結果

struct PersonalityTag: Identifiable {
    let id = UUID()
    let personality: Personality
    let score: Double    // 0.0〜1.0（判定強度：高いほど適合）
    let reason: String   // UIに表示する判定理由
    let precision: DataPrecision
}

enum DataPrecision {
    case high        // playCount/isLocalAssetから直接算出（信頼性：高）
    case estimated   // dateAddedを使う推定値（信頼性：中）
}

// MARK: - 分析指標

struct ListeningMetrics {
    // ① アーティスト集中度
    // top1ArtistRatio = TOP1アーティスト再生数 / 総再生数
    let top1ArtistRatio: Double

    // TOP1アーティスト名（表示用）
    let top1ArtistName: String

    // TOP10アーティスト集中度
    // top10ArtistRatio = TOP10アーティスト再生数合計 / 総再生数
    let top10ArtistRatio: Double

    // ② リピート率（曲集中度）
    // top1TrackRatio = TOP1楽曲再生数 / 総再生数
    let top1TrackRatio: Double

    // top10TrackRatio = TOP10楽曲再生数合計 / 総再生数
    let top10TrackRatio: Double

    // ③ アーティスト多様性
    // uniqueArtistCount: ライブラリ内のユニークアーティスト数
    let uniqueArtistCount: Int

    // ④ ジャンル比率
    // topGenreRatio = TOPジャンル再生数 / 総再生数
    let topGenreRatio: Double
    let topGenreName: String

    // ⑤ ローカル音源比率（再生ベース）
    // localPlayRatio = ローカル音源のplayCount合計 / 総playCount
    let localPlayRatio: Double

    // ⑤' ストリーミング比率
    // streamingPlayRatio = 1 - localPlayRatio
    var streamingPlayRatio: Double { 1.0 - localPlayRatio }

    // ⑥ 新規開拓率（推定・dateAdded依存）
    // recentTrackRatio = 直近90日以内追加曲の再生数 / 総再生数
    // 精度: estimated（dateAddedがnilの場合は除外）
    let recentTrackRatio: Double?

    // ⑦ 懐古率（推定・dateAdded依存）
    // oldTrackRatio = 追加1年以上経過した曲の再生数 / 総再生数
    let oldTrackRatio: Double?

    // 総再生数（playCountの合計）
    let totalPlayCount: Int

    // 総再生時間（秒）
    let totalPlayTimeSeconds: Double
}

// MARK: - エンジン本体

struct PersonalityAnalysisEngine {

    // MARK: メトリクス計算

    static func buildMetrics(from tracks: [Track]) -> ListeningMetrics {
        let totalPlayCount = tracks.reduce(0) { $0 + $1.playCount }
        let totalPlayTime = tracks.reduce(0.0) { $0 + $1.totalPlayTime }
        guard totalPlayCount > 0 else {
            return ListeningMetrics(
                top1ArtistRatio: 0, top1ArtistName: "",
                top10ArtistRatio: 0, top1TrackRatio: 0, top10TrackRatio: 0,
                uniqueArtistCount: 0, topGenreRatio: 0, topGenreName: "",
                localPlayRatio: 0, recentTrackRatio: nil, oldTrackRatio: nil,
                totalPlayCount: 0, totalPlayTimeSeconds: 0
            )
        }

        // アーティスト別再生数
        let artistPlays = Dictionary(grouping: tracks, by: \.artistName)
            .mapValues { $0.reduce(0) { $0 + $1.playCount } }
        let sortedArtists = artistPlays.sorted { $0.value > $1.value }

        let top1ArtistPlays = sortedArtists.first?.value ?? 0
        let top1ArtistName = sortedArtists.first?.key ?? ""
        let top10ArtistPlays = sortedArtists.prefix(10).reduce(0) { $0 + $1.value }

        // 楽曲別再生数（上位）
        let sortedTracks = tracks.sorted { $0.playCount > $1.playCount }
        let top1TrackPlays = sortedTracks.first?.playCount ?? 0
        let top10TrackPlays = sortedTracks.prefix(10).reduce(0) { $0 + $1.playCount }

        // ジャンル（正規化）
        let genrePlays = Dictionary(grouping: tracks, by: { normalizeGenre($0.genre) })
            .mapValues { $0.reduce(0) { $0 + $1.playCount } }
        let sortedGenres = genrePlays.sorted { $0.value > $1.value }
        let topGenrePlays = sortedGenres.first?.value ?? 0
        let topGenreName = sortedGenres.first?.key ?? "不明"

        // ローカル音源再生比率（playCountベース）
        let localPlays = tracks.filter(\.isLocalAsset).reduce(0) { $0 + $1.playCount }

        // 新規開拓率・懐古率（dateAdded依存・推定）
        let now = Date()
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now)!
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        let tracksWithDate = tracks.filter { $0.dateAdded != nil }
        let dateBasedTotal = tracksWithDate.reduce(0) { $0 + $1.playCount }

        let recentTrackRatio: Double?
        let oldTrackRatio: Double?

        if dateBasedTotal > 0 {
            let recentPlays = tracksWithDate
                .filter { $0.dateAdded! >= ninetyDaysAgo }
                .reduce(0) { $0 + $1.playCount }
            recentTrackRatio = Double(recentPlays) / Double(totalPlayCount)

            let oldPlays = tracksWithDate
                .filter { $0.dateAdded! <= oneYearAgo }
                .reduce(0) { $0 + $1.playCount }
            oldTrackRatio = Double(oldPlays) / Double(totalPlayCount)
        } else {
            recentTrackRatio = nil
            oldTrackRatio = nil
        }

        return ListeningMetrics(
            top1ArtistRatio: Double(top1ArtistPlays) / Double(totalPlayCount),
            top1ArtistName: top1ArtistName,
            top10ArtistRatio: Double(top10ArtistPlays) / Double(totalPlayCount),
            top1TrackRatio: Double(top1TrackPlays) / Double(totalPlayCount),
            top10TrackRatio: Double(top10TrackPlays) / Double(totalPlayCount),
            uniqueArtistCount: artistPlays.count,
            topGenreRatio: Double(topGenrePlays) / Double(totalPlayCount),
            topGenreName: topGenreName,
            localPlayRatio: Double(localPlays) / Double(totalPlayCount),
            recentTrackRatio: recentTrackRatio,
            oldTrackRatio: oldTrackRatio,
            totalPlayCount: totalPlayCount,
            totalPlayTimeSeconds: totalPlayTime
        )
    }

    // MARK: パーソナリティ判定（複数タグ・上位N件）

    /// 全12種を評価し、排他条件を適用した上でscoreTop件を返す
    static func evaluate(metrics: ListeningMetrics, topCount: Int = 5) -> [PersonalityTag] {
        var tags: [PersonalityTag] = []

        // --- 各パーソナリティを評価 ---

        // 🥇 レジェンド
        // 条件: 総再生時間 ≥ 1000h OR 総再生回数 ≥ 10000
        let totalHours = metrics.totalPlayTimeSeconds / 3600.0
        if totalHours >= 1000 || metrics.totalPlayCount >= 10000 {
            let score: Double
            let reason: String
            if totalHours >= 1000 && metrics.totalPlayCount >= 10000 {
                score = 1.0
                reason = "総再生\(metrics.totalPlayCount)回、\(Int(totalHours))時間を超えました"
            } else if totalHours >= 1000 {
                score = 0.95
                reason = "総再生時間が\(Int(totalHours))時間に達しました"
            } else {
                score = 0.90
                reason = "累計\(metrics.totalPlayCount)回再生を突破しました"
            }
            tags.append(PersonalityTag(personality: .legend, score: score,
                                       reason: reason, precision: .high))
        }

        // 💖 推しが本気
        // 条件: TOP1アーティスト割合 ≥ 40%
        // スコア = top1ArtistRatio（40%以上で有効）
        if metrics.top1ArtistRatio >= 0.40 {
            let pct = Int(metrics.top1ArtistRatio * 100)
            tags.append(PersonalityTag(
                personality: .obsessedFan,
                score: metrics.top1ArtistRatio,
                reason: "再生の\(pct)%が\(metrics.top1ArtistName)に集中しています",
                precision: .high
            ))
        }

        // 🎯 一点集中型
        // 条件: TOP1曲割合 ≥ 25% OR TOP1アーティスト割合 ≥ 60%
        // スコア = max(top1TrackRatio / 0.25, top1ArtistRatio / 0.60) を上限1.0で
        let trackConcentration = metrics.top1TrackRatio / 0.25
        let artistConcentration = metrics.top1ArtistRatio / 0.60
        if metrics.top1TrackRatio >= 0.25 || metrics.top1ArtistRatio >= 0.60 {
            let score = min(max(trackConcentration, artistConcentration), 1.0)
            let pctTrack = Int(metrics.top1TrackRatio * 100)
            let pctArtist = Int(metrics.top1ArtistRatio * 100)
            let reason: String
            if metrics.top1TrackRatio >= 0.25 {
                reason = "1曲に全再生の\(pctTrack)%が集中しています"
            } else {
                reason = "1アーティストに\(pctArtist)%が集中しています"
            }
            tags.append(PersonalityTag(personality: .singleFocus, score: score,
                                       reason: reason, precision: .high))
        }

        // 🔁 ヘビロテ職人
        // 条件: TOP10楽曲割合 ≥ 50%
        // スコア = top10TrackRatio（50%以上で有効）
        if metrics.top10TrackRatio >= 0.50 {
            let pct = Int(metrics.top10TrackRatio * 100)
            tags.append(PersonalityTag(
                personality: .heavyRotator,
                score: metrics.top10TrackRatio,
                reason: "再生の\(pct)%がお気に入りの10曲に集中しています",
                precision: .high
            ))
        }

        // 🗺 音楽探検家（排他グループ1）
        // 条件: TOP10アーティスト割合 ≤ 35% AND ユニークアーティスト数 ≥ 100
        // スコア = (1 - top10ArtistRatio) * min(uniqueArtistCount/100, 1.0) * 多様性係数
        if metrics.top10ArtistRatio <= 0.35 && metrics.uniqueArtistCount >= 100 {
            let diversityScore = (1.0 - metrics.top10ArtistRatio) *
                                 min(Double(metrics.uniqueArtistCount) / 200.0, 1.0)
            tags.append(PersonalityTag(
                personality: .explorer,
                score: diversityScore,
                reason: "\(metrics.uniqueArtistCount)組のアーティストを幅広く聴いています",
                precision: .high
            ))
        }

        // 🔒 固定リスナー（排他グループ1）
        // 条件: TOP10アーティスト割合 ≥ 70%
        // スコア = top10ArtistRatio（70%以上で有効）
        if metrics.top10ArtistRatio >= 0.70 {
            let pct = Int(metrics.top10ArtistRatio * 100)
            tags.append(PersonalityTag(
                personality: .loyalListener,
                score: metrics.top10ArtistRatio,
                reason: "再生の\(pct)%がお気に入りの10組に集中しています",
                precision: .high
            ))
        }

        // 📈 成長型リスナー（排他グループ2）
        // 条件: 直近90日以内追加曲の再生割合 ≥ 40%
        // 精度: estimated
        if let recent = metrics.recentTrackRatio, recent >= 0.40 {
            let pct = Int(recent * 100)
            tags.append(PersonalityTag(
                personality: .growingListener,
                score: recent,
                reason: "再生の\(pct)%が直近90日以内に追加した新曲です（推定）",
                precision: .estimated
            ))
        }

        // 📀 懐古リスナー（排他グループ2）
        // 条件: 追加1年以上経過した曲の再生割合 ≥ 70%
        // 精度: estimated
        if let old = metrics.oldTrackRatio, old >= 0.70 {
            let pct = Int(old * 100)
            tags.append(PersonalityTag(
                personality: .nostalgic,
                score: old,
                reason: "再生の\(pct)%が1年以上前に追加した楽曲です（推定）",
                precision: .estimated
            ))
        }

        // 🎼 ジャンル偏愛家
        // 条件: TOPジャンル割合 ≥ 60%
        // スコア = topGenreRatio
        if metrics.topGenreRatio >= 0.60 {
            let pct = Int(metrics.topGenreRatio * 100)
            tags.append(PersonalityTag(
                personality: .genreAddict,
                score: metrics.topGenreRatio,
                reason: "再生の\(pct)%が\(metrics.topGenreName)です",
                precision: .high
            ))
        }

        // 🧠 バランス型
        // 条件: TOPジャンル割合 ≤ 30% AND TOP1アーティスト割合 ≤ 20%
        // スコア = (0.30 - topGenreRatio) + (0.20 - top1ArtistRatio)（バランスが良いほど高い）
        if metrics.topGenreRatio <= 0.30 && metrics.top1ArtistRatio <= 0.20 {
            let genreBalance = 0.30 - metrics.topGenreRatio
            let artistBalance = 0.20 - metrics.top1ArtistRatio
            let score = min((genreBalance / 0.30 + artistBalance / 0.20) / 2.0, 1.0)
            let pctGenre = Int(metrics.topGenreRatio * 100)
            let pctArtist = Int(metrics.top1ArtistRatio * 100)
            tags.append(PersonalityTag(
                personality: .balanced,
                score: score,
                reason: "ジャンル最大\(pctGenre)%・アーティスト最大\(pctArtist)%と均等に分散しています",
                precision: .high
            ))
        }

        // 💿 コレクター（CD）（排他グループ3）
        // 条件: ローカル音源再生割合 ≥ 60%
        // スコア = localPlayRatio
        if metrics.localPlayRatio >= 0.60 {
            let pct = Int(metrics.localPlayRatio * 100)
            tags.append(PersonalityTag(
                personality: .collector,
                score: metrics.localPlayRatio,
                reason: "ローカル音源（CD取り込み）が再生の\(pct)%を占めています",
                precision: .high
            ))
        }

        // 🌐 サブスク派（排他グループ3）
        // 条件: ストリーミング再生割合 ≥ 80%
        if metrics.streamingPlayRatio >= 0.80 {
            let pct = Int(metrics.streamingPlayRatio * 100)
            tags.append(PersonalityTag(
                personality: .streamingFan,
                score: metrics.streamingPlayRatio,
                reason: "Apple Musicストリーミングが再生の\(pct)%を占めています",
                precision: .high
            ))
        }

        // --- 排他条件の適用 ---
        let resolved = resolveExclusions(tags)

        // --- スコア降順でtopCountを返す ---
        return Array(resolved.sorted { $0.score > $1.score }.prefix(topCount))
    }

    // MARK: Private

    /// 同じ排他グループ内ではスコアが高い方だけ残す
    private static func resolveExclusions(_ tags: [PersonalityTag]) -> [PersonalityTag] {
        var result: [PersonalityTag] = []
        var usedGroups: [Int: PersonalityTag] = [:]

        for tag in tags.sorted(by: { $0.score > $1.score }) {
            if let group = tag.personality.exclusionGroup {
                if usedGroups[group] == nil {
                    usedGroups[group] = tag
                    result.append(tag)
                }
                // 低スコア側はスキップ
            } else {
                result.append(tag)
            }
        }
        return result
    }

    // MARK: PlayHistoryEntry ベースのメトリクス計算（月別・年別レポート用）

    /// PlayHistoryEntry（実際の再生イベント）から指標を計算する。
    /// 1エントリ = 1再生 として扱う。
    static func buildMetrics(
        from history: [PlayHistoryEntry],
        libraryTracks: [Track]
    ) -> ListeningMetrics {
        let totalPlays = history.count
        let totalPlayTime = history.reduce(0.0) { $0 + $1.duration }
        guard totalPlays > 0 else {
            return ListeningMetrics(
                top1ArtistRatio: 0, top1ArtistName: "",
                top10ArtistRatio: 0, top1TrackRatio: 0, top10TrackRatio: 0,
                uniqueArtistCount: 0, topGenreRatio: 0, topGenreName: "",
                localPlayRatio: 0, recentTrackRatio: nil, oldTrackRatio: nil,
                totalPlayCount: 0, totalPlayTimeSeconds: 0
            )
        }

        let libraryMap = Dictionary(uniqueKeysWithValues: libraryTracks.map { ($0.id, $0) })

        // アーティスト集中度
        let artistCounts = Dictionary(grouping: history, by: \.artistName).mapValues(\.count)
        let sortedArtists = artistCounts.sorted { $0.value > $1.value }
        let top1ArtistPlays = sortedArtists.first?.value ?? 0
        let top1ArtistName = sortedArtists.first?.key ?? ""
        let top10ArtistPlays = sortedArtists.prefix(10).reduce(0) { $0 + $1.value }

        // 楽曲集中度
        let trackCounts = Dictionary(grouping: history, by: \.trackID).mapValues(\.count)
        let sortedTracks = trackCounts.sorted { $0.value > $1.value }
        let top1TrackPlays = sortedTracks.first?.value ?? 0
        let top10TrackPlays = sortedTracks.prefix(10).reduce(0) { $0 + $1.value }

        // ジャンル（libraryMapから取得・正規化）
        var genreCounts: [String: Int] = [:]
        for entry in history {
            let raw = libraryMap[entry.trackID]?.genre ?? ""
            let genre = normalizeGenre(raw)
            genreCounts[genre, default: 0] += 1
        }
        let sortedGenres = genreCounts.sorted { $0.value > $1.value }
        let topGenrePlays = sortedGenres.first?.value ?? 0
        let topGenreName = sortedGenres.first?.key ?? "その他"

        // ローカル音源比率（isLocalAssetベース）
        let localPlays = history.filter(\.isLocalAsset).count

        // 新規開拓率・懐古率（dateAdded依存・推定）
        let now = Date()
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now)!
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        let entriesWithDate = history.filter { libraryMap[$0.trackID]?.dateAdded != nil }
        let recentTrackRatio: Double?
        let oldTrackRatio: Double?

        if !entriesWithDate.isEmpty {
            let recentPlays = entriesWithDate.filter {
                (libraryMap[$0.trackID]?.dateAdded ?? .distantPast) >= ninetyDaysAgo
            }.count
            recentTrackRatio = Double(recentPlays) / Double(totalPlays)

            let oldPlays = entriesWithDate.filter {
                (libraryMap[$0.trackID]?.dateAdded ?? .distantFuture) <= oneYearAgo
            }.count
            oldTrackRatio = Double(oldPlays) / Double(totalPlays)
        } else {
            recentTrackRatio = nil
            oldTrackRatio = nil
        }

        return ListeningMetrics(
            top1ArtistRatio: Double(top1ArtistPlays) / Double(totalPlays),
            top1ArtistName: top1ArtistName,
            top10ArtistRatio: Double(top10ArtistPlays) / Double(totalPlays),
            top1TrackRatio: Double(top1TrackPlays) / Double(totalPlays),
            top10TrackRatio: Double(top10TrackPlays) / Double(totalPlays),
            uniqueArtistCount: artistCounts.count,
            topGenreRatio: Double(topGenrePlays) / Double(totalPlays),
            topGenreName: topGenreName,
            localPlayRatio: Double(localPlays) / Double(totalPlays),
            recentTrackRatio: recentTrackRatio,
            oldTrackRatio: oldTrackRatio,
            totalPlayCount: totalPlays,
            totalPlayTimeSeconds: totalPlayTime
        )
    }

    // MARK: 共有パレット（月別・年別レポート用ジャンルグラフ）

    static let genrePalette: [Color] = [
        .pink, .purple, .blue, .teal, .green,
        .yellow, .orange, .red, .indigo, .mint,
        .cyan, .brown
    ]

    // MARK: PlayHistoryEntry ベースのジャンル集計（月別・年別レポート用）

    /// 月別・年別レポートの genreData を生成する共有メソッド。
    /// GenreAnalysisViewModel（全ライブラリ用）とは別口として定義。
    static func buildGenreData(
        from history: [PlayHistoryEntry],
        libraryTracks: [Track]
    ) -> [GenreData] {
        let genreMap = Dictionary(uniqueKeysWithValues: libraryTracks.map { ($0.id, $0.genre) })
        var counts: [String: Int] = [:]
        for entry in history {
            let genre = normalizeGenre(genreMap[entry.trackID] ?? "")
            counts[genre, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { index, pair in
                GenreData(
                    genre: pair.key,
                    playCount: pair.value,
                    trackCount: 0,
                    topArtists: [],
                    color: genrePalette[index % genrePalette.count]
                )
            }
    }

    // MARK: Private

    /// ジャンル文字列を正規化する。
    /// Apple Music のメタデータは表記が不統一なため、主要ジャンルを代表名に集約する。
    static func normalizeGenre(_ genre: String) -> String {
        let trimmed = genre.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "その他" }

        let lower = trimmed.lowercased()

        // J-Pop（最優先で判定）
        if lower.contains("j-pop") || lower.contains("jpop") || lower.contains("j pop")
            || lower.contains("ジェイポップ") || lower.contains("jポップ") {
            return "J-Pop"
        }
        // K-Pop
        if lower.contains("k-pop") || lower.contains("kpop") || lower.contains("ケーポップ") {
            return "K-Pop"
        }
        // アニメ・ボカロ
        if lower.contains("anime") || lower.contains("アニメ") { return "アニメ" }
        if lower.contains("vocaloid") || lower.contains("ボカロ") || lower.contains("ボーカロイド") {
            return "ボカロ"
        }
        // 演歌・民謡・歌謡曲
        if lower.contains("演歌") || lower.contains("enka") { return "演歌" }
        if lower.contains("民謡") || lower.contains("童謡") || lower.contains("わらべ") { return "民謡・童謡" }
        if lower.contains("歌謡") || lower.contains("kayokyoku") { return "歌謡曲" }
        // R&B / Soul
        if lower.contains("r&b") || lower.contains("soul") || lower.contains("ソウル")
            || lower.contains("rhythm and blues") {
            return "R&B/Soul"
        }
        // Hip-Hop / Rap
        if lower.contains("hip") || lower.contains("rap") || lower.contains("ヒップホップ") {
            return "Hip-Hop"
        }
        // Electronic / EDM
        if lower.contains("electro") || lower.contains("edm") || lower.contains("エレクトロ")
            || lower.contains("techno") || lower.contains("テクノ") || lower.contains("house")
            || lower.contains("ハウス") || lower.contains("dance") {
            return "Electronic"
        }
        // Rock
        if lower.contains("rock") || lower.contains("ロック") || lower.contains("punk")
            || lower.contains("パンク") || lower.contains("metal") || lower.contains("メタル") {
            return "Rock"
        }
        // Jazz
        if lower.contains("jazz") || lower.contains("ジャズ") { return "Jazz" }
        // Classical
        if lower.contains("classical") || lower.contains("クラシック") || lower.contains("orchestra")
            || lower.contains("オーケストラ") || lower.contains("symphony") {
            return "Classical"
        }
        // Soundtrack / Game
        if lower.contains("soundtrack") || lower.contains("サウンドトラック") || lower.contains("ost") {
            return "サウンドトラック"
        }
        if lower.contains("game") || lower.contains("ゲーム") { return "ゲーム音楽" }
        // Gospel / Christian
        if lower.contains("gospel") || lower.contains("christian") || lower.contains("クリスチャン") {
            return "Gospel"
        }
        // Reggae / World
        if lower.contains("reggae") || lower.contains("レゲエ") { return "Reggae" }
        if lower.contains("world") || lower.contains("ワールド") || lower.contains("latin")
            || lower.contains("ラテン") {
            return "ワールド"
        }
        // Pop（広義・後ろに持ってくることで J-Pop 等の誤マッチを防ぐ）
        if lower.contains("pop") || lower.contains("ポップ") { return "Pop" }

        return trimmed
    }
}
