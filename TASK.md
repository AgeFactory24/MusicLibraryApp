#  Personality Icon Redesign Spec
### —— Waveform Universe 統一デザイン定義書 ——

## ■ 1. 目的
既存の12パーソナリティアイコンを、従来の「バッジ・人格・動物的表現」から脱却させ、**「音楽の行動履歴 ＝ 波形の振る舞い」**として統一されたビジュアル体系へ再設計する。

---

## ■ 2. デザインコンセプト（絶対遵守）

### 核心となる3要素
すべてのアイコンは、以下の要素のみで構成すること。
1. **Wave**（波形）
2. **Time Trail**（時間的残像）
3. **Energy Glow**（エネルギー発光）

###  禁止事項
具体性を排除し、抽象的な存在として表現するため、以下を一切使用しない。
* 人間・キャラクター表現
* 動物シルエット
* MBTI風アイコン
* 文字ベースのラベル依存デザイン
* SF Symbols単体使用（補助用途のみ可）

---

## ■ 3. 技術仕様
* **実装方式**: SwiftUI Canvas API（コード生成。画像アセットは禁止）
* **制御**: `TimelineView` または `withAnimation` による動的制御
* **スケーラビリティ**: 44pt / 64pt / 120pt の全サイズに対応

---

## ■ 4. 共通構造とパラメータ

### レイヤー構造
全アイコンは以下の4層構造で描画する。
1. **Layer 1**: Base Waveform Path（基本波形）
2. **Layer 2**: Variation Overlay（個性変化レイヤー）
3. **Layer 3**: Energy Glow Gradient（発光）
4. **Layer 4**: Motion Effect（回転 / 振動 / 流動）

### 制御4軸パラメータ
| パラメータ | 意味 |
| :--- | :--- |
| **frequency** | 波の速さ |
| **amplitude** | 振幅（強さ） |
| **density** | 波の密度 |
| **loopRatio** | 反復性 |

---

## ■ 5. 12パーソナリティ個別実装仕様

| ID | パーソナリティ | パラメータ特性 | 描画仕様・ビジュアル |
| :--- | :--- | :--- | :--- |
| 1 | **レジェンド** | freq: Med / amp: V.High / dens: High / loop: Stable | 中心を軸に完全対称の円環波形。太いラインとゴールド発光。 |
| 2 | **推しが本気** | freq: Low / amp: Extreme / dens: V.Low / loop: None | 1本の極端なピーク波形。中央に強い白熱光（white core glow）。 |
| 3 | **一点集中型** | freq: L-Med / amp: High / dens: Low / loop: Partial | 2〜3本の重なりが同一点で収束する構造。青白い集中光。 |
| 4 | **ヘビロテ職人** | freq: Med / amp: Med / dens: Med / loop: 100% | 完全円形ループ。同一波形が回転して重なる。紫系ネオン。 |
| 5 | **音楽探検家** | freq: High / amp: Variable / dens: Sparse / loop: None | ノイズ状拡散波形。外側にランダム拡張。緑〜シアンのグラデ。 |
| 6 | **固定リスナー** | freq: Low / amp: Stable / dens: Low / loop: Constant | 揺れがほぼない安定した1本波形。青単色のソフトグロー。 |
| 7 | **成長型リスナー** | freq: Incr / amp: Incr / dens: Incr / loop: Evolving | 複数レイヤーが成長。上層ほど濃く、時間方向に伸びる発光。 |
| 8 | **懐古リスナー** | freq: Low / amp: Fading / dens: Layered / loop: Memory | 過去波形の残像が重なるフェードレイヤー。セピア〜紫系。 |
| 9 | **ジャンル偏愛家** | freq: Narrow / amp: M-High / dens: V.High / loop: Repetitive | 特定周波数帯だけ極端に密集。横に圧縮された波形。赤系。 |
| 10 | **バランス型** | freq: Uniform / amp: Med / dens: Uniform / loop: Mild | 完全均一波形。円形または対称構造。多色かつ低彩度。 |
| 11 | **コレクター(CD)** | freq: Seg / amp: Layered / dens: Stacked / loop: Archive | ディスク積層構造。円盤状波形。レコード風ライン表現。 |
| 12 | **サブスク派** | freq: Fluid / amp: Dynamic / dens: Stream / loop: Continuous | 左から右へ流動するストリーム波形。水色〜白のグラデ。 |

---

## ■ 6. 運用ルール

### アニメーション
全アイコンは軽微に動作（回転、振動、流動、拍動）させること。動きは「音の振動」として表現する。

### カラーテーマ
* **Legend**: Gold / White
* **Focus系**: Blue / White
* **Explorer**: Green / Cyan
* **Nostalgia**: Purple / Sepia
* **Balanced**: 低彩度マルチカラー

### UI統一
* アイコンは中央配置。
* 不要な角丸装飾を禁止し、「波形オブジェクト」として扱う。

---

## ■ 最終意図（重要）
この設計の目的は、音楽履歴を「人格」ではなく**「波形の癖」**として可視化することにある。ユーザーの音楽体験そのものを、抽象的な波形存在として表現することを最終ゴールとする。