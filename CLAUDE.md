# CLAUDE.md — MusicLibrary

## Project Overview

**Apple Music × CD取り込み音源を統合分析する iOS アプリ**

Apple の公式 Replay は CD リップ音源の再生回数を反映しない。本アプリは `MPMediaQuery` で両音源を統合し、再生履歴・統計・パーソナリティ判定・相性チェックを提供する。

**主な機能**
- 再生履歴の差分検知による自動追跡（バックフィル対応）
- 12 種類の音楽パーソナリティ自動判定
- 月別・年間レポート（Wrapped 風ストーリー、カウントアップ演出・覚醒ページ）
- QR コードによる音楽相性チェック（4 軸スコア）
- ホーム画面ウィジェット × 4 種 + Live Activity
- SNS シェアカード生成（QR 自動合成・10 位表示・パーソナリティ画像埋め込み）
- フローティングタブバー（iOS 26 Liquid Glass 対応）

---

## Tech Stack

| 項目 | 内容 |
|------|------|
| 言語 | Swift 5.9+ |
| UI | SwiftUI（UIKit は UIViewControllerRepresentable 経由のみ）|
| 最小 OS | iOS 17 以上（IPHONEOS_DEPLOYMENT_TARGET）|
| データ永続化 | Core Data（プログラマティック定義、App Group 対応）|
| 音楽データ取得 | MediaPlayer（MPMediaQuery） ← **主役** |
| 認証 | MusicKit（MediaPlayer の権限取得に使用、カタログ検索は未実装）|
| グラフ | Swift Charts |
| QR スキャン | VisionKit（DataScannerViewController）+ Vision（写真ライブラリ）|
| 外部 API | Deezer Search API、iTunes Search API（アーティスト画像のみ、API キー不要）|
| バックグラウンド | BackgroundTasks（BGAppRefreshTask）|
| 通知 | UserNotifications |
| ウィジェット | WidgetKit + ActivityKit |
| 外部ライブラリ | **なし**（Swift Package 依存ゼロ）|

---

## Architecture

**MVVM + Service Layer**

```
View（SwiftUI）
  └─ @EnvironmentObject / @StateObject で ViewModel を受け取る

ViewModel（@MainActor, ObservableObject）
  └─ @Published で View に状態を公開
  └─ Service を呼び出してデータ加工

Service（ビジネスロジック）
  └─ 単一責任。ViewModel からのみ呼ばれる

Repository（Core Data クエリ抽象化）
  └─ PlayHistoryRepository のみ

Model（純粋な値型）
  └─ Track, Artist, Album, ListeningProfile など
```

**EnvironmentObject として全体に渡されるもの（MusicLibraryApp.swift）**

```swift
// Services
MusicAuthService, ArtworkService, PlayHistoryTracker,
FavoriteService, SearchHistoryService, NotificationService,
UserProfileService, CloudSyncService

// ViewModels（ContentView 起点）
LibraryViewModel, RankingViewModel, StatisticsViewModel,
MonthlyReportViewModel
```

**データフロー**
1. `PlayHistoryTracker` が `MPMediaQuery` で差分検知 → Core Data に保存
2. ViewModel が Repository / Service を呼び出してデータ構築
3. View は ViewModel の `@Published` を購読して自動更新

---

## Directory Structure

```
MusicLibrary/
├── App/
│   ├── MusicLibraryApp.swift         # @main。全 EnvironmentObject を登録
│   ├── ContentView.swift             # フローティングタブバー（iOS 26: Liquid Glass / iOS 17-25: カスタム Capsule）
│   └── AppTheme.swift                # デザイントークン統一（Colors / Spacing / Radius / Typography / Shadow）
├── Models/                           # 値型のドメインモデル
│   ├── Track.swift
│   ├── Artist.swift
│   ├── Album.swift
│   ├── PlayHistoryEntry.swift        # Core Data エンティティ定義 + 表示型
│   ├── ListeningProfile.swift        # QR 埋め込み用プロフィール（Codable）
│   ├── HistoryAccuracyLevel.swift
│   ├── LibrarySortOption.swift
│   ├── SyncLog.swift
│   ├── NowPlayingActivityAttributes.swift
│   └── MPMediaItem+SourceClassification.swift  # CD vs Apple Music 判定（isLocalAsset）
├── Persistence/
│   ├── PersistenceController.swift   # Core Data Stack（プログラマティック定義）
│   └── PlayHistoryRepository.swift   # クエリ・集計層
├── Services/                         # ビジネスロジック（19 ファイル）
│   ├── MusicLibraryService.swift     # MPMediaQuery でライブラリ取得・アルバム複合キー生成
│   ├── PlayHistoryTracker.swift      # 差分検知・バックフィル・精度管理
│   ├── PersonalityAnalysisEngine.swift  # 12 種パーソナリティ判定
│   ├── CompatibilityEngine.swift     # 相性スコア（4 軸）
│   ├── QRCodeService.swift           # QR エンコード/デコード/生成
│   ├── ArtworkService.swift          # アートワーク（多段キャッシュ・ローカル音源保護）
│   ├── DeezerSearchService.swift     # Deezer API クライアント
│   ├── iTunesSearchService.swift     # iTunes Search API（フォールバック）
│   └── ...（その他 11 サービス）
├── ViewModels/                       # 8 ViewModel
├── Views/
│   ├── Components/                   # 共通コンポーネント（PersonalityBadgeView 等）
│   ├── Home/                         # 統計グリッド（2×2）・パーソナリティ・TOP5
│   ├── Ranking/                      # 横スワイプ切替・マイクロアニメーション・先頭スクロール
│   ├── Library/
│   ├── MonthlyReport/
│   ├── YearlyReport/
│   ├── Story/                        # Wrapped 風ストーリー（カウントアップ・覚醒ページ）
│   ├── Personality/                  # 波形背景・横スワイプ探索モード（12 種比較）
│   ├── QR/
│   ├── Share/                        # シェアカード（10 位・パーソナリティ画像・QR 合成）
│   ├── Settings/
│   ├── More/
│   └── Developer/                    # デバッグ UI（DeveloperModeView）
├── Widget/                           # WidgetKit + Live Activity（4 種）
└── Resources/
    └── MusicLibrary.xcdatamodeld/   # Core Data スキーマ（コード定義のため空）
```

**ルート直下の重要ファイル**
- `UIUX_IMPROVEMENT_PROPOSALS.md` — UI/UX 改善提案書（全項目実装済み）
- `sanko/` — パーソナリティアイコン描画の参考実装（変更不要）

---

## Coding Rules

**命名規則**
- 型・ファイル名: PascalCase（`PlayHistoryTracker`, `ArtworkService`）
- プロパティ・メソッド: camelCase（`totalPlayCount`, `fetchLocalTracks()`）
- 定数: camelCase（Swift 標準に従う）
- Enum ケース: camelCase（`.playCount`, `.allTime`）

**コメント方針**
- `// MARK: - セクション名` でグループ化を必ず行う
- デバッグ print に絵文字プレフィクス（`📸`, `📊`, `✅`, `⚠️`, `🔄`）
- ロジックの「なぜ」を日本語で簡潔に。コードが語れることは書かない

**ファイル配置**
- 新 Service は `Services/` に単一責任で追加
- 新 ViewModel は `ViewModels/` に配置
- 画面をまたいで使う UI コンポーネントは `Views/Components/` に配置
- `MPMediaItem` への機能追加は `Models/MPMediaItem+SourceClassification.swift` に extension で追記
- デザイントークンの追加・変更は `App/AppTheme.swift` で行う

**UI 実装方針**
- SwiftUI のみ。UIKit は `UIViewControllerRepresentable` / `UIViewRepresentable` 経由のみ許可
- カスタムアニメーションは `TimelineView` + `Canvas` を使う（PersonalityBadgeView 参照）
- 波形描画は Catmull-Rom スプライン + `.screen` blendMode のパターンを踏襲
- ハプティクスは必ず `Haptics.play(.light/.medium/.heavy)` を使う（直接 UIImpactFeedbackGenerator を呼ばない）
- カラー・スペーシング・角丸・タイポグラフィは `AppTheme` の定数を使う（マジックナンバー禁止）

---

## Existing Features

| カテゴリ | 実装済み機能 |
|---------|------------|
| データ取得 | MPMediaQuery によるライブラリ全取得、差分検知・バックフィル、バッチ処理（50曲単位）|
| 分析 | 12種パーソナリティ判定、ジャンル分析、時間帯分析、CD vs Apple Music 比率 |
| ホーム | 統計グリッド（2×2カード）、パーソナリティバッジ、TOP5 楽曲、トップアーティスト |
| ランキング | 楽曲・アーティスト・アルバム別、横スワイプ切替、タブ切替時先頭スクロール、期間フィルタ、検索、初期表示マイクロアニメーション |
| レポート | 月別レポート（日別グラフ・前月比）、年間レポート（Wrapped 風ストーリー 7 ページ）|
| ストーリー演出 | 総再生数カウントアップ（イーズアウト）、パーソナリティ覚醒ページ（波形背景・グローリング・ネオンシャドウ）|
| QR 機能 | プロフィール QR 生成・スキャン（カメラ/写真ライブラリ）、4 軸相性スコア、バッジアニメーション |
| アートワーク | 手動変更（長押し）、Deezer→iTunes フォールバック、メモリ+ディスク双キャッシュ、アルバム複合キー管理、ローカル音源 iTunes スキップ |
| 共有 | シェアカード生成（10 位・パーソナリティ画像・QR 合成）、Instagram Story / X 対応 |
| パーソナリティ | ヒーローカード波形背景、横スワイプ探索モード（12 種一覧・下スワイプで閉じる）|
| ウィジェット | 今日の再生数・今週 TOP3・月間サマリー・時間帯ヒートマップ |
| Live Activity | ロック画面・Dynamic Island（再生中楽曲表示）|
| 通知 | 週次・月次レポート通知、久しぶりお気に入り通知 |
| 設定 | ユーザー名・アイコン、iCloud 同期トグル、通知 ON/OFF、履歴リセット |
| スプラッシュ | 波形パルス起動アニメーション、初回チュートリアルオーバーレイ |
| UI/UX | フローティングタブバー（iOS 26 Liquid Glass / iOS 17-25 カスタム Capsule）、AppTheme デザイントークン |
| 楽曲詳細 | YYYY/MM/DD 追加日、アーティスト/アルバム名タップで詳細画面遷移 |

---

## Current Status

**完成度：約 85〜90%（MVP として動作する状態）**

UIUX_IMPROVEMENT_PROPOSALS.md の全項目（★★★〜★☆☆）は実装完了。

**残タスク（技術的課題）**

| 項目 | 状態 | 備考 |
|------|------|------|
| Apple Developer 登録 | 未着手 | アプリ完成に近づいたら加入予定 |
| `.gitignore` に `GoogleService-Info.plist`, `*.p8` を追加 | 未着手 | Firebase/MusicKit key 追加前に必須 |
| App Store Connect で MusicKit private key 発行 | デベロッパー登録後 | アーティスト画像の品質向上 |
| Firebase 連携（Analytics・Crashlytics）| デベロッパー登録後 | |
| TestFlight でベータ配布 | デベロッパー登録後 | |
| ユニットテスト | 優先度低 | `PersonalityAnalysisEngine` / `CompatibilityEngine` は純粋関数が多く追加しやすい |
| 多言語対応 | 優先度低 | 現状日本語ハードコード |

**デベロッパー登録後の作業順序**
1. `.gitignore` に `GoogleService-Info.plist`, `*.p8` を追加してから commit
2. App Store Connect で MusicKit private key を発行
3. Firebase プロジェクト作成 → `GoogleService-Info.plist` をローカルのみに配置
4. TestFlight でベータ配布

---

## Constraints

**変更禁止・要注意箇所**

| ファイル・箇所 | 理由 |
|--------------|------|
| `PersonalityAnalysisEngine.swift` のスコア算出式 | 12種の判定バランスが崩れる。変更時は全パーソナリティで検証必須 |
| `PersonalityAnalysisEngine.swift` の排他グループ定義 | 同グループ内で複数パーソナリティが同時付与される不整合を防ぐ |
| `PlayHistoryTracker.swift` の差分検知・バックフィルロジック | アプリの根幹。バグると履歴データが破損する |
| `PlayHistoryTracker.swift` のバッチサイズ（50曲）・同期インターバル（30秒）| メモリ・パフォーマンスのバランス点 |
| `CompatibilityEngine.swift` の 4 軸重み付け（40/20/20/20%）| 相性スコアの一貫性に影響 |
| `QRCodeService.swift` の zlib 圧縮 + Base64URL + エラー訂正 H | QR 容量制限との密結合。変更するとスキャン不能になる |
| `PersistenceController.swift` の Core Data プログラマティック定義 | `.xcdatamodeld` は空。モデル変更は必ずここで行う |
| `MusicLibraryService.swift` のアルバム複合キー（`"\(albumTitle)//\(artistName)"`）| 変更するとアルバムアートワークキャッシュが崩れる |
| `sanko/` ディレクトリ | 参考実装のみ。アプリ本体に影響しない |

**設計整合性ルール**

- `isLocalAsset` の判定は必ず `MPMediaItem.isLocalAsset`（extension）を使う。直接 `assetURL` や `hasProtectedAsset` を個別に参照しない
- アートワーク取得は必ず `ArtworkService` 経由。`DeezerSearchService` / `iTunesSearchService` を View から直接呼ばない
- Core Data への書き込みは必ず `PlayHistoryTracker` または `PlayHistoryRepository` 経由
- ハプティクスは `Haptics.play()` のみ使用
- カラー・スペーシング等のデザイン値は `AppTheme` の定数を使う。マジックナンバーを直書きしない
- アルバムのキャッシュキーは必ず `"\(albumTitle)//\(artistName)"` 形式を維持する

---

## Development Guidelines

**新機能追加の方針**
1. UI 改善は `UIUX_IMPROVEMENT_PROPOSALS.md` を参照して優先度を確認する（全項目実装済みのため新規提案は直接議論）
2. 新しい分析軸を追加する場合は `PersonalityAnalysisEngine` の既存ロジックへの影響を確認
3. 外部 API を追加する場合は `Services/` に専用クラスを作成し、`ArtworkService` と同様に多段フォールバックを設計する
4. Core Data エンティティの追加・変更は `PersistenceController.swift` の `makeModel()` で行う（`.xcdatamodeld` ファイルは使わない）

**テスト方針**
- 現状ユニットテスト・UIテストなし
- `PersonalityAnalysisEngine` と `CompatibilityEngine` は純粋関数が多いため、将来的にユニットテストを追加しやすい
- `PlayHistoryTracker` のテストは Core Data のモック化が必要なため優先度低

**レビュー時の確認事項**
- `@MainActor` が必要な型に付いているか
- `ArtworkService` / `FavoriteService` などの Service を View から直接インスタンス化していないか
- `MPMediaItem.isLocalAsset` を使わず直接 `hasProtectedAsset` を参照していないか
- 新規 Canvas 描画で `.screen` blendMode の後に `.normal` に戻しているか
- カラー・スペーシング等に `AppTheme` を使っているか（マジックナンバーになっていないか）
