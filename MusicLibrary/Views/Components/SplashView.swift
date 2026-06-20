// SplashView.swift
// MusicLibrary

import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    @Binding var isShowing: Bool
    @AppStorage("splashTutorialShown") private var tutorialShown = false

    @State private var startDate    = Date()
    @State private var waveScale    : CGFloat = 0.01
    @State private var waveOpacity  : Double  = 0
    @State private var letterSpacing: CGFloat = -4
    @State private var textOpacity  : Double  = 0
    @State private var rootOpacity  : Double  = 1
    @State private var showTutorial = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 波形アニメーション
            TimelineView(.animation) { tl in
                let elapsed = tl.date.timeIntervalSince(startDate)
                SplashWaveView(elapsed: elapsed)
                    .scaleEffect(waveScale)
                    .opacity(waveOpacity)
            }
            .ignoresSafeArea()

            // MUSIC LIBRARY テキスト
            Text("MUSIC LIBRARY")
                .font(.system(size: 13, weight: .heavy))
                .tracking(letterSpacing)
                .foregroundStyle(.white)
                .opacity(textOpacity)

            // 初回チュートリアルオーバーレイ
            if showTutorial {
                SplashTutorialOverlay(onDismiss: dismissFromTutorial)
                    .transition(.opacity)
            }
        }
        .opacity(rootOpacity)
        .onAppear { runAnimation() }
    }

    // MARK: - Animation sequence

    private func runAnimation() {
        startDate = Date()

        // 0.00s: 光点が出現
        withAnimation(.easeIn(duration: 0.25)) {
            waveScale   = 0.04
            waveOpacity = 1.0
        }

        // 0.25s: 放射状に展開
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.65)) {
                waveScale = 1.9
            }
        }

        // 0.90s: 収縮 + テキスト出現
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                waveScale   = 0.14
                waveOpacity = 0.38
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.12)) {
                letterSpacing = 10
                textOpacity   = 1
            }
        }

        // 1.60s: チュートリアル or フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.60) {
            if !tutorialShown {
                withAnimation(.easeIn(duration: 0.30)) { showTutorial = true }
            } else {
                fadeOut()
            }
        }
    }

    private func fadeOut() {
        withAnimation(.easeOut(duration: 0.35)) { rootOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { isShowing = false }
    }

    private func dismissFromTutorial() {
        tutorialShown = true
        withAnimation(.easeOut(duration: 0.35)) { showTutorial = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { fadeOut() }
    }
}

// MARK: - Splash Wave Canvas

private struct SplashWaveView: View {
    let elapsed: Double

    private let rings: [(r: Double, col: Color, dir: Double, sd: Int)] = [
        (0.84, Color(red: 1.00, green: 0.33, blue: 0.47),  1,  0),
        (0.65, Color(red: 1.00, green: 0.67, blue: 0.20), -1,  8),
        (0.46, Color(red: 0.40, green: 1.00, blue: 0.60),  1, 16),
        (0.29, Color(red: 0.27, green: 0.67, blue: 1.00), -1, 24),
        (0.13, Color(red: 0.67, green: 0.40, blue: 1.00),  1, 32),
    ]

    var body: some View {
        Canvas { ctx, size in
            let t    = CGFloat(elapsed)
            let cx   = size.width  / 2
            let cy   = size.height / 2
            let half = min(size.width, size.height) / 2
            let lw   = max(1.2, half * 0.009)

            ctx.blendMode = .screen

            for ring in rings {
                splashRingGroup(
                    &ctx, cx: cx, cy: cy, t: t,
                    count: 8,
                    baseR:     CGFloat(ring.r) * half,
                    maxAmp:    half * 0.07,
                    speedBase: 0.30 + CGFloat(ring.r) * 0.10,
                    waveDir:   CGFloat(ring.dir),
                    color:     ring.col,
                    lw:        lw,
                    opacity:   0.48,
                    seed:      ring.sd
                )
            }
        }
    }
}

// MARK: - Tutorial Overlay（初回のみ）

private struct SplashTutorialOverlay: View {
    let onDismiss: () -> Void
    @State private var appear = false

    private let items: [(String, Color)] = [
        ("ライブラリを解析", Color(red: 1.00, green: 0.33, blue: 0.47)),
        ("聴き方を可視化",   Color(red: 0.40, green: 1.00, blue: 0.60)),
        ("音楽人格を発見",   Color(red: 0.67, green: 0.40, blue: 1.00)),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                HStack(spacing: 24) {
                    ForEach(items.indices, id: \.self) { i in
                        TutorialItemView(label: items[i].0, color: items[i].1)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 28)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.70)
                                    .delay(Double(i) * 0.13),
                                value: appear
                            )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onDismiss) {
                    Text("はじめる")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 52)
                        .padding(.vertical, 15)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.50), value: appear)

                Spacer().frame(height: 56)
            }
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }
}

private struct TutorialItemView: View {
    let label: String
    let color: Color
    @State private var startDate = Date()

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.animation) { tl in
                let e = tl.date.timeIntervalSince(startDate)
                Canvas { ctx, size in
                    let t    = CGFloat(e)
                    let cx   = size.width  / 2
                    let cy   = size.height / 2
                    let half = size.width  / 2
                    ctx.blendMode = .screen
                    splashRingGroup(&ctx, cx: cx, cy: cy, t: t,
                                    count: 5, baseR: half * 0.70,
                                    maxAmp: half * 0.22, speedBase: 0.28,
                                    waveDir: 1, color: color,
                                    lw: 1.4, opacity: 0.52, seed: 0)
                    splashRingGroup(&ctx, cx: cx, cy: cy, t: t,
                                    count: 4, baseR: half * 0.36,
                                    maxAmp: half * 0.14, speedBase: 0.44,
                                    waveDir: -1, color: color,
                                    lw: 1.1, opacity: 0.36, seed: 9)
                }
            }
            .frame(width: 76, height: 76)
            .background(Circle().fill(Color.black))
            .clipShape(Circle())
            .shadow(color: color.opacity(0.55), radius: 14)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ring helpers（SplashView 専用）

private func splashRingGroup(
    _ ctx: inout GraphicsContext,
    cx: CGFloat, cy: CGFloat, t: CGFloat,
    count: Int, baseR: CGFloat, maxAmp: CGFloat,
    speedBase: CGFloat, waveDir: CGFloat,
    color: Color, lw: CGFloat, opacity: Double, seed: Int
) {
    for i in 0..<count {
        let f      = CGFloat(i + seed)
        let ph     = f * CGFloat.pi * 1.6180339887
        let spd    = speedBase + f.truncatingRemainder(dividingBy: 7) * 0.09
        let v0     = 0.28 + f.truncatingRemainder(dividingBy: 5) * 0.13
        let v1     = 0.52 + f.truncatingRemainder(dividingBy: 7) * 0.08
        let v2     = 0.81 + f.truncatingRemainder(dividingBy: 4) * 0.08
        let ds     = (sin(t*v0 + f*1.10) + sin(t*v1 + f*2.30) + sin(t*v2 + f*3.70)) / 3
        let scl    = CGFloat((ds + 1) * 0.5)
        let rotSpd = (f.truncatingRemainder(dividingBy: 11) - 5.0) / 5.0 * 0.048
        let path   = splashRingPath(
            cx: cx, cy: cy, baseR: baseR, maxAmp: maxAmp,
            detPh: t * spd + ph,
            jitPh: -(t * spd * 0.8) + ph * 1.3,
            scale: scl, rot: t * rotSpd, dir: waveDir
        )
        ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lw)
    }
}

private func splashRingPath(
    cx: CGFloat, cy: CGFloat,
    baseR: CGFloat, maxAmp: CGFloat,
    detPh: CGFloat, jitPh: CGFloat,
    scale: CGFloat, rot: CGFloat, dir: CGFloat,
    segs: Int = 20
) -> Path {
    var pts = [CGPoint]()
    pts.reserveCapacity(segs)
    for n in 0..<segs {
        let a   = CGFloat(n) / CGFloat(segs) * 2 * .pi
        let det = sin(a * 6 + detPh) * 0.7
        let jit = sin(a * 12 + jitPh) * 0.1
        let r   = baseR + (det + jit) * maxAmp * scale * dir
        let fa  = a + rot
        pts.append(CGPoint(x: cx + r * cos(fa), y: cy + r * sin(fa)))
    }
    return splashCatmullRom(pts)
}

private func splashCatmullRom(_ pts: [CGPoint]) -> Path {
    let n = pts.count; guard n >= 2 else { return Path() }
    var path = Path(); path.move(to: pts[0])
    for i in 0..<n {
        let p0  = pts[(i - 1 + n) % n]; let p1 = pts[i]
        let p2  = pts[(i + 1) % n];     let p3 = pts[(i + 2) % n]
        let cp1 = CGPoint(x: p1.x + (p2.x - p0.x)/6, y: p1.y + (p2.y - p0.y)/6)
        let cp2 = CGPoint(x: p2.x - (p3.x - p1.x)/6, y: p2.y - (p3.y - p1.y)/6)
        path.addCurve(to: p2, control1: cp1, control2: cp2)
    }
    path.closeSubpath()
    return path
}
