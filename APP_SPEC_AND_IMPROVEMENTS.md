# MusicLibrary アプリ 仕様書 & 改善提案

最終更新: 2026-05-10

---

## 目次

1. [プロダクト方針](#1-プロダクト方針)
2. [技術スタック・制約](#2-技術スタック制約)
3. [データモデル](#3-データモデル)
4. [履歴精度レベル設計](#4-履歴精度レベル設計)
5. [データ取得・永続化フロー（新設計）](#5-データ取得永続化フロー新設計)
6. [画面構成・機能一覧](#6-画面構成機能一覧)
7. [パーソナリティ分析エンジン仕様](#7-パーソナリティ分析エンジン仕様)
8. [ウィジェット仕様](#8-ウィジェット仕様)
9. [開発者モード仕様](#9-開発者モード仕様)
10. [現状の課題](#10-現状の課題)
11. [改善提案](#11-改善提案)
12. [ファイル構成](#12-ファイル構成)

---

## 1. プロダクト方針

### コンセプト

「長年育てた音楽ライブラリと、あなたの音楽人格を可視化する」

Apple Music Replay でも Spotify Wrapped でも見えない角度——
**CD・ローカル音源を含めた音楽遍歴の総合分析**——を提供することが、
このアプリの唯一無二の存在意義。

### 差別化軸

| 軸 | 内容 |
|----|------|
| **長期ライブラリ** | 累計 playCount・総再生時間・アーティスト数など、年単位で育てたデータ |
| **CD / ローカル音源文化** | Apple Music Replay では見えない CD 取り込み楽曲を正当評価 |
| **音楽人格** | 12種類のパーソナリティ診断・カスタムアイコンによる可視化 |
| **音楽遍歴** | 年間レポート・月別レポートによる振り返り |

### 「Spotify的リアルタイム分析」はやらない

- 「今日何曲聴いた」「この時間帯によく聴く」などは Apple Music API の制約上、
  正確な値を提供できない
- 推定データをリアルタイム分析として見せることはユーザーへの誤解を招く
- **これらの機能は廃止または参考データとして明示したうえで最小化する**

### データ信頼性の原則

1. **正直であること**: 推定データは必ず UI 上で明示する
2. **高精度データを主軸にする**: playCount / isLocalAsset / lastPlayedDate は Apple 提供の高精度値
3. **時間軸分析はアプリ導入後の差分から構築する**: アプリ導入前の履歴は復元しない
4. **「使うほど精度が上がる」を体験させる**: 導入後の差分蓄積で月別・日別が充実していく

---

## 2. 技術スタック・制約

### フレームワーク

| 用途 | フレームワーク |
|------|--------------|
| UI | SwiftUI |
| 音楽ライブラリ取得 | MediaPlayer (MPMediaQuery) |
| ストリーミング認証 | MusicKit |
| 永続化 | Core Data (NSPersistentCloudKitContainer) |
| グラフ描画 | Swift Charts |
| カスタムアイコン描画 | SwiftUI Canvas / Path |
| 通知 | UserNotifications |
| ウィジェット | WidgetKit |
| シェア | UIActivityViewController |

### Apple Music API 制約（設計上の前提）

| 取得可能 | 取得不可 |
|---------|--------|
| playCount（累計再生回数） | 時系列の再生履歴 |
| lastPlayedDate（最終再生日） | 各再生の正確な時刻 |
| isLocalAsset（ローカル音源判定） | リアルタイム再生状態 |
| genre / dateAdded / duration | バックグラウンド高頻度同期 |

**isLocalAsset の判定**: `MPMediaItem.assetURL != nil` を使用。
iCloud Music Library によるマッチング後もローカルファイルが存在する場合は `true` となるため、
CD取り込み判定として最も信頼性が高い（`hasProtectedAsset` は誤分類が多いため不採用）。

---

## 3. データモデル

### Swift 構造体（View 層）

```
Track
  ├── id: String               // MPMediaItem.persistentID
  ├── title, artistName, albumTitle: String
  ├── playCount: Int           // Apple Music から直接取得（高精度）
  ├── duration: TimeInterval
  ├── isLocalAsset: Bool       // assetURL != nil（高精度）
  ├── lastPlayedDate: Date?    // 最終再生日（高精度）
  ├── genre: String
  ├── dateAdded: Date?         // 中精度
  └── totalPlayTime: TimeInterval  // computed

Artist / Album / PlayHistoryEntry ... (変更なし)
```

### Core Data エンティティ

```
PlayHistoryEntity
  ├── trackID, title, artistName, albumTitle: String
  ├── playedAt: Date           // アプリ導入後の差分から推定（※導入前は生成しない）
  ├── playCountSnapshot: Int32
  ├── duration: Double
  └── isLocalAsset: Bool

PlayCountSnapshotEntity
  ├── trackID: String
  ├── playCount: Int32         // 前回同期時の playCount（差分検出に使用）
  └── recordedAt: Date

AppInstallDateEntity（新規）
  ├── installedAt: Date        // アプリ初回起動日（差分トラッキング開始基準）
  └── baselinePlayCount: Int32 // インストール時の総 playCount（参考値）
```

### 精度分類

| データ | 精度 | 根拠 |
|-------|------|------|
| playCount（総計） | 高 | Apple Music から直接取得 |
| isLocalAsset | 高 | assetURL の有無で確定判定 |
| lastPlayedDate | 高 | Apple Music から直接取得 |
| genre | 中 | メタデータが不統一 |
| dateAdded | 中 | 一部欠損あり |
| playedAt（導入後差分） | 推定 | 差分発生日時を基点に30分間隔で推算 |
| playedAt（導入前） | 生成しない | 過去の正確な再生時刻は復元不可能 |

---

## 4. 履歴精度レベル設計

アプリ導入後の差分蓄積量に基づき、**履歴精度レベル（HistoryAccuracyLevel）**を定義する。
各分析画面はこのレベルに基づいて表示内容を切り替える。

### レベル定義

| レベル | 条件 | 利用可能な分析 |
|--------|------|----------------|
| `baseline` | 初回起動直後。差分なし | 累計データのみ（高精度） |
| `early` | 差分同期 1〜3 回 | 最近の増加トレンド（参考） |
| `developing` | 差分同期 4〜12 回（約1ヶ月） | 月別・日別分析（推定） |
| `established` | 差分同期 13 回以上（約3ヶ月） | 月別・日別分析（信頼度向上） |

### 各レベルでの UI 挙動

```
baseline（初回直後）
  → 月別レポート: 「アプリを継続利用することで月別分析が充実します」
  → 日別グラフ: 非表示（または空状態）
  → 今週のTOP: playCountSnapshot 合計値で表示（累計ベース）

early（差分1〜3回）
  → 月別レポート: データ少ない旨を通知バナーで明示
  → 日別グラフ: 推定バッジ付きで表示

developing / established
  → 通常表示（推定注記は残す）
```

### HistoryAccuracyLevel の実装

```swift
enum HistoryAccuracyLevel: Int, Comparable {
    case baseline    = 0
    case early       = 1
    case developing  = 2
    case established = 3

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .baseline:    return "初期データ"
        case .early:       return "収集中"
        case .developing:  return "分析可能"
        case .established: return "高精度"
        }
    }

    var description: String {
        switch self {
        case .baseline:
            return "アプリ導入直後です。継続利用で月別・日別分析が充実します。"
        case .early:
            return "データ収集中です。あと数回起動すると月別分析が利用できます。"
        case .developing:
            return "月別分析が利用可能になりました。"
        case .established:
            return "十分なデータが蓄積されています。"
        }
    }
}
```

---

## 5. データ取得・永続化フロー（新設計）

### 設計方針の転換

| 旧設計 | 新設計 |
|--------|--------|
| 初回起動時に最大300件/曲の playedAt を逆算生成（バックフィル） | 初回起動時はスナップショット記録のみ。履歴は生成しない |
| 過去再生を「復元」 | 導入後の差分のみ「記録」 |
| 時間帯・日別分析を推定データで提供 | 時間帯・曜日分析は廃止。日別は差分蓄積後に提供 |
| hasBackfilled フラグで制御 | HistoryAccuracyLevel + 差分回数で制御 |

### 起動時フロー（新設計）

```
アプリ起動
  └── PlayHistoryTracker.syncPlayHistory()
       │
       ├── 初回（isFirstLaunch = true）
       │    └── MPMediaQuery 全楽曲取得
       │         └── PlayCountSnapshotEntity に現在の playCount を記録
       │              → PlayHistoryEntity は生成しない
       │              → AppInstallDate を記録
       │              → HistoryAccuracyLevel = .baseline
       │
       └── 差分同期（isFirstLaunch = false）
            └── PlayCountSnapshotEntity と現在の playCount を比較
                 delta > 0 の曲のみ PlayHistoryEntity を追加
                 playedAt = lastPlayedDate から差分数×30分で推算
                 差分同期回数をインクリメント → HistoryAccuracyLevel を更新
                 500件ごとにバッチ保存
```

### 重要な変更点

- **バックフィル廃止**: `hasBackfilled` / `performInitialBackfillBatched()` を削除
- **初回はゼロ履歴が正常**: 初回直後は PlayHistoryEntity = 0 件
- **累計データは常に高精度**: playCount / isLocalAsset / lastPlayedDate はそのまま全画面で表示可能
- **「使い続けるほど精度が上がる」体験**: 差分が蓄積されるにつれて月別・日別が充実

### アーティスト/アルバム取得フォールバック

```
カスタム画像（手動設定）
  ↓
MPMediaItemArtwork（楽曲組み込み）
  ↓
Deezer API（人物画像）
  ↓
iTunes Search API（アルバムジャケット）
  ↓
プレースホルダー
```

---

## 6. 画面構成・機能一覧

### タブ構成

```
TabView
  ├── ホーム（HomeView）           … 累計高精度データ主体
  ├── ランキング（RankingView）     … 累計高精度データ主体
  ├── 月別（MonthlyReportView）    … 精度レベルに応じて表示切替
  └── more（MoreView）
       ├── 音楽パーソナリティ
       ├── 年間レポート
       ├── ライブラリ
       ├── 統計
       ├── 設定
       └── 開発者モード（内部確認用）
```

**削除済み画面:**
- 時間帯分析（TimeOfDayView） — 推定精度が低すぎるため廃止
- 曜日分析 — 同上
- CD vs Apple Music（CDvsStreamingView） — more から削除（統計画面に統合）

---

### 6-1. ホーム（HomeView）

**高精度データのみ表示（精度レベル問わず利用可）**

- リスニングサマリ（4マスグリッド）
  - 総再生回数 / 総再生時間 / アーティスト数 / CD取り込み曲数
- パーソナリティバッジ（PersonalityIconSymbol + 判定理由）
- 再生回数TOP5楽曲（CDアイコンでローカル音源識別）
- トップアーティスト（横スクロール、TOP10）

---

### 6-2. ランキング（RankingView）

**高精度データのみ表示**

- 楽曲 / アーティスト / アルバム（セグメントPicker）
- 期間: 全期間 / 直近30日（lastPlayedDate フィルタ）
- 注記: 「再生回数は累計値です。期間内の再生数ではありません」

---

### 6-3. 月別レポート（MonthlyReportView）

**精度レベルに応じて表示を切り替える**

| 精度レベル | 表示内容 |
|-----------|---------|
| baseline | 「継続利用で充実します」バナー + 累計データのみ |
| early | 推定バッジ + 参考グラフ（データ少ない旨を明示） |
| developing〜 | 通常表示（推定注記は残す） |

**表示内容**
1. 月選択ナビゲーター
2. サマリーカード（再生回数・再生時間・前月比）
3. パーソナリティバッジ（PersonalityInlineRow）
4. 日別再生数棒グラフ（精度レベル条件付き）
5. TOP5楽曲 / TOP3アーティスト
6. HistoryAccuracyLevel バナー（baseline / early 時のみ表示）
7. 共有ボタン

---

### 6-4. more（MoreView）

| メニュー項目 | 遷移先 | 備考 |
|------------|--------|------|
| 音楽パーソナリティ | PersonalityAnalysisView | 高精度 |
| 年間レポート | YearlyReportView | 差分ベース |
| ライブラリ | LibraryView | 高精度 |
| 統計 | StatisticsView | 高精度 |
| 設定 | SettingsView | — |
| 開発者モード | DeveloperModeView | 内部確認用 |

**削除したメニュー:**
- CD vs Apple Music（→ 統計画面の音源内訳セクションで確認）
- 時間帯分析（廃止）

---

### 6-5. 音楽パーソナリティ（PersonalityAnalysisView）

**高精度データのみ使用 → 精度レベル問わず常に有効**

- TOP1パーソナリティのカスタムアイコン + 名前 + 全タグ横スクロール
- タグカード × 最大5件（カスタムアイコン・スコアバー・推定バッジ）
- メトリクスサマリー（6指標グリッド）
- 精度注記（推定データの説明）
- シェアボタン（PersonalityShareCard を画像共有）

---

### 6-6. 年間レポート（YearlyReportView）

- 年選択ナビゲーター
- サマリーカード（再生回数・再生時間・前年比）
- パーソナリティバッジ
- 月別再生数棒グラフ
- TOP5楽曲 / TOP3アーティスト
- Wrapped 風ストーリー共有

---

### 6-7. 統計（StatisticsView）

**高精度データのみ**

- 全体統計（再生回数・時間・アーティスト数・アルバム数）
- 音源内訳（CD取り込み vs Apple Music の再生数比率）← CDvsStreamingView の内容を統合
- 最も聴いた楽曲 / アーティスト
- ジャンル別再生分布

---

### 6-8. 楽曲詳細（TrackDetailView）

- アートワーク（長押しで変更可）
- 総再生回数・総再生時間
- 初回再生日
- 日別再生数折れ線グラフ（精度レベル条件付き）
- 最近の再生履歴（最大10件、推定注記付き）
- お気に入りボタン

---

### 6-9. Wrapped 風ストーリー（ReportStoryView）

**7ページ構成**

1. オープニング
2. 総再生回数（高精度）
3. ジャンル分布（高精度）
4. TOPアーティスト（高精度）
5. TOP楽曲（高精度）
6. 最も聴いた月（差分ベース）
7. パーソナリティ（高精度・PersonalityIconSymbol animated）

---

## 7. パーソナリティ分析エンジン仕様

### 7-1. 分析指標（ListeningMetrics）

| 指標 | 計算式 | 精度 |
|------|--------|------|
| top1ArtistRatio | TOP1アーティスト再生数 / 総再生数 | 高 |
| top10ArtistRatio | TOP10アーティスト再生数合計 / 総再生数 | 高 |
| top1TrackRatio | TOP1楽曲再生数 / 総再生数 | 高 |
| top10TrackRatio | TOP10楽曲再生数合計 / 総再生数 | 高 |
| uniqueArtistCount | ユニークアーティスト数 | 高 |
| topGenreRatio | TOPジャンル再生数 / 総再生数 | 高 |
| localPlayRatio | ローカル音源再生数 / 総再生数 | 高 |
| recentTrackRatio | 直近90日追加曲の再生数 / 総再生数 | 推定 |
| oldTrackRatio | 追加1年以上経過曲の再生数 / 総再生数 | 推定 |

### 7-2. パーソナリティ判定（12種類）

| # | 名称 | 判定条件 | 排他グループ | アイコン種別 |
|---|------|---------|------------|---------|
| 1 | レジェンド | 総時間 ≥ 1000h OR 総再生 ≥ 10000回 | なし | 光線+王冠+レコード+スパークル |
| 2 | 推しが本気 | top1ArtistRatio ≥ 40% | なし | グロー+ハート（拡縮）+スパークル |
| 3 | 一点集中型 | top1TrackRatio ≥ 25% OR top1ArtistRatio ≥ 60% | なし | 的+矢 |
| 4 | ヘビロテ職人 | top10TrackRatio ≥ 50% | なし | ループ矢印（回転）+∞ |
| 5 | 音楽探検家 | top10ArtistRatio ≤ 35% AND uniqueArtist ≥ 100 | グループA | コンパス+音符 |
| 6 | 固定リスナー | top10ArtistRatio ≥ 70% | グループA | シールド+南京錠+スパークル |
| 7 | 成長型リスナー | recentTrackRatio ≥ 40%（推定） | グループB | 棒グラフ（高さ変動）+上矢印 |
| 8 | 懐古リスナー | oldTrackRatio ≥ 70%（推定） | グループB | ビニールレコード（回転） |
| 9 | ジャンル偏愛家 | topGenreRatio ≥ 60% | なし | 五線譜+ト音記号+音符 |
| 10 | バランス型 | topGenreRatio ≤ 30% AND top1ArtistRatio ≤ 20% | なし | 天秤（ビーム揺動）+音符 |
| 11 | コレクター（CD） | localPlayRatio ≥ 60% | グループC | CDディスク（回転） |
| 12 | サブスク派 | streamingPlayRatio ≥ 80% | グループC | 地球儀+WiFiアーク（点滅）+音符 |

---

## 8. ウィジェット仕様

**削除したウィジェット:**
- HourlyHeatmapWidget — 時間帯分析廃止に伴い削除

| ウィジェット | サイズ | 表示内容 | データソース |
|------------|--------|---------|------------|
| TodayPlaysWidget | Small | 累計再生数（TOTAL） | playCountSnapshot 合計 |
| WeeklyTopWidget | Small/Medium | ALL TIME TOP3楽曲 | playCountSnapshot 最大値 |
| MonthlySummaryWidget | Large | 月間再生回数サマリー | PlayHistoryRepository |
| NowPlayingLiveActivity | Dynamic Island | 再生中楽曲情報 | NowPlayingActivityAttributes |

---

## 9. 開発者モード仕様

**対象**: 開発者・社内確認のみ。本番ユーザーには提供しない。
**導線**: more → 開発者モード（デバッグビルド時のみ表示推奨）

### 9-1. セクション構成

#### パーソナリティ確認

- 全12種のPersonalityIconSymbol をグリッド表示
- 各アイコンをタップ → 判定条件・スコア算出例をオーバーレイ表示
- 現在の LibraryViewModel データで全12種のスコアをリスト表示（フィルタ前の生スコア）

#### 現在のメトリクス

- ListeningMetrics の全フィールドを数値で表示
- どのパーソナリティ条件をパスしているか ✅ / ❌ で明示

#### 同期・履歴状態

- 最終同期日時 / 同期回数
- HistoryAccuracyLevel（現在レベル + 次レベルまでの条件）
- PlayHistoryEntity 総件数
- PlayCountSnapshotEntity 総件数
- アプリ初回起動日（AppInstallDate）

#### playCount 差分確認

- 直近同期で差分が発生した楽曲一覧（trackID・title・前回count・今回count・delta）
- 最大20件表示

#### Feature Flag

- `enableMonthlyAnalysis`: 月別グラフ表示のON/OFF（デバッグ用強制表示）
- `enableDeveloperMode`: 開発者モードメニューの表示制御
- `forceAccuracyLevel`: 精度レベルを強制上書き（テスト用）

#### データ操作（危険操作）

- 履歴リセット（PlayHistoryEntity 全削除 + バックフィルフラグリセット）
- スナップショットリセット
- AppInstallDate リセット

---

## 10. 現状の課題

### 10-1. 廃止済み問題（解決）

- ~~時間帯分析が推定精度で誤解を招く~~ → **廃止**
- ~~バックフィルで過去履歴が「復元」されたように見える~~ → **バックフィル廃止**
- ~~CDvsStreamingView がタブから独立しすぎている~~ → **統計に統合・削除**

### 10-2. 現存する課題

**月別レポートの日別グラフ精度**
- 差分 playedAt は30分間隔の推定値
- 「8/15 に10回再生」は実態とは異なる可能性がある
- → UI 上の推定バッジ表示で対処中。根本解決は Apple API 制約上不可

**ランキング期間フィルタが近似**
- 「直近30日」は lastPlayedDate ベース
- 期間内の再生数ではなく、期間内に最後に聴いた楽曲の累計 playCount

**ジャンル文字列の不統一**
- Apple Music メタデータは表記が不均一
- normalizeGenre() でカバーしているが長尾ジャンルは未対応

**アーティスト/アルバムIDが文字列キー**
- Artist.id = artistName（スペル揺れで衝突リスク）

**月別・年別のジャンル集計が3箇所に重複**
- MonthlyReportViewModel / YearlyReportViewModel / PersonalityAnalysisEngine

---

## 11. 改善提案

凡例: ✅ 実装済み / 🔲 未実装

---

### 優先度: 高

---

#### ✅ バックフィル廃止・差分専用トラッキングへ変更

- 初回起動時は PlayHistoryEntity を生成しない
- PlayCountSnapshotEntity への記録のみ実施
- 以降の差分同期でのみ PlayHistoryEntity を追加

---

#### ✅ HistoryAccuracyLevel 導入

- 差分同期回数に基づくレベル定義（baseline / early / developing / established）
- 月別レポートで精度レベルに応じた表示切替
- SettingsView に現在の精度レベルと向上条件を表示

---

#### ✅ 時間帯分析・曜日分析・HourlyHeatmapWidget 廃止

- 推定精度が低すぎるため完全削除
- MoreView・WidgetBundle から除去

---

#### ✅ CD vs Apple Music 分析 廃止（統計に統合）

- CDvsStreamingView を MoreView から削除
- StatisticsView の音源内訳セクションに統合

---

#### ✅ 開発者モード追加

- DeveloperModeView を実装
- more メニューに追加（デバッグビルドまたは設定でON/OFF）

---

#### 🔲 月別レポートに HistoryAccuracyLevel バナーを追加

```swift
if accuracyLevel < .developing {
    AccuracyLevelBanner(level: accuracyLevel)
}
```

---

#### 🔲 ランキング期間の拡充

```swift
enum RankingPeriod {
    case allTime, recentWeek, recentMonth, recent3Months, thisYear
}
```

---

#### 🔲 月別・年別レポートにジャンル分布を追加

- genreData が計算済みだが View に未表示

---

### 優先度: 中

---

#### 🔲 localAssetRatio の計算基準統一

- StatisticsViewModel: 曲数ベース
- PersonalityAnalysisEngine: 再生数ベース
- → 再生数ベースに統一

---

#### 🔲 ジャンル集計の共通化

- buildGenreData() が3箇所に重複 → PersonalityAnalysisEngine に統合

---

#### 🔲 パーソナリティ分析のキャッシュ

- UserDefaults にキャッシュ、tracks.count 変化で無効化

---

### 優先度: 低（将来検討）

---

#### 🔲 パーソナリティの推移トラッキング

- 月末に PersonalityTag を Core Data 保存
- 「3ヶ月前は音楽探検家でした」の変化ストーリー

#### 🔲 楽曲詳細への外部情報連携

- Genius API で歌詞リンク
- リリース日・BPM 等の追加メタデータ

#### 🔲 連続再生ストリーク機能

- N日連続でアプリ起動・差分記録を達成したら通知

---

## 12. ファイル構成

```
MusicLibrary/
├── App/
│   ├── MusicLibraryApp.swift
│   └── ContentView.swift              # TabView（ホーム / ランキング / 月別 / more）
│
├── Models/
│   ├── Track.swift
│   ├── Artist.swift
│   ├── Album.swift
│   ├── PlayHistoryEntry.swift
│   ├── HistoryAccuracyLevel.swift     # 新規: 履歴精度レベル定義
│   └── LibrarySortOption.swift
│
├── Persistence/
│   ├── PersistenceController.swift
│   └── PlayHistoryRepository.swift
│
├── Services/
│   ├── PlayHistoryTracker.swift       # 変更: バックフィル廃止・差分専用
│   ├── PersonalityAnalysisEngine.swift
│   ├── MusicLibraryService.swift
│   ├── MusicAuthService.swift
│   ├── ArtworkService.swift
│   ├── DeezerSearchService.swift
│   ├── iTunesSearchService.swift
│   ├── FavoriteService.swift
│   ├── SearchHistoryService.swift
│   ├── NotificationService.swift
│   ├── UserProfileService.swift
│   ├── HapticsManager.swift
│   ├── ShareImageRenderer.swift
│   ├── SocialShareService.swift
│   ├── BackgroundSyncManager.swift
│   ├── CloudSyncService.swift
│   └── NowPlayingActivityManager.swift
│
├── ViewModels/
│   ├── LibraryViewModel.swift
│   ├── RankingViewModel.swift
│   ├── StatisticsViewModel.swift
│   ├── MonthlyReportViewModel.swift
│   ├── YearlyReportViewModel.swift
│   ├── TrackDetailViewModel.swift
│   ├── GenreAnalysisViewModel.swift
│   └── PersonalityAnalysisViewModel.swift
│
├── Views/
│   ├── Home/HomeView.swift
│   ├── Ranking/RankingView.swift, RankingRowView.swift
│   ├── MonthlyReport/MonthlyReportView.swift
│   ├── YearlyReport/YearlyReportView.swift
│   ├── More/MoreView.swift             # 変更: CDvs・TimeOfDay削除、DeveloperMode追加
│   ├── Developer/DeveloperModeView.swift  # 新規
│   ├── Personality/PersonalityAnalysisView.swift
│   ├── Statistics/StatisticsView.swift # 変更: 音源内訳セクション強化
│   ├── Library/LibraryView.swift
│   ├── TrackDetail/TrackDetailView.swift
│   ├── ArtistDetail/ArtistDetailView.swift, AlbumDetailView.swift
│   ├── Settings/SettingsView.swift
│   ├── Auth/AuthorizationView.swift
│   ├── Onboarding/OnboardingView.swift
│   ├── Story/ReportStoryView.swift, StoryShareSheet.swift
│   ├── Share/ShareCardView.swift
│   └── Components/
│       ├── PersonalityBadgeView.swift  # PersonalityIconSymbol（12種Canvasアイコン）
│       ├── AccuracyLevelBanner.swift   # 新規: 精度レベル通知バナー
│       ├── ArtworkView.swift
│       ├── StatCardView.swift
│       ├── EditableArtworkView.swift
│       └── GenreReportSection.swift
│
└── Widget/
    ├── MusicLibraryWidgetBundle.swift  # 変更: HourlyHeatmapWidget 削除
    ├── TodayPlaysWidget.swift
    ├── WeeklyTopWidget.swift
    ├── MonthlySummaryWidget.swift
    └── NowPlayingLiveActivity.swift
    ※ HourlyHeatmapWidget.swift は廃止（ファイル削除）
```

---

*以上*
