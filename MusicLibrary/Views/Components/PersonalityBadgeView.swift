// PersonalityBadgeView.swift
// MusicLibrary

import SwiftUI
import UIKit

// MARK: - メインアイコンビュー

struct PersonalityIconSymbol: View {
    let personality: Personality
    var size: CGFloat = 120
    var animated: Bool = false

    @State private var phase: Double = 0    // 0→1 autoreverses (pulse)
    @State private var spin: Double = 0     // 0→360 linear (rotation)

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
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                spin = 360.0
            }
        }
    }

    @ViewBuilder
    private var iconLayer: some View {
        switch personality {
        case .legend:          LegendIconLayer(size: size, phase: phase)
        case .obsessedFan:     ObsessedFanIconLayer(size: size, phase: phase)
        case .singleFocus:     SingleFocusIconLayer(size: size, phase: phase)
        case .heavyRotator:    HeavyRotatorIconLayer(size: size, spin: spin)
        case .explorer:        ExplorerIconLayer(size: size, phase: phase)
        case .loyalListener:   LoyalListenerIconLayer(size: size, phase: phase)
        case .growingListener: GrowingListenerIconLayer(size: size, phase: phase)
        case .nostalgic:       NostalgicIconLayer(size: size, spin: spin)
        case .genreAddict:     GenreAddictIconLayer(size: size, phase: phase)
        case .balanced:        BalancedIconLayer(size: size, phase: phase)
        case .collector:       CollectorIconLayer(size: size, spin: spin)
        case .streamingFan:    StreamingFanIconLayer(size: size, phase: phase)
        }
    }
}

// MARK: - レジェンド（光線 + 王冠 + レコード + スパークル）

private struct LegendIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 8本の光線
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4
                let r1: CGFloat = 22 * s, r2: CGFloat = 52 * s
                var ray = Path()
                ray.move(to: CGPoint(x: cx + cos(a - 0.10) * r1, y: cy + sin(a - 0.10) * r1))
                ray.addLine(to: CGPoint(x: cx + cos(a) * r2, y: cy + sin(a) * r2))
                ray.addLine(to: CGPoint(x: cx + cos(a + 0.10) * r1, y: cy + sin(a + 0.10) * r1))
                ray.closeSubpath()
                ctx.fill(ray, with: .color(.white.opacity(0.42)))
            }

            // 王冠
            let cY = cy - 12 * s
            var crown = Path()
            crown.move(to: CGPoint(x: cx - 22*s, y: cY + 8*s))
            crown.addLine(to: CGPoint(x: cx - 22*s, y: cY - 2*s))
            crown.addLine(to: CGPoint(x: cx - 14*s, y: cY + 4*s))
            crown.addLine(to: CGPoint(x: cx - 7*s,  y: cY - 10*s))
            crown.addLine(to: CGPoint(x: cx,         y: cY + 4*s))
            crown.addLine(to: CGPoint(x: cx + 7*s,  y: cY - 10*s))
            crown.addLine(to: CGPoint(x: cx + 14*s, y: cY + 4*s))
            crown.addLine(to: CGPoint(x: cx + 22*s, y: cY - 2*s))
            crown.addLine(to: CGPoint(x: cx + 22*s, y: cY + 8*s))
            crown.closeSubpath()
            ctx.fill(crown, with: .color(.white))

            // 宝石 x3
            let jewY = cY - 4 * s
            for jx in [CGFloat(-7), 0, 7] {
                ctx.fill(ellipseRect(cx: cx + jx*s, cy: jewY, w: 5*s, h: 5*s),
                         with: .color(Color(red:1,green:0.9,blue:0.3)))
            }

            // レコードディスク
            let dY = cy + 22 * s, dR = 18 * s
            ctx.fill(ellipseRect(cx: cx, cy: dY, w: dR*2, h: dR*2),
                     with: .color(.black.opacity(0.3)))
            for r in [dR*0.75, dR*0.55] {
                ctx.stroke(ellipseRect(cx: cx, cy: dY, w: r*2, h: r*2),
                           with: .color(.white.opacity(0.45)), lineWidth: 1.4*s)
            }
            let lR = dR * 0.30
            ctx.fill(ellipseRect(cx: cx, cy: dY, w: lR*2, h: lR*2),
                     with: .color(.white.opacity(0.75)))
            ctx.fill(ellipseRect(cx: cx, cy: dY, w: 4.5*s, h: 4.5*s),
                     with: .color(.black.opacity(0.5)))

            // スパークル x4 (点滅)
            let sOp = 0.45 + phase * 0.55
            for (dx, dy) in [(-32.0, -34.0), (32.0, -34.0), (-33.0, 28.0), (33.0, 28.0)] {
                drawSparkle(&ctx, x: cx + CGFloat(dx)*s, y: cy + CGFloat(dy)*s, r: 5.5*s, opacity: sOp)
            }
        }
    }
}

// MARK: - 推しが本気（グロー + ハート + スパークル）

private struct ObsessedFanIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 放射グロー
            let glowRings: [(CGFloat, Double)] = [(50, 0.12), (38, 0.18), (26, 0.22)]
            for (r, op) in glowRings {
                ctx.fill(ellipseRect(cx: cx, cy: cy, w: r*s*2, h: r*s*2),
                         with: .color(.white.opacity(op)))
            }

            // ハート（アニメーション拡縮）
            let hr = CGFloat(34 + phase * 6) * s
            ctx.fill(heartPath(cx: cx, cy: cy + 2*s, r: hr),
                     with: .color(.white.opacity(0.92)))
            ctx.fill(heartPath(cx: cx, cy: cy + 2*s, r: hr * 0.65),
                     with: .color(.pink.opacity(0.55)))

            // スパークル x3
            let sOp = 0.55 + phase * 0.45
            drawSparkle(&ctx, x: cx - 30*s, y: cy - 26*s, r: 5.5*s, opacity: sOp)
            drawSparkle(&ctx, x: cx + 30*s, y: cy - 26*s, r: 4.5*s, opacity: sOp * 0.85)
            drawSparkle(&ctx, x: cx + 33*s, y: cy + 12*s, r: 3.5*s, opacity: sOp * 0.7)
        }
    }
}

// MARK: - 一点集中型（的 + 矢印）

private struct SingleFocusIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 同心円（的）x4
            let radii: [(CGFloat, Double)] = [(44, 0.25), (32, 0.35), (20, 0.55), (10, 0.9)]
            for (r, op) in radii {
                ctx.fill(ellipseRect(cx: cx, cy: cy, w: r*s*2, h: r*s*2),
                         with: .color(.white.opacity(op)))
            }

            // 矢（右上から中心へ）
            let arrowEnd = CGPoint(x: cx + 3*s, y: cy + 3*s)
            let arrowStart = CGPoint(x: cx + 38*s, y: cy - 38*s)
            var shaft = Path()
            shaft.move(to: arrowStart)
            shaft.addLine(to: arrowEnd)
            ctx.stroke(shaft, with: .color(.white.opacity(0.9)), lineWidth: 4*s)

            // 矢じり
            let tipAngle = atan2(arrowEnd.y - arrowStart.y, arrowEnd.x - arrowStart.x)
            var tip = Path()
            tip.move(to: arrowEnd)
            let tipLen = 14 * s
            let spread = CGFloat.pi / 6
            tip.addLine(to: CGPoint(x: arrowEnd.x + cos(tipAngle + .pi - spread) * tipLen,
                                    y: arrowEnd.y + sin(tipAngle + .pi - spread) * tipLen))
            tip.addLine(to: CGPoint(x: arrowEnd.x + cos(tipAngle + .pi + spread) * tipLen,
                                    y: arrowEnd.y + sin(tipAngle + .pi + spread) * tipLen))
            tip.closeSubpath()
            ctx.fill(tip, with: .color(.white.opacity(0.9)))
        }
    }
}

// MARK: - ヘビロテ職人（ループ矢印 + 音符）

private struct HeavyRotatorIconLayer: View {
    let size: CGFloat
    let spin: Double    // 0→360, linear
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2
            let arcR = 30 * s

            // 上半円弧（左→右）
            var topArc = Path()
            topArc.addArc(center: CGPoint(x: cx, y: cy),
                          radius: arcR,
                          startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(topArc, with: .color(.white.opacity(0.9)), lineWidth: 5*s)

            // 上弧の矢じり（右端 340°）
            let a340 = CGFloat(340.0 * .pi / 180.0)
            let topEndX = cx + cos(a340) * arcR
            let topEndY = cy + sin(a340) * arcR
            var topTip = Path()
            topTip.move(to: CGPoint(x: topEndX, y: topEndY))
            topTip.addLine(to: CGPoint(x: topEndX - 9*s, y: topEndY - 5*s))
            topTip.addLine(to: CGPoint(x: topEndX - 5*s, y: topEndY + 8*s))
            topTip.closeSubpath()
            ctx.fill(topTip, with: .color(.white.opacity(0.9)))

            // 下半円弧（右→左）
            var botArc = Path()
            botArc.addArc(center: CGPoint(x: cx, y: cy),
                          radius: arcR,
                          startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            ctx.stroke(botArc, with: .color(.white.opacity(0.9)), lineWidth: 5*s)

            // 下弧の矢じり（左端 160°）
            let a160 = CGFloat(160.0 * .pi / 180.0)
            let botEndX = cx + cos(a160) * arcR
            let botEndY = cy + sin(a160) * arcR
            var botTip = Path()
            botTip.move(to: CGPoint(x: botEndX, y: botEndY))
            botTip.addLine(to: CGPoint(x: botEndX + 9*s, y: botEndY + 5*s))
            botTip.addLine(to: CGPoint(x: botEndX + 5*s, y: botEndY - 8*s))
            botTip.closeSubpath()
            ctx.fill(botTip, with: .color(.white.opacity(0.9)))

            // 中央音符
            drawMusicNote(&ctx, cx: cx - 4*s, cy: cy - 4*s, s: s * 0.85, opacity: 0.95)

            // ∞記号（下部）
            let infY = cy + 40 * s
            let inf = 10 * s
            ctx.stroke(Path(ellipseIn: CGRect(x: cx - inf*2, y: infY - inf*0.55, width: inf*1.1, height: inf*1.1)),
                       with: .color(.white.opacity(0.7)), lineWidth: 2.8*s)
            ctx.stroke(Path(ellipseIn: CGRect(x: cx + inf*0.9, y: infY - inf*0.55, width: inf*1.1, height: inf*1.1)),
                       with: .color(.white.opacity(0.7)), lineWidth: 2.8*s)
        }
        .rotationEffect(.degrees(spin * 0.5))
    }
}

// MARK: - 音楽探検家（コンパス + 音符）

private struct ExplorerIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 外側2リング
            ctx.stroke(ellipseRect(cx: cx, cy: cy, w: 90*s, h: 90*s),
                       with: .color(.white.opacity(0.35)), lineWidth: 1.8*s)
            ctx.stroke(ellipseRect(cx: cx, cy: cy, w: 70*s, h: 70*s),
                       with: .color(.white.opacity(0.25)), lineWidth: 1.2*s)

            // 4方位ドット (N/S/E/W)
            let dirDots: [(CGFloat, CGFloat, Double)] = [(0, -38, 1.0), (0, 38, 0.5), (-38, 0, 0.7), (38, 0, 0.7)]
            for (dx, dy, op) in dirDots {
                ctx.fill(ellipseRect(cx: cx+dx*s, cy: cy+dy*s, w: 6*s, h: 6*s),
                         with: .color(.white.opacity(op)))
            }

            // コンパス針（ダイヤモンド形、N=白、S=薄）
            var needle = Path()
            needle.move(to: CGPoint(x: cx, y: cy - 28*s))         // North tip
            needle.addLine(to: CGPoint(x: cx + 7*s, y: cy))
            needle.addLine(to: CGPoint(x: cx, y: cy + 20*s))      // South tip
            needle.addLine(to: CGPoint(x: cx - 7*s, y: cy))
            needle.closeSubpath()
            ctx.fill(needle, with: .color(.white.opacity(0.9)))

            var needleS = Path()
            needleS.move(to: CGPoint(x: cx, y: cy + 20*s))
            needleS.addLine(to: CGPoint(x: cx + 7*s, y: cy))
            needleS.addLine(to: CGPoint(x: cx, y: cy - 28*s))
            needleS.addLine(to: CGPoint(x: cx - 7*s, y: cy))
            needleS.closeSubpath()
            ctx.fill(needleS, with: .color(.black.opacity(0.25)))

            // 中央ピン
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: 7*s, h: 7*s),
                     with: .color(.white))

            // 音符（右上・左下、フェード）
            let nOp = 0.5 + phase * 0.4
            drawMusicNote(&ctx, cx: cx + 30*s, cy: cy - 28*s, s: s * 0.7, opacity: nOp)
            drawMusicNote(&ctx, cx: cx - 30*s, cy: cy + 24*s, s: s * 0.55, opacity: nOp * 0.7)
        }
    }
}

// MARK: - 固定リスナー（シールド + 鍵 + スパークル）

private struct LoyalListenerIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // シールド
            var shield = Path()
            shield.move(to: CGPoint(x: cx, y: cy + 46*s))
            shield.addCurve(to: CGPoint(x: cx - 34*s, y: cy - 10*s),
                            control1: CGPoint(x: cx - 34*s, y: cy + 34*s),
                            control2: CGPoint(x: cx - 34*s, y: cy + 4*s))
            shield.addLine(to: CGPoint(x: cx - 34*s, y: cy - 34*s))
            shield.addLine(to: CGPoint(x: cx, y: cy - 42*s))
            shield.addLine(to: CGPoint(x: cx + 34*s, y: cy - 34*s))
            shield.addLine(to: CGPoint(x: cx + 34*s, y: cy - 10*s))
            shield.addCurve(to: CGPoint(x: cx, y: cy + 46*s),
                            control1: CGPoint(x: cx + 34*s, y: cy + 4*s),
                            control2: CGPoint(x: cx + 34*s, y: cy + 34*s))
            ctx.fill(shield, with: .color(.white.opacity(0.25)))
            ctx.stroke(shield, with: .color(.white.opacity(0.8)), lineWidth: 3.5*s)

            // 南京錠ボディ
            ctx.fill(roundedRect(cx: cx, cy: cy + 8*s, w: 28*s, h: 22*s, r: 5*s),
                     with: .color(.white.opacity(0.9)))
            // シャックル（弧）
            ctx.withCGContext { cg in
                cg.setStrokeColor(UIColor.white.cgColor)
                cg.setLineWidth(5 * s)
                cg.setLineCap(.round)
                cg.addArc(center: CGPoint(x: cx, y: cy - 2*s),
                          radius: 11*s, startAngle: .pi, endAngle: 0, clockwise: true)
                cg.strokePath()
            }
            // キーホール
            ctx.fill(ellipseRect(cx: cx, cy: cy + 6*s, w: 7*s, h: 7*s),
                     with: .color(.black.opacity(0.4)))
            ctx.fill(trianglePath(cx: cx, tipY: cy + 17*s, w: 6*s, h: 8*s),
                     with: .color(.black.opacity(0.4)))

            // スパークル x3（点滅）
            let sOp = 0.4 + phase * 0.6
            drawSparkle(&ctx, x: cx - 34*s, y: cy - 32*s, r: 4.5*s, opacity: sOp)
            drawSparkle(&ctx, x: cx + 34*s, y: cy - 32*s, r: 3.5*s, opacity: sOp * 0.8)
            drawSparkle(&ctx, x: cx + 36*s, y: cy + 20*s, r: 3*s, opacity: sOp * 0.6)
        }
    }
}

// MARK: - 成長型リスナー（棒グラフ + 上向き矢印）

private struct GrowingListenerIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            let baseY = cy + 28*s
            let barW = 14 * s
            let heights: [CGFloat] = [18, 28, 38, 50]
            let xOffsets: [CGFloat] = [-27, -9, 9, 27]

            // 棒グラフ
            for (i, h) in heights.enumerated() {
                let bh = h * s * CGFloat(0.6 + phase * 0.4)
                let by = baseY - bh
                let opacity = 0.5 + Double(i) * 0.12
                ctx.fill(roundedRect(cx: cx + xOffsets[i]*s, cy: by + bh/2, w: barW, h: bh, r: 3*s),
                         with: .color(.white.opacity(opacity)))
            }

            // ベースライン
            var base = Path()
            base.move(to: CGPoint(x: cx - 36*s, y: baseY + 2*s))
            base.addLine(to: CGPoint(x: cx + 36*s, y: baseY + 2*s))
            ctx.stroke(base, with: .color(.white.opacity(0.5)), lineWidth: 2*s)

            // 上向き矢印
            let arrowX = cx + 44*s
            let arrowTip = CGPoint(x: arrowX, y: cy - 34*s)
            var arrow = Path()
            arrow.move(to: CGPoint(x: arrowX, y: cy + 28*s))
            arrow.addLine(to: arrowTip)
            ctx.stroke(arrow, with: .color(.white.opacity(0.9)), lineWidth: 4*s)
            var arrowHead = Path()
            arrowHead.move(to: arrowTip)
            arrowHead.addLine(to: CGPoint(x: arrowX - 8*s, y: arrowTip.y + 14*s))
            arrowHead.addLine(to: CGPoint(x: arrowX + 8*s, y: arrowTip.y + 14*s))
            arrowHead.closeSubpath()
            ctx.fill(arrowHead, with: .color(.white.opacity(0.9)))
        }
    }
}

// MARK: - 懐古リスナー（ビニールレコード、回転）

private struct NostalgicIconLayer: View {
    let size: CGFloat
    let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2
            let dR = 46 * s

            // 外周ディスク
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: dR*2, h: dR*2),
                     with: .color(.black.opacity(0.45)))
            // グルーヴリング x4
            for r: CGFloat in [42, 36, 30, 24] {
                ctx.stroke(ellipseRect(cx: cx, cy: cy, w: r*s*2, h: r*s*2),
                           with: .color(.white.opacity(0.22)), lineWidth: 1.5*s)
            }
            // センターラベル
            let lR = 18 * s
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: lR*2, h: lR*2),
                     with: .color(.white.opacity(0.65)))
            // センターホール
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: 6*s, h: 6*s),
                     with: .color(.black.opacity(0.6)))
            // 反射ハイライト
            var shine = Path()
            shine.move(to: CGPoint(x: cx - 10*s, y: cy - 40*s))
            shine.addCurve(to: CGPoint(x: cx + 15*s, y: cy - 30*s),
                           control1: CGPoint(x: cx - 2*s, y: cy - 44*s),
                           control2: CGPoint(x: cx + 10*s, y: cy - 40*s))
            shine.addLine(to: CGPoint(x: cx + 8*s, y: cy - 26*s))
            shine.addCurve(to: CGPoint(x: cx - 10*s, y: cy - 40*s),
                           control1: CGPoint(x: cx - 2*s, y: cy - 32*s),
                           control2: CGPoint(x: cx - 12*s, y: cy - 36*s))
            ctx.fill(shine, with: .color(.white.opacity(0.18)))
        }
        .rotationEffect(.degrees(spin * 0.3))
    }
}

// MARK: - ジャンル偏愛家（五線譜 + ト音記号 + 音符）

private struct GenreAddictIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 五線譜（5本）
            let staffTop = cy - 22 * s
            let staffSpacing = 9 * s
            let staffLeft = cx - 44 * s
            let staffRight = cx + 44 * s
            for i in 0..<5 {
                let y = staffTop + CGFloat(i) * staffSpacing
                var line = Path()
                line.move(to: CGPoint(x: staffLeft, y: y))
                line.addLine(to: CGPoint(x: staffRight, y: y))
                ctx.stroke(line, with: .color(.white.opacity(0.65)), lineWidth: 1.8*s)
            }

            // ト音記号（簡略版）
            ctx.withCGContext { cg in
                cg.setStrokeColor(UIColor.white.cgColor)
                cg.setLineWidth(3.5 * s)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)
                let gx = cx - 10 * s
                let gy = staffTop - 8 * s

                // 縦軸
                cg.move(to: CGPoint(x: gx, y: gy))
                cg.addLine(to: CGPoint(x: gx, y: gy + 64*s))

                // スパイラル上部
                cg.move(to: CGPoint(x: gx, y: gy + 10*s))
                cg.addArc(center: CGPoint(x: gx + 8*s, y: gy + 16*s),
                          radius: 9*s, startAngle: -.pi * 0.6, endAngle: .pi * 1.4, clockwise: false)

                // 下部ループ
                cg.move(to: CGPoint(x: gx, y: gy + 56*s))
                cg.addArc(center: CGPoint(x: gx + 8*s, y: gy + 52*s),
                          radius: 9*s, startAngle: .pi * 0.7, endAngle: -.pi * 0.3, clockwise: true)
                cg.strokePath()
            }

            // 音符 (右側)
            let nOp = 0.65 + phase * 0.35
            drawMusicNote(&ctx, cx: cx + 28*s, cy: staffTop + 4*s, s: s * 0.9, opacity: nOp)
            drawMusicNote(&ctx, cx: cx + 36*s, cy: staffTop + 22*s, s: s * 0.75, opacity: nOp * 0.8)
        }
    }
}

// MARK: - バランス型（天秤）

private struct BalancedIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 中央柱
            var pillar = Path()
            pillar.move(to: CGPoint(x: cx, y: cy - 36*s))
            pillar.addLine(to: CGPoint(x: cx, y: cy + 40*s))
            ctx.stroke(pillar, with: .color(.white.opacity(0.8)), lineWidth: 4*s)

            // 三角底座
            var base = Path()
            base.move(to: CGPoint(x: cx - 22*s, y: cy + 40*s))
            base.addLine(to: CGPoint(x: cx + 22*s, y: cy + 40*s))
            base.addLine(to: CGPoint(x: cx, y: cy + 26*s))
            base.closeSubpath()
            ctx.fill(base, with: .color(.white.opacity(0.7)))

            // 水平ビーム（少し傾ける）
            let tilt = CGFloat(phase - 0.5) * 10 * s
            var beam = Path()
            beam.move(to: CGPoint(x: cx - 42*s, y: cy - 34*s + tilt))
            beam.addLine(to: CGPoint(x: cx + 42*s, y: cy - 34*s - tilt))
            ctx.stroke(beam, with: .color(.white.opacity(0.85)), lineWidth: 3.5*s)

            // 左右の吊り紐
            let leftPanX = cx - 42 * s, rightPanX = cx + 42 * s
            let leftTop = cy - 34 * s + tilt, rightTop = cy - 34 * s - tilt
            let panY = cy + 4 * s
            var ropes = Path()
            ropes.move(to: CGPoint(x: leftPanX, y: leftTop))
            ropes.addLine(to: CGPoint(x: leftPanX, y: panY))
            ropes.move(to: CGPoint(x: rightPanX, y: rightTop))
            ropes.addLine(to: CGPoint(x: rightPanX, y: panY))
            ctx.stroke(ropes, with: .color(.white.opacity(0.6)), lineWidth: 2*s)

            // 左右の皿（半円）
            ctx.withCGContext { cg in
                cg.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                cg.setStrokeColor(UIColor.white.withAlphaComponent(0.75).cgColor)
                cg.setLineWidth(2.5 * s)
                for px in [leftPanX, rightPanX] {
                    cg.addArc(center: CGPoint(x: px, y: panY), radius: 18*s,
                              startAngle: 0, endAngle: .pi, clockwise: false)
                    cg.fillPath()
                    cg.addArc(center: CGPoint(x: px, y: panY), radius: 18*s,
                              startAngle: 0, endAngle: .pi, clockwise: false)
                    cg.strokePath()
                }
            }

            // 音符（左右の皿に）
            drawMusicNote(&ctx, cx: leftPanX - 4*s, cy: panY - 8*s, s: s * 0.8, opacity: 0.85)
            drawMusicNote(&ctx, cx: rightPanX - 4*s, cy: panY - 8*s, s: s * 0.8, opacity: 0.85)
        }
    }
}

// MARK: - コレクター（CDディスク、回転）

private struct CollectorIconLayer: View {
    let size: CGFloat
    let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2
            let dR = 48 * s

            // CDディスク外周（白）
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: dR*2, h: dR*2),
                     with: .color(.white.opacity(0.85)))
            // グルーヴリング
            for r: CGFloat in [46, 40, 34, 28] {
                ctx.stroke(ellipseRect(cx: cx, cy: cy, w: r*s*2, h: r*s*2),
                           with: .color(Color(red: 0.7, green: 0.8, blue: 1).opacity(0.35)), lineWidth: 1.5*s)
            }
            // センターハブ（シルバー）
            let hR = 16 * s
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: hR*2, h: hR*2),
                     with: .color(Color(red: 0.8, green: 0.85, blue: 0.95).opacity(0.9)))
            // センターホール
            ctx.fill(ellipseRect(cx: cx, cy: cy, w: 6.5*s, h: 6.5*s),
                     with: .color(.white.opacity(0.95)))
            // 反射ハイライト
            var shine = Path()
            shine.move(to: CGPoint(x: cx - 8*s, y: cy - 42*s))
            shine.addCurve(to: CGPoint(x: cx + 20*s, y: cy - 34*s),
                           control1: CGPoint(x: cx + 2*s, y: cy - 46*s),
                           control2: CGPoint(x: cx + 14*s, y: cy - 42*s))
            shine.addLine(to: CGPoint(x: cx + 12*s, y: cy - 28*s))
            shine.addCurve(to: CGPoint(x: cx - 8*s, y: cy - 42*s),
                           control1: CGPoint(x: cx - 2*s, y: cy - 32*s),
                           control2: CGPoint(x: cx - 10*s, y: cy - 38*s))
            ctx.fill(shine, with: .color(.white.opacity(0.25)))
        }
        .rotationEffect(.degrees(spin * 0.4))
    }
}

// MARK: - サブスク派（地球儀 + WiFi + 音符）

private struct StreamingFanIconLayer: View {
    let size: CGFloat
    let phase: Double
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 140
            let cx = sz.width / 2
            let cy = sz.height / 2

            // 地球儀外輪
            let gR = 36 * s
            ctx.stroke(ellipseRect(cx: cx, cy: cy, w: gR*2, h: gR*2),
                       with: .color(.white.opacity(0.8)), lineWidth: 2.5*s)

            // 経線（楕円）x3
            for wR: CGFloat in [16, 28, 36] {
                ctx.stroke(ellipseRect(cx: cx, cy: cy, w: wR*s*2, h: gR*2),
                           with: .color(.white.opacity(0.4)), lineWidth: 1.5*s)
            }
            // 緯線 x2
            for (dy, wR): (CGFloat, CGFloat) in [(-14, 32), (14, 32)] {
                ctx.stroke(ellipseRect(cx: cx, cy: cy + dy*s, w: wR*s*2, h: wR*s*0.5),
                           with: .color(.white.opacity(0.35)), lineWidth: 1.5*s)
            }

            // WiFiアーク x3（右上）
            let wfX = cx + 18 * s, wfY = cy - 30 * s
            let wfOp = 0.55 + phase * 0.45
            ctx.withCGContext { cg in
                cg.setStrokeColor(UIColor.white.withAlphaComponent(wfOp).cgColor)
                cg.setLineCap(.round)
                let wfArcs: [(CGFloat, CGFloat)] = [(14, 3.5), (22, 3), (30, 2.5)]
                for (r, lw) in wfArcs {
                    cg.setLineWidth(lw * s)
                    cg.addArc(center: CGPoint(x: wfX, y: wfY + r * 0.5),
                              radius: r * s, startAngle: -.pi * 0.75, endAngle: -.pi * 0.25, clockwise: false)
                    cg.strokePath()
                }
                // ドット
                cg.setFillColor(UIColor.white.withAlphaComponent(wfOp).cgColor)
                cg.addEllipse(in: CGRect(x: wfX - 3*s, y: wfY + 14*s*0.5 - 3*s, width: 6*s, height: 6*s))
                cg.fillPath()
            }

            // 音符（左下）
            drawMusicNote(&ctx, cx: cx - 22*s, cy: cy + 22*s, s: s * 0.85, opacity: 0.85)
        }
    }
}

// MARK: - ヘルパー: 楕円Rect

private func ellipseRect(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h))
}

// MARK: - ヘルパー: 角丸矩形

private func roundedRect(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h),
         cornerRadius: r)
}

// MARK: - ヘルパー: 三角形

private func trianglePath(cx: CGFloat, tipY: CGFloat, w: CGFloat, h: CGFloat) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: cx, y: tipY))
    p.addLine(to: CGPoint(x: cx - w/2, y: tipY - h))
    p.addLine(to: CGPoint(x: cx + w/2, y: tipY - h))
    p.closeSubpath()
    return p
}

// MARK: - ヘルパー: ハートパス

private func heartPath(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
    var p = Path()
    let bot = CGPoint(x: cx, y: cy + r * 0.72)
    p.move(to: bot)
    p.addCurve(to: CGPoint(x: cx - r, y: cy - r * 0.1),
               control1: CGPoint(x: cx - r * 0.35, y: cy + r * 0.55),
               control2: CGPoint(x: cx - r * 1.05, y: cy + r * 0.3))
    p.addCurve(to: CGPoint(x: cx, y: cy - r * 0.38),
               control1: CGPoint(x: cx - r, y: cy - r * 0.55),
               control2: CGPoint(x: cx - r * 0.45, y: cy - r * 0.65))
    p.addCurve(to: CGPoint(x: cx + r, y: cy - r * 0.1),
               control1: CGPoint(x: cx + r * 0.45, y: cy - r * 0.65),
               control2: CGPoint(x: cx + r, y: cy - r * 0.55))
    p.addCurve(to: bot,
               control1: CGPoint(x: cx + r * 1.05, y: cy + r * 0.3),
               control2: CGPoint(x: cx + r * 0.35, y: cy + r * 0.55))
    p.closeSubpath()
    return p
}

// MARK: - ヘルパー: スパークル（4方向ダイヤモンド）

private func drawSparkle(_ ctx: inout GraphicsContext,
                          x: CGFloat, y: CGFloat, r: CGFloat, opacity: Double) {
    let w = r * 0.28
    var p = Path()
    // 上
    p.move(to: CGPoint(x: x, y: y - r))
    p.addLine(to: CGPoint(x: x + w, y: y - r * 0.28))
    p.addLine(to: CGPoint(x: x, y: y))
    p.addLine(to: CGPoint(x: x - w, y: y - r * 0.28))
    p.closeSubpath()
    // 下
    p.move(to: CGPoint(x: x, y: y + r))
    p.addLine(to: CGPoint(x: x + w, y: y + r * 0.28))
    p.addLine(to: CGPoint(x: x, y: y))
    p.addLine(to: CGPoint(x: x - w, y: y + r * 0.28))
    p.closeSubpath()
    // 右
    p.move(to: CGPoint(x: x + r, y: y))
    p.addLine(to: CGPoint(x: x + r * 0.28, y: y + w))
    p.addLine(to: CGPoint(x: x, y: y))
    p.addLine(to: CGPoint(x: x + r * 0.28, y: y - w))
    p.closeSubpath()
    // 左
    p.move(to: CGPoint(x: x - r, y: y))
    p.addLine(to: CGPoint(x: x - r * 0.28, y: y + w))
    p.addLine(to: CGPoint(x: x, y: y))
    p.addLine(to: CGPoint(x: x - r * 0.28, y: y - w))
    p.closeSubpath()
    ctx.fill(p, with: .color(.white.opacity(opacity)))
}

// MARK: - ヘルパー: 音符（♩）

private func drawMusicNote(_ ctx: inout GraphicsContext,
                            cx: CGFloat, cy: CGFloat, s: CGFloat, opacity: Double) {
    let color = GraphicsContext.Shading.color(.white.opacity(opacity))
    // 音符の玉
    let noteR = 5.5 * s
    ctx.fill(ellipseRect(cx: cx, cy: cy + 2*s, w: noteR*2, h: noteR*1.6),
             with: color)
    // ステム
    var stem = Path()
    stem.move(to: CGPoint(x: cx + noteR * 0.85, y: cy + 2*s - noteR * 0.6))
    stem.addLine(to: CGPoint(x: cx + noteR * 0.85, y: cy - 14*s))
    ctx.stroke(stem, with: color, lineWidth: 2.2*s)
    // フラッグ
    var flag = Path()
    flag.move(to: CGPoint(x: cx + noteR * 0.85, y: cy - 14*s))
    flag.addCurve(to: CGPoint(x: cx + noteR * 0.85, y: cy - 6*s),
                  control1: CGPoint(x: cx + noteR * 0.85 + 10*s, y: cy - 12*s),
                  control2: CGPoint(x: cx + noteR * 0.85 + 8*s, y: cy - 8*s))
    ctx.stroke(flag, with: color, lineWidth: 2*s)
}

// MARK: - PersonalityBadgeView（後方互換：ListenerPersonality → PersonalityIconSymbol）

struct PersonalityBadgeView: View {
    let personality: ListenerPersonality
    var size: CGFloat = 120

    var body: some View {
        if let p = Personality.allCases.first(where: { $0.rawValue == personality.title }) {
            PersonalityIconSymbol(personality: p, size: size)
        } else {
            // ニューカマー等、対応するenumがない場合のフォールバック
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
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
