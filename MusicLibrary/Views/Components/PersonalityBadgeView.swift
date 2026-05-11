// PersonalityBadgeView.swift
// MusicLibrary — Waveform Universe  Dark BG + Neon Glow

import SwiftUI

// MARK: - PersonalityIconSymbol

struct PersonalityIconSymbol: View {
    let personality: Personality
    var size: CGFloat = 120

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            // phase: 0→1→0 pulse (period ≈ 3.2s), matches "sound vibration" feel
            let phase  = (sin(elapsed * .pi / 1.6) + 1) / 2
            // spin: linear degrees, one rotation every 6s
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

    // Neon accent color per personality
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
        case .obsessedFan:     ObsessedFanWave(size: size, phase: phase)
        case .singleFocus:     SingleFocusWave(size: size, phase: phase)
        case .heavyRotator:    HeavyRotatorWave(size: size, phase: phase, spin: spin)
        case .explorer:        ExplorerWave(size: size, phase: phase)
        case .loyalListener:   LoyalListenerWave(size: size, phase: phase)
        case .growingListener: GrowingListenerWave(size: size, phase: phase)
        case .nostalgic:       NostalgicWave(size: size, phase: phase)
        case .genreAddict:     GenreAddictWave(size: size, phase: phase)
        case .balanced:        BalancedWave(size: size, phase: phase, spin: spin)
        case .collector:       CollectorWave(size: size, phase: phase, spin: spin)
        case .streamingFan:    StreamingFanWave(size: size, phase: phase)
        }
    }
}

// MARK: - 1. レジェンド  ── 金粒子が2リングを周回

private struct LegendWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let c = Color(red: 1.0, green: 0.85, blue: 0.2)
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)
            let sr = CGFloat(spin * .pi / 180)

            // outer ring: 16 particles
            for i in 0..<16 {
                let a = CGFloat(i) * (2 * .pi / 16) + sr
                let brightness = 0.55 + CGFloat(sin(p * 2 * .pi + CGFloat(i) * 0.4)) * 0.4
                glowDot(&ctx, x: cx + cos(a)*40*s, y: cy + sin(a)*40*s,
                        r: 3.5*s, color: c.opacity(max(0.1, brightness)))
            }
            // inner ring: 8 particles (counter)
            for i in 0..<8 {
                let a = CGFloat(i) * (2 * .pi / 8) - sr * 0.7
                let brightness = 0.5 + CGFloat(sin(p * 2 * .pi + CGFloat(i) * 0.8)) * 0.4
                glowDot(&ctx, x: cx + cos(a)*22*s, y: cy + sin(a)*22*s,
                        r: 2.8*s, color: c.opacity(max(0.1, brightness)))
            }
            // center pulse
            glowDot(&ctx, x: cx, y: cy, r: (4 + p*2)*s, color: c.opacity(0.85 + p*0.15))
        }
    }
}

// MARK: - 2. 推しが本気  ── 極端な1本スパイク + 白熱コア

private struct ObsessedFanWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 1.0, green: 0.20, blue: 0.60)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let beat = CGFloat(abs(sin(phase * .pi * 2)))
            let spikeH = (50 + beat * 20) * s

            // Glow spike layers (wide → narrow)
            for (wMult, op): (CGFloat, Double) in [(5, 0.06), (3, 0.14), (1.5, 0.35), (1, 0.92)] {
                let w = (2.5 + beat) * s * wMult
                var p = Path()
                p.move(to: CGPoint(x: cx - w, y: cy + 6*s))
                p.addCurve(to: CGPoint(x: cx, y: cy - spikeH),
                           control1: CGPoint(x: cx - w, y: cy - spikeH * 0.4),
                           control2: CGPoint(x: cx - w * 0.3, y: cy - spikeH * 0.85))
                p.addCurve(to: CGPoint(x: cx + w, y: cy + 6*s),
                           control1: CGPoint(x: cx + w * 0.3, y: cy - spikeH * 0.85),
                           control2: CGPoint(x: cx + w, y: cy - spikeH * 0.4))
                ctx.fill(p, with: .color(c.opacity(op)))
            }
            // Tip incandescent core
            glowDot(&ctx, x: cx, y: cy - spikeH, r: (5 + beat*3)*s, color: .white.opacity(0.9 + beat*0.1))
        }
    }
}

// MARK: - 3. 一点集中型  ── 4本の波線が中心へ収束

private struct SingleFocusWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 0.3, green: 0.80, blue: 1.0)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)

            // 4 converging wave lines at 0°/45°/90°/135°
            for (i, angle) in [CGFloat(0), .pi/4, .pi/2, .pi*3/4].enumerated() {
                let pOff = p * 2 * .pi + CGFloat(i) * 0.9
                let path = makeConvergingPath(cx: cx, cy: cy, length: 108*s,
                                              angle: angle, amplitude: (10+p*4)*s,
                                              freq: 2.5, phaseOff: pOff)
                let op = 0.80 - Double(i) * 0.10
                glowStroke(&ctx, path: path, color: c, width: (2.8 - CGFloat(i)*0.3)*s, glow: 0.18, opacity: op)
            }
            // Center convergence glow
            glowDot(&ctx, x: cx, y: cy, r: (6 + p*2)*s, color: .white.opacity(0.95))
        }
    }
}

// MARK: - 4. ヘビロテ職人  ── 均等分割リングが反転回転する催眠ループ

private struct HeavyRotatorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let mainC = Color(red: 0.60, green: 0.10, blue: 0.95)   // 紫ネオン
    private let echoC = Color(red: 0.28, green: 0.12, blue: 0.88)   // 青紫

    var body: some View {
        Canvas { ctx, sz in
            let s   = sz.width / 140
            let cx  = sz.width / 2, cy = sz.height / 2
            let rot = CGFloat(spin * .pi / 180)   // 線形増加のみ — 折り返しなし

            // メインリング: 16セグメント、時計回り
            drawArcRing(&ctx, cx: cx, cy: cy, r: 44*s, n: 16, coverage: 0.60,
                        rotation: rot, color: mainC, lw: 2.2*s, glow: 0.16, opacity: 0.93)

            // エコー1: 12セグメント、反時計回り（干渉で催眠感）
            drawArcRing(&ctx, cx: cx, cy: cy, r: 34*s, n: 12, coverage: 0.55,
                        rotation: -rot * 0.75, color: echoC, lw: 1.6*s, glow: 0.12, opacity: 0.50)

            // エコー2: 10セグメント、ゆっくり時計回り — 中央は空白を保つ
            drawArcRing(&ctx, cx: cx, cy: cy, r: 25*s, n: 10, coverage: 0.50,
                        rotation: rot * 0.45, color: echoC, lw: 1.1*s, glow: 0.09, opacity: 0.24)
        }
    }
}

// MARK: - 5. 音楽探検家  ── 多色パーティクルが拡散

private struct ExplorerWave: View {
    let size: CGFloat; let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)

            // Fixed seed particle layout — 36 particles in 3 rings expanding with phase
            let colors: [Color] = [
                Color(red: 0.2, green: 0.9, blue: 0.5),
                Color(red: 0.6, green: 0.3, blue: 1.0),
                Color(red: 0.3, green: 0.85, blue: 1.0),
                Color(red: 1.0, green: 0.6, blue: 0.2),
            ]
            let configs: [(n: Int, baseR: CGFloat, rOff: CGFloat, rDot: CGFloat)] = [
                (8,  14, 6,  2.8),
                (12, 28, 10, 2.2),
                (16, 42, 14, 1.8),
            ]
            for (ri, cfg) in configs.enumerated() {
                for i in 0..<cfg.n {
                    let a = CGFloat(i) * (2 * .pi / CGFloat(cfg.n)) + p * 0.4 * CGFloat(ri + 1)
                    let r = (cfg.baseR + p * cfg.rOff) * s
                    let col = colors[(i + ri * 3) % colors.count]
                    let brightness = 0.5 + CGFloat(sin(p * 2 * .pi + CGFloat(i) * 0.5)) * 0.45
                    glowDot(&ctx, x: cx + cos(a)*r, y: cy + sin(a)*r,
                            r: cfg.rDot*s, color: col.opacity(max(0.15, brightness)))
                }
            }
            glowDot(&ctx, x: cx, y: cy, r: (3+p)*s, color: .white.opacity(0.8))
        }
    }
}

// MARK: - 6. 固定リスナー  ── 安定した1本の波形

private struct LoyalListenerWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 0.30, green: 0.60, blue: 1.0)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2

            // Subtle ring glow
            var ring = Path()
            ring.addArc(center: CGPoint(x: cx, y: cy), radius: 42*s,
                        startAngle: .zero, endAngle: .radians(2 * .pi), clockwise: false)
            ctx.stroke(ring, with: .color(c.opacity(0.18)), lineWidth: 1.5*s)

            // Single stable sine wave — very small amplitude, slow drift
            let amp = (5 + phase * 2) * s
            let path = makeHorizWavePath(x1: cx-50*s, x2: cx+50*s, cy: cy,
                                         amplitude: amp, freq: 1.5,
                                         phaseOff: CGFloat(phase * .pi * 0.6))
            glowStroke(&ctx, path: path, color: c, width: 2.8*s, glow: 0.25, opacity: 1.0)
        }
    }
}

// MARK: - 7. 成長型リスナー  ── 下から上へ成長する水平バー群

private struct GrowingListenerWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 0.20, green: 0.90, blue: 0.70)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)

            // 6 horizontal bars: bottom short/dim → top long/bright
            let bars: [(yOff: CGFloat, halfW: CGFloat, op: Double)] = [
                (28, 12, 0.22),
                (18, 20, 0.35),
                (8,  30, 0.50),
                (-2, 38, 0.65),
                (-12,44, 0.80),
                (-22,48, 0.95),
            ]
            for bar in bars {
                let hw = bar.halfW * s * (0.75 + p * 0.25)
                var path = Path()
                path.move(to: CGPoint(x: cx - hw, y: cy + bar.yOff*s))
                path.addLine(to: CGPoint(x: cx + hw, y: cy + bar.yOff*s))
                glowStroke(&ctx, path: path, color: c, width: 2.5*s,
                           glow: 0.20, opacity: bar.op + phase * 0.05)
            }
        }
    }
}

// MARK: - 8. 懐古リスナー  ── 過去波形の残像が重なる

private struct NostalgicWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 0.70, green: 0.40, blue: 0.90)
    private let w = Color(red: 0.92, green: 0.80, blue: 0.62) // sepia
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)

            // 4 echoes: most-faded (oldest) → bright (newest)
            let echoes: [(yOff: CGFloat, phAdd: CGFloat, op: Double, useSepia: Bool)] = [
                (16, 2.0, 0.16, true),
                ( 9, 1.3, 0.32, true),
                ( 3, 0.6, 0.54, false),
                ( 0, 0.0, 0.85, false),
            ]
            for echo in echoes {
                let yPos = cy - echo.yOff*s - p * echo.yOff * 0.35 * s
                let pOff = p * .pi * 2 - echo.phAdd
                let path = makeHorizWavePath(x1: cx-50*s, x2: cx+50*s, cy: yPos,
                                             amplitude: (9+p*2)*s, freq: 2, phaseOff: pOff)
                let col: Color = echo.useSepia ? w : c
                glowStroke(&ctx, path: path, color: col, width: (echo.op > 0.5 ? 2.5 : 1.6)*s,
                           glow: 0.15, opacity: echo.op)
            }
        }
    }
}

// MARK: - 9. ジャンル偏愛家  ── 狭帯域に密集した縦スパイク群

private struct GenreAddictWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 1.0, green: 0.32, blue: 0.10)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)

            // 12 vertical bars varying heights, narrow column
            let nBars = 12
            let totalW: CGFloat = 56 * s
            for i in 0..<nBars {
                let t = CGFloat(i) / CGFloat(nBars - 1)
                let x = cx - totalW/2 + t * totalW
                // Height envelope: taller in center
                let envelope = 1.0 - pow(abs(t - 0.5) * 1.8, 1.4)
                let h = max(4, (14 + envelope * 36 + CGFloat(sin(p * .pi * 2 + t * 8)) * 10)) * s
                var bar = Path()
                bar.move(to: CGPoint(x: x, y: cy + 2*s))
                bar.addLine(to: CGPoint(x: x, y: cy + 2*s - h))
                let op = 0.45 + envelope * 0.55
                glowStroke(&ctx, path: bar, color: c, width: 3*s, glow: 0.20, opacity: min(1, op))
            }
            // Bottom baseline
            var base = Path()
            base.move(to: CGPoint(x: cx - totalW/2 - 4*s, y: cy + 2*s))
            base.addLine(to: CGPoint(x: cx + totalW/2 + 4*s, y: cy + 2*s))
            ctx.stroke(base, with: .color(c.opacity(0.40)), lineWidth: 1.2*s)
        }
    }
}

// MARK: - 10. バランス型  ── 5色の同心円が穏やかに拍動・回転

private struct BalancedWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)
            let sr = CGFloat(spin * .pi / 180)

            // 5 concentric ring-waves, rainbow colors — each ring waves gently
            let rings: [(r: CGFloat, col: Color, wc: Int)] = [
                (44, Color(red: 1.0, green: 0.40, blue: 0.40), 6),
                (34, Color(red: 1.0, green: 0.80, blue: 0.25), 5),
                (25, Color(red: 0.40, green: 0.90, blue: 0.45), 4),
                (17, Color(red: 0.35, green: 0.70, blue: 1.00), 3),
                (9,  Color(red: 0.80, green: 0.40, blue: 1.00), 3),
            ]
            for (i, ring) in rings.enumerated() {
                let baseR = ring.r * s * (0.95 + p * 0.06)
                let amp   = ring.r * s * 0.04 * p
                let phOff = sr * 0.12 * CGFloat(i + 1)
                let path  = makeRingWavePath(cx: cx, cy: cy, baseR: baseR,
                                             amplitude: amp, waveCount: ring.wc, phaseOff: phOff)
                glowStroke(&ctx, path: path, color: ring.col, width: 2.2*s, glow: 0.22, opacity: 0.88)
            }
            glowDot(&ctx, x: cx, y: cy, r: (3+p)*s, color: .white.opacity(0.95))
        }
    }
}

// MARK: - 11. コレクター(CD派)  ── 同心環波形のディスク構造

private struct CollectorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    private let c = Color(red: 1.0, green: 0.78, blue: 0.30)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)
            let sr = CGFloat(spin * .pi / 180)

            let rings: [(r: CGFloat, cnt: Int, amp: CGFloat, op: Double, lw: CGFloat)] = [
                (47, 20, 1.5, 0.40, 1.4),
                (38, 16, 2.0, 0.55, 1.8),
                (30, 12, 2.5, 0.68, 2.1),
                (22, 10, 2.2, 0.80, 2.4),
                (14,  8, 1.8, 0.90, 2.8),
            ]
            for ring in rings {
                let path = makeRingWavePath(cx: cx, cy: cy, baseR: ring.r*s,
                                            amplitude: ring.amp*s*(1+p*0.4),
                                            waveCount: ring.cnt, phaseOff: sr*0.25)
                glowStroke(&ctx, path: path, color: c, width: ring.lw*s,
                           glow: 0.18, opacity: ring.op + p*0.08)
            }
            glowDot(&ctx, x: cx, y: cy, r: (5+p*2)*s, color: .white.opacity(0.95))
            glowDot(&ctx, x: cx, y: cy, r: 2*s, color: c.opacity(0.9))
        }
    }
}

// MARK: - 12. サブスク派  ── 左から右へ流れる4本のストリーム

private struct StreamingFanWave: View {
    let size: CGFloat; let phase: Double
    private let c = Color(red: 0.30, green: 0.85, blue: 1.0)
    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p  = CGFloat(phase)
            let flowOff = p * 2 * .pi * -1  // rightward flow

            let streams: [(yOff: CGFloat, amp: CGFloat, op: Double, lw: CGFloat)] = [
                (-20, 5,  0.40, 1.6),
                (-7,  9,  0.68, 2.4),
                (7,   9,  0.68, 2.4),
                (20,  5,  0.40, 1.6),
            ]
            for stream in streams {
                let path = makeHorizWavePath(x1: cx-52*s, x2: cx+52*s,
                                             cy: cy + stream.yOff*s,
                                             amplitude: stream.amp*s, freq: 1.5,
                                             phaseOff: flowOff)
                glowStroke(&ctx, path: path, color: c, width: stream.lw*s,
                           glow: 0.20, opacity: stream.op)
            }
            // Leading edge glow dots
            let dotX = cx - 52*s + p * 104*s
            for dy: CGFloat in [-20, -7, 7, 20] {
                glowDot(&ctx, x: dotX, y: cy+dy*s, r: 3*s,
                        color: .white.opacity(max(0, 0.7 - abs(Double(dy))/28.0 * 0.4)))
            }
        }
    }
}

// MARK: - Path Factories

private func makeHorizWavePath(x1: CGFloat, x2: CGFloat, cy: CGFloat,
                                amplitude: CGFloat, freq: CGFloat, phaseOff: CGFloat,
                                steps: Int = 80) -> Path {
    var path = Path()
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let pt = CGPoint(x: x1 + (x2 - x1)*t,
                         y: cy + amplitude * sin(2 * .pi * freq * t + phaseOff))
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    return path
}

private func makeRingWavePath(cx: CGFloat, cy: CGFloat, baseR: CGFloat,
                               amplitude: CGFloat, waveCount: Int, phaseOff: CGFloat,
                               steps: Int = 120) -> Path {
    var path = Path()
    for i in 0...steps {
        let a = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let r = baseR + amplitude * sin(CGFloat(waveCount) * a + phaseOff)
        let pt = CGPoint(x: cx + cos(a)*r, y: cy + sin(a)*r)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    return path
}

private func makeConvergingPath(cx: CGFloat, cy: CGFloat, length: CGFloat, angle: CGFloat,
                                 amplitude: CGFloat, freq: CGFloat, phaseOff: CGFloat,
                                 steps: Int = 80) -> Path {
    var path = Path()
    let px = -sin(angle), py = cos(angle)
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let dist = (t - 0.5) * length
        let base = CGPoint(x: cx + cos(angle)*dist, y: cy + sin(angle)*dist)
        let wave = amplitude * abs(t - 0.5) * 2 * sin(2 * .pi * freq * t + phaseOff)
        let pt = CGPoint(x: base.x + px*wave, y: base.y + py*wave)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    return path
}

// MARK: - Arc Ring Helper

/// n個の円弧セグメントを均等に円形配置して描画する（ヘビロテ職人専用）
private func drawArcRing(_ ctx: inout GraphicsContext,
                          cx: CGFloat, cy: CGFloat, r: CGFloat,
                          n: Int, coverage: CGFloat, rotation: CGFloat,
                          color: Color, lw: CGFloat, glow: Double, opacity: Double) {
    let step   = 2 * CGFloat.pi / CGFloat(n)
    let arcLen = step * coverage
    for i in 0..<n {
        let a = CGFloat(i) * step + rotation
        var seg = Path()
        seg.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                   startAngle: .radians(Double(a)),
                   endAngle:   .radians(Double(a + arcLen)),
                   clockwise: false)
        glowStroke(&ctx, path: seg, color: color, width: lw, glow: glow, opacity: opacity)
    }
}

// MARK: - Glow Helpers

private func glowDot(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r: CGFloat, color: Color) {
    ctx.fill(waveEllipse(cx: x, cy: y, w: r*5.5, h: r*5.5), with: .color(color.opacity(0.07)))
    ctx.fill(waveEllipse(cx: x, cy: y, w: r*3.2, h: r*3.2), with: .color(color.opacity(0.22)))
    ctx.fill(waveEllipse(cx: x, cy: y, w: r*1.7, h: r*1.7), with: .color(color.opacity(0.65)))
    ctx.fill(waveEllipse(cx: x, cy: y, w: r,     h: r),     with: .color(color.opacity(1.00)))
}

private func glowStroke(_ ctx: inout GraphicsContext, path: Path, color: Color,
                         width: CGFloat, glow: Double, opacity: Double) {
    ctx.stroke(path, with: .color(color.opacity(glow * 0.5)), lineWidth: width * 5.5)
    ctx.stroke(path, with: .color(color.opacity(glow * 1.2)), lineWidth: width * 3.0)
    ctx.stroke(path, with: .color(color.opacity(glow * 2.5)), lineWidth: width * 1.6)
    ctx.stroke(path, with: .color(color.opacity(opacity)),    lineWidth: width)
}

private func waveEllipse(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h))
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
