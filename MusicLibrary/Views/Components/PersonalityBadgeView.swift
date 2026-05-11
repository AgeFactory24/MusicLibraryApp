// PersonalityBadgeView.swift
// MusicLibrary — Waveform Universe · Organic Wave System

import SwiftUI

// MARK: - PersonalityIconSymbol

struct PersonalityIconSymbol: View {
    let personality: Personality
    var size: CGFloat = 120

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let phase  = (sin(elapsed * .pi / 1.6) + 1) / 2
            let spin   = elapsed / 6.0 * 360.0

            ZStack {
                Circle().fill(Color.black)
                    .frame(width: size, height: size)
                Circle()
                    .fill(RadialGradient(
                        colors: [neonColor.opacity(0.22), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.5))
                    .frame(width: size, height: size)
                iconLayer(phase: phase, spin: spin).frame(width: size, height: size)
            }
            .clipShape(Circle())
            .shadow(color: neonColor.opacity(0.6), radius: size * 0.1)
        }
    }

    private var neonColor: Color {
        switch personality {
        case .legend:          Color(red: 1.0, green: 0.82, blue: 0.20)
        case .obsessedFan:     Color(red: 1.0, green: 0.20, blue: 0.60)
        case .singleFocus:     Color(red: 0.30, green: 0.80, blue: 1.00)
        case .heavyRotator:    Color(red: 0.70, green: 0.20, blue: 1.00)
        case .explorer:        Color(red: 0.20, green: 0.90, blue: 0.50)
        case .loyalListener:   Color(red: 0.30, green: 0.60, blue: 1.00)
        case .growingListener: Color(red: 0.20, green: 0.90, blue: 0.70)
        case .nostalgic:       Color(red: 0.70, green: 0.40, blue: 0.90)
        case .genreAddict:     Color(red: 1.00, green: 0.30, blue: 0.10)
        case .balanced:        Color(red: 0.70, green: 0.80, blue: 0.95)
        case .collector:       Color(red: 1.00, green: 0.78, blue: 0.30)
        case .streamingFan:    Color(red: 0.30, green: 0.85, blue: 1.00)
        }
    }

    @ViewBuilder
    private func iconLayer(phase: Double, spin: Double) -> some View {
        switch personality {
        case .legend:          LegendWave(size: size, phase: phase, spin: spin)
        case .obsessedFan:     ObsessedFanWave(size: size, phase: phase, spin: spin)
        case .singleFocus:     SingleFocusWave(size: size, phase: phase, spin: spin)
        case .heavyRotator:    HeavyRotatorWave(size: size, phase: phase, spin: spin)
        case .explorer:        ExplorerWave(size: size, phase: phase, spin: spin)
        case .loyalListener:   LoyalListenerWave(size: size, phase: phase, spin: spin)
        case .growingListener: GrowingListenerWave(size: size, phase: phase, spin: spin)
        case .nostalgic:       NostalgicWave(size: size, phase: phase, spin: spin)
        case .genreAddict:     GenreAddictWave(size: size, phase: phase, spin: spin)
        case .balanced:        BalancedWave(size: size, phase: phase, spin: spin)
        case .collector:       CollectorWave(size: size, phase: phase, spin: spin)
        case .streamingFan:    StreamingFanWave(size: size, phase: phase, spin: spin)
        }
    }
}

// MARK: - 1. レジェンド ── ゴールドの王冠波形リング

private struct LegendWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let gold  = Color(red: 1.00, green: 0.82, blue: 0.20)
    private let white = Color(red: 1.00, green: 0.96, blue: 0.88)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 外側の王冠リング — outward で冠状スパイク
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 22, baseR: half*0.68, maxAmp: half*0.28,
                             speedBase: 0.28, waveDir:  1,
                             color: gold,  lw: s*2.2, opacity: 0.42, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: half*0.60, maxAmp: half*0.12,
                             speedBase: 0.36, waveDir: -1,
                             color: white, lw: s*1.6, opacity: 0.32, seed: 22)
            // 中央の発光核
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count:  8, baseR: half*0.20, maxAmp: half*0.12,
                             speedBase: 0.48, waveDir:  1,
                             color: gold,  lw: s*1.8, opacity: 0.52, seed: 34)
            ctx.blendMode = .normal
            var dot = Path()
            dot.addArc(center: CGPoint(x: cx, y: cy), radius: half*0.08,
                       startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(dot,   with: .color(gold.opacity(0.90)))
            ctx.stroke(dot, with: .color(white.opacity(0.95)), lineWidth: s*1.5)
            ctx.stroke(dot, with: .color(gold.opacity(0.40)),  lineWidth: s*6.0)
        }
    }
}

// MARK: - 2. 推しが本気 ── 中心爆発スパイク波形

private struct ObsessedFanWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let pink  = Color(red: 1.00, green: 0.12, blue: 0.52)
    private let white = Color(red: 1.00, green: 0.92, blue: 0.95)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 極端に高い振幅で中心から爆発的スパイク
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 10, baseR: half*0.08, maxAmp: half*0.70,
                             speedBase: 0.60, waveDir:  1,
                             color: pink,  lw: s*2.8, opacity: 0.42, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count:  8, baseR: half*0.06, maxAmp: half*0.38,
                             speedBase: 0.80, waveDir: -1,
                             color: white, lw: s*2.0, opacity: 0.38, seed: 10)
            ctx.blendMode = .normal
            var dot = Path()
            dot.addArc(center: CGPoint(x: cx, y: cy), radius: half*0.10,
                       startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(dot,   with: .color(white.opacity(0.95)))
            ctx.stroke(dot, with: .color(pink.opacity(0.70)), lineWidth: s*5.0)
        }
    }
}

// MARK: - 3. 一点集中型 ── 3層が中心へ収束する有機波形

private struct SingleFocusWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let cyan  = Color(red: 0.22, green: 0.78, blue: 1.00)
    private let white = Color(red: 0.85, green: 0.95, blue: 1.00)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 全層 inward で収束感
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 15, baseR: half*0.65, maxAmp: half*0.20,
                             speedBase: 0.38, waveDir: -1,
                             color: cyan,  lw: s*2.0, opacity: 0.38, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: half*0.44, maxAmp: half*0.16,
                             speedBase: 0.48, waveDir: -1,
                             color: white, lw: s*1.6, opacity: 0.36, seed: 15)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count:  8, baseR: half*0.24, maxAmp: half*0.10,
                             speedBase: 0.62, waveDir: -1,
                             color: cyan,  lw: s*1.2, opacity: 0.44, seed: 27)
            ctx.blendMode = .normal
            var dot = Path()
            dot.addArc(center: CGPoint(x: cx, y: cy), radius: half*0.08,
                       startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(dot,   with: .color(white.opacity(0.95)))
            ctx.stroke(dot, with: .color(cyan.opacity(0.60)), lineWidth: s*5.0)
        }
    }
}

// MARK: - 4. ヘビロテ職人 ── 有機的波形ループ（hebirote.html完全移植）

private struct HeavyRotatorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double

    var body: some View {
        Canvas { ctx, sz in
            let half  = sz.width / 2
            let cx    = half, cy = half
            let coreR = half * 0.50
            let s     = sz.width / 400
            let t     = CGFloat(spin / 60)

            let purple   = Color(red: 0.58, green: 0.20, blue: 0.93)
            let lavender = Color(red: 0.75, green: 0.52, blue: 0.99)
            let coreEdge = Color(red: 0.85, green: 0.53, blue: 0.99)

            ctx.blendMode = .screen
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 20, baseR: coreR*1.02, maxAmp: coreR*0.30,
                             speedBase: 0.35, waveDir:  1,
                             color: purple,   lw: s*2.0, opacity: 0.38, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: coreR*0.99, maxAmp: coreR*0.08,
                             speedBase: 0.55, waveDir: -1,
                             color: lavender, lw: s*1.0, opacity: 0.38, seed: 20)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count:  8, baseR: coreR*0.92, maxAmp: coreR*0.15,
                             speedBase: 0.42, waveDir: -1,
                             color: lavender, lw: s*1.0, opacity: 0.30, seed: 32)

            ctx.blendMode = .normal
            var core = Path()
            core.addArc(center: CGPoint(x: cx, y: cy), radius: coreR,
                        startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(core,   with: .color(.black))
            ctx.stroke(core, with: .color(coreEdge.opacity(0.82)), lineWidth: s*1.8)
            ctx.stroke(core, with: .color(purple.opacity(0.30)),    lineWidth: s*7.0)
        }
    }
}

// MARK: - 5. 音楽探検家 ── 3帯域に拡散する有機波形

private struct ExplorerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let green = Color(red: 0.15, green: 0.88, blue: 0.45)
    private let cyan  = Color(red: 0.20, green: 0.82, blue: 0.95)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 外側 — 散逸 outward
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 16, baseR: half*0.78, maxAmp: half*0.16,
                             speedBase: 0.55, waveDir:  1,
                             color: green, lw: s*1.8, opacity: 0.35, seed: 0)
            // 中間 — やや広がり
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 14, baseR: half*0.55, maxAmp: half*0.22,
                             speedBase: 0.45, waveDir:  1,
                             color: cyan,  lw: s*1.6, opacity: 0.35, seed: 16)
            // 内側 — inward で核へ向かう
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 10, baseR: half*0.32, maxAmp: half*0.20,
                             speedBase: 0.62, waveDir: -1,
                             color: green, lw: s*1.4, opacity: 0.30, seed: 30)
        }
    }
}

// MARK: - 6. 固定リスナー ── 安定した低振幅の単一リング

private struct LoyalListenerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let blue = Color(red: 0.20, green: 0.55, blue: 1.00)
    private let sky  = Color(red: 0.50, green: 0.78, blue: 1.00)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 極めて低振幅 → ほぼ平坦・安定感
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 18, baseR: half*0.60, maxAmp: half*0.055,
                             speedBase: 0.20, waveDir:  1,
                             color: blue, lw: s*2.6, opacity: 0.48, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: half*0.52, maxAmp: half*0.040,
                             speedBase: 0.16, waveDir: -1,
                             color: sky,  lw: s*1.6, opacity: 0.36, seed: 18)
        }
    }
}

// MARK: - 7. 成長型リスナー ── 内から外へ段階的に成長する波形

private struct GrowingListenerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let teal    = Color(red: 0.15, green: 0.88, blue: 0.68)
    private let emerald = Color(red: 0.18, green: 0.72, blue: 0.52)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 内側の種 (小)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 10, baseR: half*0.22, maxAmp: half*0.12,
                             speedBase: 0.52, waveDir:  1,
                             color: teal,    lw: s*1.2, opacity: 0.28, seed: 0)
            // 中間の成長 (中)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 14, baseR: half*0.44, maxAmp: half*0.18,
                             speedBase: 0.42, waveDir:  1,
                             color: emerald, lw: s*1.8, opacity: 0.36, seed: 10)
            // 外側の成熟 (大・最も明るい)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 18, baseR: half*0.65, maxAmp: half*0.22,
                             speedBase: 0.32, waveDir:  1,
                             color: teal,    lw: s*2.2, opacity: 0.42, seed: 24)
        }
    }
}

// MARK: - 8. 懐古リスナー ── 3層フェード残像波形

private struct NostalgicWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let purple   = Color(red: 0.65, green: 0.35, blue: 0.88)
    private let sepia    = Color(red: 0.88, green: 0.72, blue: 0.52)
    private let lavender = Color(red: 0.82, green: 0.65, blue: 0.98)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 過去(最遠・最薄)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: half*0.72, maxAmp: half*0.16,
                             speedBase: 0.22, waveDir:  1,
                             color: sepia,   lw: s*1.2, opacity: 0.22, seed: 0)
            // 中間残像
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 12, baseR: half*0.55, maxAmp: half*0.15,
                             speedBase: 0.28, waveDir: -1,
                             color: purple,  lw: s*1.6, opacity: 0.34, seed: 12)
            // 現在(最近・最明)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 10, baseR: half*0.38, maxAmp: half*0.14,
                             speedBase: 0.36, waveDir:  1,
                             color: lavender,lw: s*2.0, opacity: 0.44, seed: 24)
        }
    }
}

// MARK: - 9. ジャンル偏愛家 ── 狭帯域に密集した高密度リング

private struct GenreAddictWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let red    = Color(red: 0.95, green: 0.22, blue: 0.08)
    private let orange = Color(red: 1.00, green: 0.55, blue: 0.10)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 20, baseR: half*0.64, maxAmp: half*0.10,
                             speedBase: 0.48, waveDir:  1,
                             color: red,    lw: s*2.0, opacity: 0.42, seed: 0)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 18, baseR: half*0.57, maxAmp: half*0.09,
                             speedBase: 0.58, waveDir: -1,
                             color: orange, lw: s*1.8, opacity: 0.40, seed: 20)
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 10, baseR: half*0.50, maxAmp: half*0.06,
                             speedBase: 0.70, waveDir:  1,
                             color: red,    lw: s*1.5, opacity: 0.30, seed: 38)
            // 帯域の境界を示すコアリング
            ctx.blendMode = .normal
            var ring = Path()
            ring.addArc(center: CGPoint(x: cx, y: cy), radius: half*0.38,
                        startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(ring,   with: .color(.black))
            ctx.stroke(ring, with: .color(red.opacity(0.75)),    lineWidth: s*1.8)
            ctx.stroke(ring, with: .color(orange.opacity(0.28)), lineWidth: s*6.0)
        }
    }
}

// MARK: - 10. バランス型 ── 5色の均等同心有機リング

private struct BalancedWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 5色リング — 低彩度マルチカラー、均等間隔
            let rings: [(r: CGFloat, col: Color, dir: CGFloat, sd: Int)] = [
                (half*0.78, Color(red: 0.88, green: 0.40, blue: 0.40),  1, 0),
                (half*0.61, Color(red: 0.90, green: 0.75, blue: 0.22), -1, 8),
                (half*0.44, Color(red: 0.32, green: 0.82, blue: 0.48),  1, 16),
                (half*0.28, Color(red: 0.30, green: 0.60, blue: 0.95), -1, 24),
                (half*0.13, Color(red: 0.72, green: 0.35, blue: 0.90),  1, 32),
            ]
            for ring in rings {
                organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                                 count: 8, baseR: ring.r, maxAmp: half*0.07,
                                 speedBase: 0.30 + ring.r/half * 0.10,
                                 waveDir: ring.dir,
                                 color: ring.col, lw: s*2.0, opacity: 0.40,
                                 seed: ring.sd)
            }
        }
    }
}

// MARK: - 11. コレクター(CD派) ── レコード溝のような多重同心リング

private struct CollectorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let gold      = Color(red: 0.95, green: 0.72, blue: 0.28)
    private let warmWhite = Color(red: 1.00, green: 0.95, blue: 0.85)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 外周溝
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 22, baseR: half*0.80, maxAmp: half*0.055,
                             speedBase: 0.18, waveDir:  1,
                             color: gold,      lw: s*1.5, opacity: 0.38, seed: 0)
            // 中間溝
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 20, baseR: half*0.62, maxAmp: half*0.055,
                             speedBase: 0.20, waveDir: -1,
                             color: warmWhite, lw: s*1.5, opacity: 0.35, seed: 22)
            // 内周溝
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count: 16, baseR: half*0.44, maxAmp: half*0.055,
                             speedBase: 0.22, waveDir:  1,
                             color: gold,      lw: s*1.5, opacity: 0.30, seed: 42)
            // レーベル部分
            organicRingGroup(&ctx, cx: cx, cy: cy, t: t,
                             count:  6, baseR: half*0.22, maxAmp: half*0.040,
                             speedBase: 0.28, waveDir: -1,
                             color: warmWhite, lw: s*1.8, opacity: 0.42, seed: 58)
            // スピンドル穴
            ctx.blendMode = .normal
            var dot = Path()
            dot.addArc(center: CGPoint(x: cx, y: cy), radius: half*0.07,
                       startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.fill(dot,   with: .color(.black))
            ctx.stroke(dot, with: .color(gold.opacity(0.85)), lineWidth: s*2.0)
        }
    }
}

// MARK: - 12. サブスク派 ── 左から右へ流動するストリーム波形

private struct StreamingFanWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let cyan  = Color(red: 0.20, green: 0.82, blue: 1.00)
    private let white = Color(red: 0.80, green: 0.95, blue: 1.00)
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            // 4本のストリームを異なるy位置で
            let streams: [(yOff: CGFloat, col: Color, op: Double, sd: Int)] = [
                (-half*0.32, cyan,  0.34,  0),
                (-half*0.11, white, 0.44, 10),
                ( half*0.11, white, 0.44, 20),
                ( half*0.32, cyan,  0.34, 30),
            ]
            for stream in streams {
                organicStreamGroup(&ctx, cx: cx, yCenter: cy + stream.yOff,
                                   halfW: half*0.82, t: t,
                                   count: 10, maxAmp: half*0.055,
                                   speedBase: 0.50,
                                   color: stream.col, lw: s*2.0,
                                   opacity: stream.op, seed: stream.sd)
            }
        }
    }
}

// MARK: - Organic Ring Helpers

private func organicRingGroup(_ ctx: inout GraphicsContext,
                               cx: CGFloat, cy: CGFloat,
                               t: CGFloat, count: Int,
                               baseR: CGFloat, maxAmp: CGFloat,
                               speedBase: CGFloat, waveDir: CGFloat,
                               color: Color, lw: CGFloat, opacity: Double, seed: Int) {
    for i in 0..<count {
        let f   = CGFloat(i + seed)
        let ph  = f * CGFloat.pi * 1.6180339887
        let spd = speedBase + f.truncatingRemainder(dividingBy: 7) * 0.09
        let v0  = 0.28 + f.truncatingRemainder(dividingBy: 5) * 0.13
        let v1  = 0.52 + f.truncatingRemainder(dividingBy: 7) * 0.08
        let v2  = 0.81 + f.truncatingRemainder(dividingBy: 4) * 0.08
        let ds  = (sin(t*v0 + f*1.10) + sin(t*v1 + f*2.30) + sin(t*v2 + f*3.70)) / 3
        let scl = CGFloat((ds + 1) * 0.5)
        let rotSpd = (f.truncatingRemainder(dividingBy: 11) - 5.0) / 5.0 * 0.048
        let detPh  = t * spd + ph
        let jitPh  = -(t * spd * 0.8) + ph * 1.3
        let path = makeOrganicRingPath(cx: cx, cy: cy, baseR: baseR, maxAmp: maxAmp,
                                       detPh: detPh, jitPh: jitPh,
                                       scale: scl, rot: t * rotSpd, dir: waveDir)
        ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lw)
    }
}

private func makeOrganicRingPath(cx: CGFloat, cy: CGFloat,
                                  baseR: CGFloat, maxAmp: CGFloat,
                                  detPh: CGFloat, jitPh: CGFloat,
                                  scale: CGFloat, rot: CGFloat, dir: CGFloat,
                                  segs: Int = 20) -> Path {
    var pts = [CGPoint](); pts.reserveCapacity(segs)
    for n in 0..<segs {
        let a   = CGFloat(n) / CGFloat(segs) * 2 * .pi
        let det = sin(a * 6 + detPh) * 0.7
        let jit = sin(a * 12 + jitPh) * 0.1
        let r   = baseR + (det + jit) * maxAmp * scale * dir
        let fa  = a + rot
        pts.append(CGPoint(x: cx + r * cos(fa), y: cy + r * sin(fa)))
    }
    return catmullRomClosed(pts)
}

private func catmullRomClosed(_ pts: [CGPoint]) -> Path {
    let n = pts.count; guard n >= 2 else { return Path() }
    var path = Path(); path.move(to: pts[0])
    for i in 0..<n {
        let p0 = pts[(i - 1 + n) % n]; let p1 = pts[i]
        let p2 = pts[(i + 1) % n];     let p3 = pts[(i + 2) % n]
        let cp1 = CGPoint(x: p1.x + (p2.x - p0.x)/6, y: p1.y + (p2.y - p0.y)/6)
        let cp2 = CGPoint(x: p2.x - (p3.x - p1.x)/6, y: p2.y - (p3.y - p1.y)/6)
        path.addCurve(to: p2, control1: cp1, control2: cp2)
    }
    path.closeSubpath(); return path
}

// MARK: - Organic Stream Helpers (サブスク派専用)

private func organicStreamGroup(_ ctx: inout GraphicsContext,
                                 cx: CGFloat, yCenter: CGFloat,
                                 halfW: CGFloat, t: CGFloat,
                                 count: Int, maxAmp: CGFloat,
                                 speedBase: CGFloat,
                                 color: Color, lw: CGFloat, opacity: Double, seed: Int) {
    for i in 0..<count {
        let f   = CGFloat(i + seed)
        let ph  = f * CGFloat.pi * 1.6180339887
        let spd = speedBase + f.truncatingRemainder(dividingBy: 7) * 0.08
        let v0  = 0.28 + f.truncatingRemainder(dividingBy: 5) * 0.13
        let v1  = 0.52 + f.truncatingRemainder(dividingBy: 7) * 0.08
        let ds  = (sin(t*v0 + f*1.10) + sin(t*v1 + f*2.30)) / 2
        let scl = CGFloat((ds + 1) * 0.5)
        // 右方向への流動 (flowPh 減少 = ピークが右へ移動)
        let flowPh = -(t * spd) + ph
        let path = makeOrganicStreamPath(cx: cx, yCenter: yCenter, halfW: halfW,
                                          maxAmp: maxAmp, flowPh: flowPh, scale: scl)
        ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lw)
    }
}

private func makeOrganicStreamPath(cx: CGFloat, yCenter: CGFloat,
                                    halfW: CGFloat, maxAmp: CGFloat,
                                    flowPh: CGFloat, scale: CGFloat,
                                    segs: Int = 40) -> Path {
    var pts = [CGPoint](); pts.reserveCapacity(segs)
    let x0 = cx - halfW, x1 = cx + halfW
    for n in 0..<segs {
        let u   = CGFloat(n) / CGFloat(segs - 1)
        let x   = x0 + (x1 - x0) * u
        let det = sin(u * .pi * 6 + flowPh) * 0.7
        let jit = sin(u * .pi * 12 + flowPh * 1.3) * 0.1
        let y   = yCenter + (det + jit) * maxAmp * scale
        pts.append(CGPoint(x: x, y: y))
    }
    return catmullRomOpen(pts)
}

private func catmullRomOpen(_ pts: [CGPoint]) -> Path {
    let n = pts.count; guard n >= 2 else { return Path() }
    var path = Path(); path.move(to: pts[0])
    for i in 0..<(n - 1) {
        let p0 = pts[max(0, i - 1)]; let p1 = pts[i]
        let p2 = pts[i + 1];          let p3 = pts[min(n - 1, i + 2)]
        let cp1 = CGPoint(x: p1.x + (p2.x - p0.x)/6, y: p1.y + (p2.y - p0.y)/6)
        let cp2 = CGPoint(x: p2.x - (p3.x - p1.x)/6, y: p2.y - (p3.y - p1.y)/6)
        path.addCurve(to: p2, control1: cp1, control2: cp2)
    }
    return path
}

// MARK: - PersonalityBadgeView

struct PersonalityBadgeView: View {
    let personality: ListenerPersonality
    var size: CGFloat = 120

    var body: some View {
        if let p = Personality.allCases.first(where: { $0.rawValue == personality.title }) {
            PersonalityIconSymbol(personality: p, size: size)
        } else {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: personality.gradient,
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size, height: size)
                    .shadow(color: (personality.gradient.first ?? .purple).opacity(0.4),
                            radius: size * 0.12)
                Text(personality.emoji).font(.system(size: size * 0.38))
            }
        }
    }
}

// MARK: - PersonalityInlineRow

struct PersonalityInlineRow: View {
    let personality: ListenerPersonality
    var reason: String = ""
    var badgeSize: CGFloat = 72

    var body: some View {
        HStack(spacing: 16) {
            PersonalityBadgeView(personality: personality, size: badgeSize)
            VStack(alignment: .leading, spacing: 4) {
                Text("今期のパーソナリティ")
                    .font(.caption).foregroundStyle(.secondary)
                Text(personality.title).font(.headline.bold())
                Text(personality.description)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                if !reason.isEmpty {
                    Text(reason)
                        .font(.caption).foregroundStyle(.pink.opacity(0.85))
                        .lineLimit(3).padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
