# MusicLibrary 同期基盤改善 実装指示書

## 概要

Apple Music / MediaPlayer API の制約上、リアルタイム再生履歴取得は不可能。

そのため本アプリでは、

- MPMediaItem.playCount
- lastPlayedDate

を利用した差分同期方式を採用している。

ただし現状は、

- アプリ起動時のみ同期
- フルスキャン中心
- バックグラウンド同期弱い

という課題がある。

本タスクでは、

# 「iOS 制約下で同期頻度と精度を最大化する」

ことを目的として以下を実装する。

---

# 実装対象

## 1. scenePhase active 同期（最優先）

## 目的

アプリ起動時だけでなく、
バックグラウンド復帰時にも同期を実施する。

ユーザーはアプリを完全終了しないケースが多いため、
scenePhase == .active で同期する。

---

## 実装内容

### ContentView または App Root

swift @Environment(\.scenePhase) private var scenePhase 

swift .onChange(of: scenePhase) { phase in     guard phase == .active else { return }      Task {         await playHistoryTracker.performForegroundSync()     } } 

---

## 要件

- 多重同期防止
- 連続 active 遷移で短時間に何度も走らない
- 5分以内の再同期はスキップ

---

## 実装方針

### PlayHistoryTracker

swift @MainActor final class PlayHistoryTracker: ObservableObject {     private var lastSyncDate: Date?     private var isSyncing = false      func performForegroundSync() async {         guard !isSyncing else { return }          if let lastSyncDate,            Date().timeIntervalSince(lastSyncDate) < 300 {             return         }          isSyncing = true         defer {             isSyncing = false             lastSyncDate = Date()         }          await performLightweightDiffScan()     } } 

---

# 2. BGTaskScheduler 補助同期

## 目的

アプリ未起動期間でも、
iOS が許可したタイミングで軽量同期を実施する。

---

## 注意

BGTask は定期実行保証ではない。

- 実行されない場合あり
- OS が頻度を決定
- 重い処理をすると次回以降呼ばれにくくなる

そのため、

# 「軽量同期専用」

として実装する。

---

## Capabilities

Background Modes:

- Background fetch

を有効化。

---

## Info.plist

xml <key>BGTaskSchedulerPermittedIdentifiers</key> <array>     <string>com.yourapp.musiclibrary.sync</string> </array> 

---

## 登録処理

### MusicLibraryApp.swift

swift BGTaskScheduler.shared.register(     forTaskWithIdentifier: "com.yourapp.musiclibrary.sync",     using: nil ) { task in     guard let task = task as? BGAppRefreshTask else { return }      Task {         await BackgroundSyncManager.shared.handle(task: task)     } } 

---

## スケジュール

swift func scheduleRefresh() {     let request = BGAppRefreshTaskRequest(         identifier: "com.yourapp.musiclibrary.sync"     )      request.earliestBeginDate = Date(         timeIntervalSinceNow: 60 * 60     )      do {         try BGTaskScheduler.shared.submit(request)     } catch {         print(error)     } } 

---

## タスク実行

swift func handle(task: BGAppRefreshTask) async {      scheduleRefresh()      let operation = Task {         await PlayHistoryTracker.shared.performBackgroundSync()     }      task.expirationHandler = {         operation.cancel()     }      await operation.value      task.setTaskCompleted(success: true) } 

---

# 3. Widget Refresh 軽量同期

## 目的

Widget 更新タイミングを利用して、
接触頻度と同期機会を増やす。

---

## 注意

Widget は制約が厳しい。

- 実行時間短い
- メモリ制限厳しい
- フル同期禁止

---

## 実装内容

Widget Timeline 更新時に:

swift await PlayHistoryTracker.shared.performWidgetSync() 

を実施。

---

## Widget Sync 要件

### 軽量限定

以下のみ実施:

- 最近再生された楽曲のみ確認
- 最大100曲
- playCount比較のみ

禁止:

- フルライブラリ走査
- バックフィル
- 大量 Core Data 書き込み

---

## Widget Sync 目的

- 完全同期ではない
- 接触頻度向上
- データ鮮度改善

---

# 4. Notification 起動誘導

## 目的

ユーザーのアプリ起動頻度を増やし、
結果的に同期精度を高める。

---

## 通知設計

### NG

単なる宣伝通知。

---

### OK

「分析更新」を通知。

例:

- 今週のTOP楽曲が更新されました
- 月別レポートを確認できます
- 新しい音楽パーソナリティが判定されました

---

## 実装方針

### NotificationService

以下追加:

swift func scheduleEngagementNotification() 

---

## 条件

以下を満たす場合のみ:

- 48時間以上未起動
- 新しい差分履歴あり
- 通知許可済み

---

## 重視点

通知目的は:

# 「同期精度向上のための起動誘導」

であり、
広告ではない。

---

# 5. 軽量差分スキャン

## 最重要改善

現状の:

text 全楽曲走査 

を改善する。

---

# 目的

バックグラウンド実行でも
OS に kill されにくい同期を実現する。

---

# 実装方針

## performLightweightDiffScan()

新規実装。

---

## 対象楽曲

優先順位:

1. lastPlayedDate が新しい
2. playCount が高い
3. 最近差分が発生した
4. お気に入り楽曲

---

## 上限

swift maxTracks = 100 

---

## 処理内容

以下のみ:

- playCount取得
- 前回値比較
- 差分記録

禁止:

- フルバックフィル
- 履歴再生成
- 重い集計

---

## Core Data 最適化

### 必須

- Background Context 使用
- 50件ごと save
- save後 reset()

---

## 例

swift bgContext.save() bgContext.reset() 

---

# 6. 同期状態UI

## 目的

ユーザーに:

- データ鮮度
- 精度
- 最終同期

を可視化する。

---

## 表示例

text 最終同期: 2時間前 同期状態: 高精度 

---

## 要件

表示場所:

- Home
- Monthly Report

---

# 7. ログ・計測

## 必須

同期改善ではログが重要。

---

## OSLog

導入:

swift import OSLog 

---

## 計測内容

- 同期時間
- 同期対象件数
- 差分件数
- BGTask 成功率
- Widget sync 実行回数
- キャンセル回数

---

# 非目標（重要）

以下は今回実装しない:

- 完全リアルタイム同期
- Spotify級履歴精度
- 常時バックグラウンド監視
- 音楽再生イベント完全取得

理由:

iOS / MusicKit 制約上不可能。

---

# 期待する成果

## Before

- アプリ起動時のみ同期
- 精度低下しやすい
- 長期未起動に弱い

---

## After

- foreground復帰で自動同期
- BGTask補助同期
- Widget経由同期
- 起動誘導通知
- 軽量差分スキャン
- 同期鮮度改善
- OS制約下での最適化

---

# 実装優先順位

## Phase 1（必須）

1. scenePhase active 同期
2. 軽量差分スキャン
3. BGTaskScheduler

---

## Phase 2

4. Widget Sync
5. Notification 起動誘導

---

## Phase 3

6. 同期状態UI
7. OSLog計測

---

# 重要設計思想

本アプリは:

# 「完全同期アプリ」

ではなく、

# 「iOS制約下で最も自然に音楽履歴を振り返れるアプリ」

を目指す。

そのため:

- 完全精度
- リアルタイム性

より、

- 継続利用
- データ鮮度
- ユーザー納得感

を重視すること。