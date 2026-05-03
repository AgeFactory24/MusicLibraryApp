# 🎵 MusicLibrary　
## Apple Music × iOS Music Listening Analytics App

**MusicLibrary** は、Apple Music の再生情報をもとに、  
**楽曲・アーティストのランキングや統計情報を表示する iOS アプリ**です。

SwiftUI と MusicKit を中心に構成した、  
**個人開発・ポートフォリオ目的のプロジェクト**です。。

---

## 📌 アプリ開発のきっかけ

Apple Music を利用する中で特に不満に感じていたのが、  
**CD 音源として取り込んだ楽曲が Apple Music の Replay（ランキング）に一切反映されない**点でした。

好きなアーティストの CD を購入し、  **このサブスクリプション全盛の時代に、あえて音源を取り込み、  
PC から iPhone へ転送して聴いているにもかかわらず、**  それらの再生履歴が「存在しないもの」として扱われ、  
ランキングや統計の対象外になってしまうことに違和感を覚えました。

「せっかく聴いている音楽なのに、なぜ分析できないのか」  
「自分の音楽の聴き方を、もっと正確に振り返れないのか」

そう感じたことが、**MusicLibrary** 開発のきっかけです。

本アプリでは、
- Apple Music のストリーミング楽曲だけでなく
- CD 取り込み音源を含めた再生体験を整理・分析し
- アーティスト・アルバム・楽曲単位で可視化する

することで、**自分だけの音楽リスニング履歴を記録・分析できる仕組み**を目指しています。

また、分析したランキングや統計情報を  
**SNS などで共有できたら面白いのではないか**と考え、  
「個人で楽しむ」だけでなく「人に見せたくなる」体験も意識して設計しています。

Apple Music の API 制約がある中でも、  
取得可能なデータを最大限活用し、  
**制約下でどこまで価値ある分析体験を提供できるか**をテーマに開発しています。

本プロジェクトは、
- SwiftUI を用いた UI 構築
- MusicKit / ローカル音源の扱い
- MVVM による設計
- 音楽ドメイン特有の制約を踏まえた設計判断

を実践的に学ぶことを目的とした  
**iOS エンジニアとしてのスキル向上とポートフォリオ作成を兼ねた個人開発**です。

---

## 📱 アプリ概要

- Apple Music の認証を行い、音楽情報を取得
- 楽曲データをスキャン・管理
- 再生情報をもとにランキングや統計を表示
- 楽曲の詳細情報・アートワークを表示
- SwiftUI によるシンプルで Apple ライクな UI

---

## 🛠 使用技術

- **Swift 5.9+**
- **SwiftUI**
- **MusicKit**
- **MVVM アーキテクチャ**
- async / await
- ObservableObject
- iOS モーションセンサー（Core Motion）

---

## 🧱 アーキテクチャ

本アプリは **MVVM** をベースに設計しています。
```text
App
├─ Views        : UI 表示 (SwiftUI)
├─ Models       : データモデル
├─ Services     : MusicKit / スキャン処理
├─ Utilities    : Motion / 共通処理
```
UI とロジックを分離し、可読性と拡張性を意識しています。

---

## 📂 プロジェクト構成
```text
├── ranking_ProjectApp.swift  // アプリエントリーポイント
├── ContentView.swift         // メイン画面
├── StatsView.swift           // 統計・ランキング表示画面
├── MusicDetailView.swift     // 楽曲詳細画面
├── ArtworkView.swift         // アートワーク表示View
│
├── Models.swift              // 楽曲・統計用モデル
├── Item.swift                // 共通データモデル
│
├── MusicKitService.swift     // Apple Music 認証・取得処理
├── MusicScanService.swift    // 楽曲スキャン・管理処理
│
└── MotionManager.swift       // 端末モーションを利用したCDケース反射表現
```
---

## 🔐 Apple Music 認証について

本アプリは **MusicKit** を使用しています。

実行には以下が必要です。
1. Apple Developer Program への登録
2. Xcode の **Signing & Capabilities** にて  
   - **MusicKit** を有効化
3. **実機での実行**（※ シミュレーター不可）

---
