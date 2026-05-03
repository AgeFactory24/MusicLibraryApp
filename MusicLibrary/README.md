# MusicLibrary

Apple Music × iOS Music Listening Analytics App

CD取り込み音源を含めた再生体験を整理・分析・可視化するiOSアプリです。

## 📁 プロジェクト構成

```
MusicLibrary/
├── App/
│   ├── MusicLibraryApp.swift        # アプリエントリーポイント
│   └── ContentView.swift             # ルートView/タブバー
├── Models/
│   ├── Track.swift                   # 楽曲モデル
│   ├── Artist.swift                  # アーティストモデル
│   ├── Album.swift                   # アルバムモデル
│   └── PlayHistoryEntry.swift        # CoreDataエンティティ + 表示用struct
├── Persistence/
│   ├── PersistenceController.swift   # CoreData (App Group共有)
│   └── PlayHistoryRepository.swift   # 履歴クエリ
├── Services/
│   ├── MusicAuthService.swift        # MusicKit認証
│   ├── MusicLibraryService.swift     # MPMediaQuery
│   ├── ArtworkService.swift          # アートワーク管理 (手動変更対応)
│   ├── PlayHistoryTracker.swift      # 差分検知による履歴記録
│   └── ShareImageRenderer.swift      # SwiftUI→UIImage変換
├── ViewModels/
│   ├── LibraryViewModel.swift
│   ├── RankingViewModel.swift
│   ├── StatisticsViewModel.swift
│   ├── MonthlyReportViewModel.swift
│   ├── TimeOfDayViewModel.swift
│   └── TrackDetailViewModel.swift
├── Views/
│   ├── Auth/AuthorizationView.swift
│   ├── Home/HomeView.swift
│   ├── Ranking/
│   │   ├── RankingView.swift
│   │   └── RankingRowView.swift
│   ├── Library/LibraryView.swift
│   ├── Statistics/StatisticsView.swift
│   ├── MonthlyReport/MonthlyReportView.swift
│   ├── TimeOfDay/TimeOfDayView.swift
│   ├── TrackDetail/TrackDetailView.swift
│   ├── Share/ShareCardView.swift
│   └── Components/
│       ├── ArtworkView.swift
│       ├── EditableArtworkView.swift
│       └── StatCardView.swift
├── Widget/
│   ├── MusicLibraryWidgetBundle.swift
│   ├── TodayPlaysWidget.swift
│   └── WeeklyTopWidget.swift
└── Resources/
    └── Info.plist.additions.xml
```

## 🚀 セットアップ手順

### 1. Xcodeプロジェクト作成
- iOS App テンプレートで新規作成
- Interface: **SwiftUI**
- Language: **Swift**
- Minimum Deployment: **iOS 17.0**

### 2. 全Swiftファイルをドラッグ&ドロップ
本リポジトリの `MusicLibrary/` 配下を Xcode にドラッグ。

### 3. Capabilities を有効化
- **App Groups**: `group.com.yourcompany.MusicLibrary` を作成
- **Apple Music** (MusicKit)

### 4. Info.plist に以下を追加
```xml
<key>NSAppleMusicUsageDescription</key>
<string>音楽ライブラリの再生情報を分析するために使用します</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>アーティスト・アルバム画像のカスタマイズに使用します</string>
```

### 5. Widget Extension を追加
- File → New → Target → **Widget Extension**
- Widget Target にも **App Groups** を追加（同じID）
- 共有が必要なファイルを Widget Target にも追加:
  - `Persistence/PersistenceController.swift`
  - `Models/PlayHistoryEntry.swift`
- `Widget/` 配下のファイルは Widget Target のみに含める

### 6. PersistenceController.swift の App Group ID を変更
```swift
static let appGroupID = "group.com.yourcompany.MusicLibrary"
```
↑ あなたが作成した実際のIDに変更

## 🎯 実装機能

| 機能 | 説明 |
|---|---|
| **Core Data履歴** | playCountの差分検知でApple Music Replayより正確な履歴を記録 |
| **手動アートワーク** | アーティスト・アルバム画像を写真ライブラリから差し替え可能 |
| **月別レポート** | 前月比・日別グラフ・TOP楽曲を集約 |
| **時間帯分析** | 「朝の人 / 夜更かし派」などラベル化 |
| **楽曲詳細画面** | 折れ線グラフで再生履歴の推移を可視化 |
| **SNSシェアカード** | 5種テーマ・Instagram Story比率(1080×1920)で書き出し |
| **ウィジェット** | 「今日の再生数」「週間TOP3」をホーム画面表示 |

## 📌 アプリのコンセプト

Apple Music の Replay 機能では CD取り込み音源の再生履歴が反映されません。
本アプリは `MPMediaQuery` を使うことで、CD音源も含めた全再生履歴を分析できます。

さらに `playCount` の差分を Core Data に記録することで、
Apple Musicが提供する `lastPlayedDate` だけでは取れない時系列データを蓄積し、
時間帯分析・月別比較・楽曲ごとの再生推移グラフを実現しています。
