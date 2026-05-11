// PersonalityBadgeView.swift
// MusicLibrary — Waveform Universe Design System

import SwiftUI

// MARK: - PersonalityIconSymbol

struct PersonalityIconSymbol: View {
    let personality: Personality
    var size: CGFloat = 120
    var animated: Bool = false

    @State private var phase: Double = 0
    @State private var spin: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: personality.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .shadow(color: (personality.gradient.first ?? .pink).opacity(0.4),
                        radius: size * 0.12)
            iconLayer
                .frame(width: size, height: size)
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { phase = 1.0 }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) { spin = 360.0 }
        }
    }

    @ViewBuilder
    private var iconLayer: some View {
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
        case .balanced:        BalancedWave(size: size, phase: phase)
        case .collector:       CollectorWave(size: size, phase: phase, spin: spin)
        case .streamingFan:    StreamingFanWave(size: size, phase: phase)
        }
    }
}

// MARK: - 1. レジェンド: 対称円環波形 Gold/White

private struct LegendWave: View {
    let size: CGFloat
    let phase: Double
    let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let spinRad = CGFloat(spin * .pi / 180)
            let gold = Color(red: 1, green: 0.88, blue: 0.3)

            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 90*s, h: 90*s), with: .color(.white.opacity(0.06)))
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 60*s, h: 60*s), with: .color(.white.opacity(0.08)))

            drawRingWave(&ctx, cx: cx, cy: cy, baseR: 46*s,
                         amplitude: (4 + p*3)*s, waveCount: 8, phaseOffset: spinRad,
                         color: gold, opacity: 0.90, lineWidth: 3*s)
            drawRingWave(&ctx, cx: cx, cy: cy, baseR: 32*s,
                         amplitude: (3 + p*2)*s, waveCount: 8, phaseOffset: -spinRad + .pi/8,
                         color: .white, opacity: 0.72, lineWidth: 2.2*s)
            drawRingWave(&ctx, cx: cx, cy: cy, baseR: 18*s,
                         amplitude: (2 + p)*s, waveCount: 8, phaseOffset: spinRad*0.5 + .pi/4,
                         color: .white, opacity: 0.55, lineWidth: 1.6*s)

            let cr = (5 + p*3)*s
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: cr*2, h: cr*2), with: .color(gold.opacity(0.95)))
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: cr*1.4, h: cr*1.4), with: .color(.white.opacity(0.9)))
        }
    }
}

// MARK: - 2. 推しが本気: 1本の極端スパイク + 白熱光

private struct ObsessedFanWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let beat = CGFloat(abs(sin(phase * .pi * 2)))

            for (r, op): (CGFloat, Double) in [(55, 0.06), (40, 0.10), (26, 0.14)] {
                let sc = 1 + beat * 0.12
                ctx.fill(waveEllipse(cx: cx, cy: cy, w: r*s*2*sc, h: r*s*2*sc),
                         with: .color(.white.opacity(op + beat * 0.07)))
            }

            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy,
                          amplitude: 3*s, frequency: 3, phaseOffset: CGFloat(phase * .pi * 2),
                          color: .white, opacity: 0.35, lineWidth: 1.5*s)

            let spikeH = (44 + beat*22)*s, spikeW = (4 + beat*2)*s
            var spike = Path()
            spike.move(to: CGPoint(x: cx - spikeW, y: cy))
            spike.addCurve(to: CGPoint(x: cx, y: cy - spikeH),
                           control1: CGPoint(x: cx - spikeW*0.8, y: cy - spikeH*0.5),
                           control2: CGPoint(x: cx - spikeW*0.3, y: cy - spikeH*0.85))
            spike.addCurve(to: CGPoint(x: cx + spikeW, y: cy),
                           control1: CGPoint(x: cx + spikeW*0.3, y: cy - spikeH*0.85),
                           control2: CGPoint(x: cx + spikeW*0.8, y: cy - spikeH*0.5))
            ctx.fill(spike, with: .color(.white.opacity(0.88 + beat*0.12)))

            let tipY = cy - spikeH, gs = 1 + beat*0.4
            for (r, op): (CGFloat, Double) in [(18, 0.10), (12, 0.22), (7, 0.55), (4, 0.92)] {
                ctx.fill(waveEllipse(cx: cx, cy: tipY, w: r*gs*s, h: r*gs*s),
                         with: .color(.white.opacity(op + beat*0.08)))
            }
        }
    }
}

// MARK: - 3. 一点集中型: 中心へ収束する波形

private struct SingleFocusWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)

            for (r, op): (CGFloat, Double) in [(26, 0.10), (16, 0.22), (9, 0.50)] {
                ctx.fill(waveEllipse(cx: cx, cy: cy, w: r*(1+p*0.2)*s, h: r*(1+p*0.2)*s),
                         with: .color(.white.opacity(op + phase*0.08)))
            }
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: (5+p*2)*s, h: (5+p*2)*s),
                     with: .color(.white.opacity(0.97)))

            let angles: [CGFloat]  = [0, .pi/3, -.pi/3]
            let pOffs:  [CGFloat]  = [0, 1.0, 2.1]
            for (i, angle) in angles.enumerated() {
                drawConvergingWave(&ctx, cx: cx, cy: cy, length: 110*s, angle: angle,
                                   amplitude: (11+p*3)*s, frequency: 2.5,
                                   phaseOffset: pOffs[i] + p*2*CGFloat.pi,
                                   color: .white,
                                   opacity: 0.78 - Double(i)*0.14,
                                   lineWidth: (2.5 - CGFloat(i)*0.3)*s)
            }
        }
    }
}

// MARK: - 4. ヘビロテ職人: 完全円形ループ、紫ネオン

private struct HeavyRotatorWave: View {
    let size: CGFloat
    let phase: Double
    let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let spinRad = CGFloat(spin * .pi / 180)
            let p = CGFloat(phase)
            let purple = Color(red: 0.75, green: 0.4, blue: 1.0)

            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 80*s, h: 80*s), with: .color(.white.opacity(0.06)))

            for layer in 0..<3 {
                let lPhase = spinRad + CGFloat(layer) * (2 * .pi / 3)
                drawRingWave(&ctx, cx: cx, cy: cy,
                             baseR: (38 + CGFloat(layer)*5)*s,
                             amplitude: (5+p*2.5)*s, waveCount: 6, phaseOffset: lPhase,
                             color: layer == 0 ? purple : .white,
                             opacity: 0.88 - Double(layer)*0.2,
                             lineWidth: (3.2 - CGFloat(layer)*0.5)*s)
            }

            ctx.fill(waveEllipse(cx: cx, cy: cy, w: (6+p*2)*s, h: (6+p*2)*s),
                     with: .color(purple.opacity(0.95)))
        }
    }
}

// MARK: - 5. 音楽探検家: 外側へ拡散するノイズ波

private struct ExplorerWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let green = Color(red: 0.2, green: 0.9, blue: 0.6)
            let cyan  = Color(red: 0.3, green: 0.85, blue: 1.0)

            let segs: [(a: CGFloat, br: CGFloat, len: CGFloat, freq: CGFloat, col: Color)] = [
                (0,        18, 28, 1.0, .white),
                (.pi/4,    16, 24, 1.5, green),
                (.pi/2,    20, 28, 0.8, cyan),
                (.pi*3/4,  15, 22, 1.2, .white),
                (.pi,      22, 28, 0.9, green),
                (-.pi/4,   18, 24, 1.1, cyan),
                (-.pi/2,   17, 22, 1.4, .white),
                (-.pi*3/4, 20, 26, 0.7, green),
            ]
            for seg in segs {
                let expandR = seg.br*s + p*16*s
                let sx = cx + cos(seg.a)*expandR,       sy = cy + sin(seg.a)*expandR
                let ex = cx + cos(seg.a)*(expandR+seg.len*s), ey = cy + sin(seg.a)*(expandR+seg.len*s)
                let pa = seg.a + .pi/2
                let amp = (4 + p*3)*s
                var path = Path()
                for i in 0...20 {
                    let t = CGFloat(i)/20
                    let x = sx + (ex-sx)*t, y = sy + (ey-sy)*t
                    let w = amp * sin(2 * .pi * seg.freq * t + p * 2 * .pi)
                    let pt = CGPoint(x: x + cos(pa)*w, y: y + sin(pa)*w)
                    if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                ctx.stroke(path, with: .color(seg.col.opacity(max(0.25, 0.82 - p*0.45))),
                           lineWidth: 1.8*s)
            }
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: (8+p*2)*s, h: (8+p*2)*s),
                     with: .color(.white.opacity(0.75 - p*0.2)))
        }
    }
}

// MARK: - 6. 固定リスナー: 揺れのない1本の安定波形

private struct LoyalListenerWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let blue = Color(red: 0.4, green: 0.7, blue: 1.0)

            ctx.stroke(waveEllipse(cx: cx, cy: cy, w: 82*s, h: 82*s),
                       with: .color(blue.opacity(0.22)), lineWidth: 1.5*s)
            ctx.stroke(waveEllipse(cx: cx, cy: cy, w: 62*s, h: 62*s),
                       with: .color(blue.opacity(0.16)), lineWidth: 1.2*s)
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 72*s, h: 72*s),
                     with: .color(.white.opacity(0.04)))

            let amp = (3 + phase*1.5)*s
            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy,
                          amplitude: amp, frequency: 1.5,
                          phaseOffset: CGFloat(phase * .pi * 0.6),
                          color: .white, opacity: 0.90, lineWidth: 3.2*s)
            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy+14*s,
                          amplitude: amp*0.45, frequency: 1.5,
                          phaseOffset: CGFloat(phase * .pi * 0.6),
                          color: .white, opacity: 0.28, lineWidth: 1.6*s)
        }
    }
}

// MARK: - 7. 成長型リスナー: 積層して成長する波形

private struct GrowingListenerWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)

            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 80*s, h: 80*s), with: .color(.white.opacity(0.05)))

            let layers: [(yOff: CGFloat, ampBase: CGFloat, op: Double, lw: CGFloat)] = [
                (26,  6, 0.28, 1.4),
                (13,  9, 0.43, 1.9),
                (0,  12, 0.60, 2.4),
                (-13, 15, 0.75, 2.9),
                (-26, 18, 0.90, 3.4),
            ]
            for (i, layer) in layers.enumerated() {
                let amp = layer.ampBase * s * (0.7 + p*0.3)
                let pOff = p * .pi * 2 + CGFloat(i) * 0.45
                drawHorizWave(&ctx, x1: cx-48*s, x2: cx+48*s, cy: cy+layer.yOff*s,
                              amplitude: amp, frequency: 1.5, phaseOffset: pOff,
                              color: .white, opacity: layer.op + phase*0.07,
                              lineWidth: layer.lw*s)
            }

            var arrow = Path()
            arrow.move(to: CGPoint(x: cx+46*s, y: cy+32*s))
            arrow.addLine(to: CGPoint(x: cx+46*s, y: cy-32*s))
            ctx.stroke(arrow, with: .color(.white.opacity(0.28)), lineWidth: 1.4*s)
            var head = Path()
            head.move(to: CGPoint(x: cx+46*s, y: cy-32*s))
            head.addLine(to: CGPoint(x: cx+40*s, y: cy-22*s))
            head.addLine(to: CGPoint(x: cx+52*s, y: cy-22*s))
            head.closeSubpath()
            ctx.fill(head, with: .color(.white.opacity(0.35 + p*0.2)))
        }
    }
}

// MARK: - 8. 懐古リスナー: 過去波形の残像レイヤー

private struct NostalgicWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let sepia = Color(red: 0.92, green: 0.80, blue: 0.62)

            let echoes: [(yOff: CGFloat, phAdd: CGFloat, op: Double, lw: CGFloat, isSepia: Bool)] = [
                (18, 2.2, 0.18, 1.4, true),
                (10, 1.4, 0.32, 1.8, true),
                (4,  0.7, 0.52, 2.2, false),
                (0,  0.0, 0.82, 2.8, false),
            ]
            for echo in echoes {
                let yPos = cy - echo.yOff*s - p*echo.yOff*0.3*s
                let pOff = p * .pi * 2 - echo.phAdd
                drawHorizWave(&ctx, x1: cx-50*s, x2: cx+50*s, cy: yPos,
                              amplitude: (10+p*2)*s, frequency: 2, phaseOffset: pOff,
                              color: echo.isSepia ? sepia : .white,
                              opacity: echo.op, lineWidth: echo.lw*s)
            }
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 72*s, h: 18*s),
                     with: .color(.white.opacity(0.04)))
        }
    }
}

// MARK: - 9. ジャンル偏愛家: 特定帯域に密集した波形

private struct GenreAddictWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let red = Color(red: 1.0, green: 0.3, blue: 0.25)

            ctx.fill(Path(roundedRect: CGRect(x: cx-52*s, y: cy-22*s, width: 104*s, height: 44*s),
                          cornerRadius: 8*s),
                     with: .color(red.opacity(0.14)))

            for i in 0..<9 {
                let t = CGFloat(i) / 8
                let yOff = (t - 0.5) * 36 * s
                let cf = max(0.0, 1 - abs(t - 0.5) * 1.6)
                let pOff = p * .pi * 2 + CGFloat(i) * 0.42
                drawHorizWave(&ctx, x1: cx-50*s, x2: cx+50*s, cy: cy+yOff,
                              amplitude: (2 + cf*3.5)*s, frequency: 4.5, phaseOffset: pOff,
                              color: i % 3 == 0 ? red : .white,
                              opacity: min(1, 0.4 + cf*0.55),
                              lineWidth: (1.1 + cf*0.9)*s)
            }
        }
    }
}

// MARK: - 10. バランス型: 完全均一波形、多色低彩度

private struct BalancedWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let lavender = Color(red: 0.78, green: 0.62, blue: 0.92)
            let teal     = Color(red: 0.58, green: 0.84, blue: 0.80)

            ctx.stroke(waveEllipse(cx: cx, cy: cy, w: 84*s, h: 84*s),
                       with: .color(lavender.opacity(0.22)), lineWidth: 1.4*s)

            let pOff = p * .pi * 2
            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy-16*s,
                          amplitude: (9+p*2)*s, frequency: 2, phaseOffset: pOff,
                          color: lavender, opacity: 0.82, lineWidth: 2.4*s)
            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy,
                          amplitude: (10+p*2)*s, frequency: 2, phaseOffset: pOff+0.6,
                          color: .white, opacity: 0.88, lineWidth: 3.0*s)
            drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy+16*s,
                          amplitude: (9+p*2)*s, frequency: 2, phaseOffset: pOff+1.2,
                          color: teal, opacity: 0.82, lineWidth: 2.4*s)
        }
    }
}

// MARK: - 11. コレクター(CD): ディスク積層構造、同心円環波形

private struct CollectorWave: View {
    let size: CGFloat
    let phase: Double
    let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let spinRad = CGFloat(spin * .pi / 180)
            let gold   = Color(red: 1.0, green: 0.88, blue: 0.55)
            let silver = Color(red: 0.85, green: 0.88, blue: 0.95)

            let rings: [(r: CGFloat, amp: CGFloat, cnt: Int, col: Color, op: Double, lw: CGFloat)] = [
                (47, 1.4, 16, silver, 0.42, 1.5),
                (38, 2.0, 14, gold,   0.55, 1.8),
                (30, 2.5, 12, silver, 0.66, 2.1),
                (22, 2.2, 10, gold,   0.78, 2.4),
                (14, 1.8,  8, silver, 0.88, 2.8),
            ]
            for ring in rings {
                drawRingWave(&ctx, cx: cx, cy: cy, baseR: ring.r*s,
                             amplitude: ring.amp*s*(1+p*0.5), waveCount: ring.cnt,
                             phaseOffset: spinRad*0.3,
                             color: ring.col, opacity: ring.op + p*0.08,
                             lineWidth: ring.lw*s)
            }
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: (8+p*2)*s, h: (8+p*2)*s),
                     with: .color(.white.opacity(0.94)))
            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 3*s, h: 3*s),
                     with: .color(gold.opacity(0.9)))
        }
    }
}

// MARK: - 12. サブスク派: 左から右へ流動するストリーム波形

private struct StreamingFanWave: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2, cy = sz.height / 2
            let p = CGFloat(phase)
            let aqua = Color(red: 0.4, green: 0.88, blue: 1.0)

            ctx.fill(waveEllipse(cx: cx, cy: cy, w: 80*s, h: 80*s),
                     with: .color(.white.opacity(0.05)))

            let streams: [(yOff: CGFloat, amp: CGFloat, op: Double, lw: CGFloat, col: Color)] = [
                (-18, 7,  0.45, 1.8, aqua),
                (-6,  11, 0.70, 2.5, .white),
                (6,   11, 0.70, 2.5, .white),
                (18,  7,  0.45, 1.8, aqua),
            ]
            for stream in streams {
                drawHorizWave(&ctx, x1: cx-52*s, x2: cx+52*s, cy: cy+stream.yOff*s,
                              amplitude: stream.amp*s, frequency: 1.5,
                              phaseOffset: p * 2 * .pi * -1,
                              color: stream.col, opacity: stream.op,
                              lineWidth: stream.lw*s)
            }

            let dotX = cx - 52*s + p * 104*s
            for dy: CGFloat in [-20, -8, 8, 20] {
                ctx.fill(waveEllipse(cx: dotX, cy: cy+dy*s, w: 4*s, h: 4*s),
                         with: .color(.white.opacity(max(0, 0.6 - abs(Double(dy))/40.0*0.5))))
            }
        }
    }
}

// MARK: - Drawing Helpers

private func drawHorizWave(
    _ ctx: inout GraphicsContext,
    x1: CGFloat, x2: CGFloat, cy: CGFloat,
    amplitude: CGFloat, frequency: CGFloat, phaseOffset: CGFloat,
    color: Color, opacity: Double, lineWidth: CGFloat,
    steps: Int = 80
) {
    var path = Path()
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let x = x1 + (x2 - x1) * t
        let y = cy + amplitude * sin(2 * .pi * frequency * t + phaseOffset)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lineWidth)
}

private func drawRingWave(
    _ ctx: inout GraphicsContext,
    cx: CGFloat, cy: CGFloat,
    baseR: CGFloat, amplitude: CGFloat, waveCount: Int, phaseOffset: CGFloat,
    color: Color, opacity: Double, lineWidth: CGFloat,
    steps: Int = 120
) {
    var path = Path()
    for i in 0...steps {
        let angle = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let r = baseR + amplitude * sin(CGFloat(waveCount) * angle + phaseOffset)
        let pt = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lineWidth)
}

private func drawConvergingWave(
    _ ctx: inout GraphicsContext,
    cx: CGFloat, cy: CGFloat,
    length: CGFloat, angle: CGFloat,
    amplitude: CGFloat, frequency: CGFloat, phaseOffset: CGFloat,
    color: Color, opacity: Double, lineWidth: CGFloat,
    steps: Int = 80
) {
    var path = Path()
    let px = -sin(angle), py = cos(angle)
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let dist = (t - 0.5) * length
        let baseX = cx + cos(angle) * dist, baseY = cy + sin(angle) * dist
        let ampScale = abs(t - 0.5) * 2
        let wave = amplitude * ampScale * sin(2 * .pi * frequency * t + phaseOffset)
        let pt = CGPoint(x: baseX + px * wave, y: baseY + py * wave)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lineWidth)
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
                    .fill(LinearGradient(
                        colors: personality.gradient,
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size, height: size)
                    .shadow(color: (personality.gradient.first ?? .purple).opacity(0.4),
                            radius: size * 0.12)
                Text(personality.emoji)
                    .font(.system(size: size * 0.38))
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(personality.title)
                    .font(.headline.bold())
                Text(personality.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.pink.opacity(0.85))
                        .lineLimit(3)
                        .padding(.top, 2)
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
