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
        case .legend:          Color(red: 1.00, green: 0.71, blue: 0.15)
        case .obsessedFan:     Color(red: 1.00, green: 0.23, blue: 0.42)
        case .singleFocus:     Color(red: 0.13, green: 0.88, blue: 0.71)
        case .heavyRotator:    Color(red: 0.70, green: 0.40, blue: 1.00)
        case .explorer:        Color(red: 0.36, green: 0.72, blue: 1.00)
        case .loyalListener:   Color(red: 0.29, green: 0.55, blue: 1.00)
        case .growingListener: Color(red: 0.20, green: 0.88, blue: 0.56)
        case .nostalgic:       Color(red: 1.00, green: 0.71, blue: 0.36)
        case .genreAddict:     Color(red: 0.96, green: 0.82, blue: 0.25)
        case .balanced:        Color(red: 0.62, green: 0.42, blue: 1.00)
        case .collector:       Color(red: 0.76, green: 0.41, blue: 1.00)
        case .streamingFan:    Color(red: 0.98, green: 0.14, blue: 0.24)
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

// MARK: - Rendering infrastructure (sanko/Core.swift 移植)

private let pTWO_PI: Double = 2.0 * .pi

private extension Color {
    init(sankoHex hex: String) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(.sRGB,
                  red:   Double((rgb & 0xFF0000) >> 16) / 255,
                  green: Double((rgb & 0x00FF00) >>  8) / 255,
                  blue:  Double( rgb & 0x0000FF)        / 255,
                  opacity: 1)
    }
}

private struct BadgePalette {
    let colors: [Color]
    let rgb: [(r: Double, g: Double, b: Double)]

    init(_ hexes: [String]) {
        colors = hexes.map { Color(sankoHex: $0) }
        rgb = hexes.map { h -> (Double, Double, Double) in
            let s = h.replacingOccurrences(of: "#", with: "")
            var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
            return (Double((v & 0xFF0000) >> 16) / 255,
                    Double((v & 0x00FF00) >>  8) / 255,
                    Double( v & 0x0000FF)        / 255)
        }
    }

    subscript(_ i: Int) -> Color {
        colors[((i % colors.count) + colors.count) % colors.count]
    }

    func interpolated(at t: Double, opacity: Double = 1) -> Color {
        let n = Double(rgb.count)
        let f = (t.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * n
        let i = Int(floor(f)) % rgb.count
        let j = (i + 1) % rgb.count
        let k = f - floor(f)
        let a = rgb[i], b = rgb[j]
        return Color(.sRGB,
                     red:   a.r + (b.r - a.r) * k,
                     green: a.g + (b.g - a.g) * k,
                     blue:  a.b + (b.b - a.b) * k,
                     opacity: opacity)
    }
}

private struct BadgeCanvas {
    let W: Double = 400, H: Double = 310
    var cx: Double { W / 2 }
    var cy: Double { H / 2 }
}

private extension GraphicsContext {
    mutating func badgeBloom(radius: Double, _ body: (inout GraphicsContext) -> Void) {
        drawLayer { l in l.addFilter(.blur(radius: radius)); body(&l) }
        body(&self)
    }

    @discardableResult
    mutating func enterBadgeDesignSpace(_ sz: CGSize) -> BadgeCanvas {
        let dc = BadgeCanvas()
        let s = max(sz.width / dc.W, sz.height / dc.H)
        translateBy(x: (sz.width  - dc.W * s) / 2,
                    y: (sz.height - dc.H * s) / 2)
        scaleBy(x: s, y: s)
        return dc
    }
}

private func bSmooth(_ pts: [CGPoint]) -> Path {
    var p = Path(); guard pts.count >= 2 else { return p }
    p.move(to: pts[0])
    for i in 0..<pts.count - 1 {
        let mid = CGPoint(x: (pts[i].x + pts[i+1].x) / 2,
                          y: (pts[i].y + pts[i+1].y) / 2)
        p.addQuadCurve(to: mid, control: pts[i])
    }
    p.addLine(to: pts.last!); return p
}

private func bPoly(_ pts: [CGPoint], closed: Bool = false) -> Path {
    var p = Path(); guard !pts.isEmpty else { return p }
    p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) }
    if closed { p.closeSubpath() }; return p
}

private func bCircle(cx: Double, cy: Double, r: Double) -> Path {
    Circle().path(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

private func bEllipse(cx: Double, cy: Double, rx: Double, ry: Double) -> Path {
    Ellipse().path(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
}

private func bSeg(_ a: CGPoint, _ b: CGPoint) -> Path {
    var p = Path(); p.move(to: a); p.addLine(to: b); return p
}

// MARK: - Wave views (バランス型以外は Renderer に委譲)

private struct LegendWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = LegendBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#FFE08A","#FFB627","#FF7A1A"]))
        }
    }
}

private struct ObsessedFanWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = OshiBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#FFB3C7","#FF3B6B","#C71F4C"]))
        }
    }
}

private struct SingleFocusWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = FocusBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#9DFFE3","#22E1B6","#0D9B7B"]))
        }
    }
}

private struct HeavyRotatorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = HeavyBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#E6B8FF","#B265FF","#7A2BD4"]))
        }
    }
}

private struct ExplorerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = ExplorerBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#7AE0FF","#A06BFF","#FF6BD2"]))
        }
    }
}

private struct LoyalListenerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = FixedBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#8FB8FF","#4A8BFF","#1D58D9"]))
        }
    }
}

private struct GrowingListenerWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = GrowthBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#A0FFD0","#33E08E","#0F9A5A"]))
        }
    }
}

private struct NostalgicWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = NostalgicBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#FFDFA8","#FFB55C","#E07A1A"]))
        }
    }
}

private struct GenreAddictWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = GenreBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#FFEFA0","#F5D040","#B8911C"]))
        }
    }
}

// MARK: - 10. バランス型 ── 変更なし

private struct BalancedWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    var body: some View {
        Canvas { ctx, sz in
            let half = sz.width / 2; let cx = half; let cy = half
            let s = sz.width / 400; let t = CGFloat(spin / 60)
            ctx.blendMode = .screen
            let rings: [(r: CGFloat, col: Color, dir: CGFloat, sd: Int)] = [
                (half*0.78, Color(red: 1.00, green: 0.33, blue: 0.47),  1, 0),
                (half*0.61, Color(red: 1.00, green: 0.67, blue: 0.20), -1, 8),
                (half*0.44, Color(red: 0.40, green: 1.00, blue: 0.60),  1, 16),
                (half*0.28, Color(red: 0.27, green: 0.67, blue: 1.00), -1, 24),
                (half*0.13, Color(red: 0.67, green: 0.40, blue: 1.00),  1, 32),
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

private struct CollectorWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = CollectorBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#EAB6FF","#C168FF","#8829D4"]))
        }
    }
}

private struct StreamingFanWave: View {
    let size: CGFloat; let phase: Double; let spin: Double
    @State private var r = SubscriptionBR()
    var body: some View {
        Canvas { ctx, sz in
            r.draw(context: &ctx, size: sz, t: spin / 60,
                   palette: BadgePalette(["#FF7AA3","#FA243C","#A06BFF","#48C4FF"]))
        }
    }
}

// MARK: - Organic Ring Helpers (バランス型専用)

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

// MARK: - Renderer classes (sanko 移植、名前衝突回避のため BR サフィックス)

// 01 Legend
private final class LegendBR {
    struct Ptcl { let angle, radius, baseR, phase, speed: Double; let ci: Int }
    struct Chord { let a1, a2, phase: Double }
    let ptcls: [Ptcl]; let chords: [Chord]; let ticks: [Double]
    init() {
        ptcls  = (0..<60).map { _ in Ptcl(angle: .random(in: 0...pTWO_PI), radius: 78 + .random(in: 6...50), baseR: .random(in: 0.4...1.8), phase: .random(in: 0...pTWO_PI), speed: .random(in: 0.15...0.5), ci: Double.random(in: 0...1) > 0.7 ? 0 : 1) }
        chords = (0..<7).map { _ in let a = Double.random(in: 0...pTWO_PI); return Chord(a1: a, a2: a + .random(in: 0.5...2.5), phase: .random(in: 0...pTWO_PI)) }
        ticks  = (0..<80).map { 3 + abs(sin(Double($0) * 1.7)) * 5 }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 4, R = 78.0, rot = t * 6 * .pi / 180
        let glowR = 90 + sin(t * 1.4) * 18
        context.fill(bCircle(cx: cx, cy: cy, r: glowR), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.35), location: 0),
                             .init(color: palette[1].opacity(0), location: 0.6),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: glowR))
        context.badgeBloom(radius: 2.8) { ctx in
            for i in 0..<80 {
                let a = Double(i) / 80.0 * pTWO_PI + rot
                ctx.stroke(bSeg(CGPoint(x: cx+cos(a)*R, y: cy+sin(a)*R),
                                CGPoint(x: cx+cos(a)*(R+ticks[i]), y: cy+sin(a)*(R+ticks[i]))),
                           with: .color(palette[1].opacity(0.85)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
            ctx.stroke(bCircle(cx: cx, cy: cy, r: R),   with: .color(palette[1].opacity(0.6)),  lineWidth: 1)
            ctx.stroke(bCircle(cx: cx, cy: cy, r: R-7), with: .color(palette[0].opacity(0.35)), lineWidth: 0.5)
            for c in chords {
                let a1 = c.a1+rot, a2 = c.a2+rot
                ctx.stroke(bSeg(CGPoint(x: cx+cos(a1)*R, y: cy+sin(a1)*R),
                                CGPoint(x: cx+cos(a2)*R, y: cy+sin(a2)*R)),
                           with: .color(palette[0].opacity(0.15+0.35*abs(sin(t*0.8+c.phase)))),
                           lineWidth: 0.6)
            }
            for i in 0..<5 {
                let a = Double(i)/5.0*pTWO_PI+rot
                ctx.fill(bCircle(cx: cx+cos(a)*R, cy: cy+sin(a)*R, r: 2+abs(sin(t*2+a))*1.6),
                         with: .color(palette[0]))
            }
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                let a = p.angle + t*p.speed*0.05
                ctx.fill(bCircle(cx: cx+cos(a)*p.radius, cy: cy+sin(a)*p.radius,
                                 r: p.baseR*(0.4+0.6*abs(sin(t*1.6+p.phase)))),
                         with: .color(palette[p.ci].opacity(0.6)))
            }
        }
    }
}

// 02 Oshi
private final class OshiBR {
    struct Ptcl { let angle, speed, phase: Double }
    let ptcls: [Ptcl]; let ringPhases: [Double]
    init() {
        ptcls      = (0..<40).map { _ in Ptcl(angle: .random(in: 0...pTWO_PI), speed: .random(in: 20...60), phase: .random(in: 0...3)) }
        ringPhases = (0..<5).map { Double($0) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 10
        context.fill(bEllipse(cx: cx, cy: cy, rx: dc.W*0.7, ry: dc.H*0.5), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: dc.W*0.7))
        context.badgeBloom(radius: 1.6) { ctx in
            for ph in ringPhases {
                let k = ((t+ph).truncatingRemainder(dividingBy: 3)) / 3
                ctx.stroke(bCircle(cx: cx, cy: cy, r: 5+k*110),
                           with: .color(palette[1].opacity((1-k)*0.7)), lineWidth: 1)
            }
        }
        var pts = [CGPoint](), pts2 = [CGPoint](); var x = 0.0
        while x <= dc.W {
            let env = exp(-abs((x-cx)/cx)*4) * 70
            pts.append(CGPoint(x: x,  y: cy + sin(x*0.35-t*12)*env*cos(t*4+x*0.05)))
            pts2.append(CGPoint(x: x, y: cy + sin(x*0.4-t*8+1)*env*0.6))
            x += 2
        }
        context.badgeBloom(radius: 2.8) { ctx in
            ctx.stroke(bSmooth(pts), with: .color(palette[1]),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        context.stroke(bSmooth(pts2), with: .color(palette[0].opacity(0.7)), lineWidth: 0.8)
        let peakH = 110 + sin(t*6)*18
        var spike = Path()
        spike.move(to: CGPoint(x: cx-3, y: cy)); spike.addLine(to: CGPoint(x: cx, y: cy-peakH)); spike.addLine(to: CGPoint(x: cx+3, y: cy))
        spike.move(to: CGPoint(x: cx-3, y: cy)); spike.addLine(to: CGPoint(x: cx, y: cy+peakH*0.7)); spike.addLine(to: CGPoint(x: cx+3, y: cy))
        context.badgeBloom(radius: 6)   { ctx in ctx.stroke(spike, with: .color(palette[0]), lineWidth: 2) }
        context.badgeBloom(radius: 2.8) { ctx in
            ctx.stroke(bSeg(CGPoint(x: cx, y: 0), CGPoint(x: cx, y: dc.H)),
                       with: .color(palette[0].opacity(0.3+abs(sin(t*6))*0.4)), lineWidth: 1)
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                let k = ((t*p.speed*0.02+p.phase).truncatingRemainder(dividingBy: 1))
                ctx.fill(bCircle(cx: cx+cos(p.angle)*k*110, cy: cy+sin(p.angle)*k*110*0.55, r: 0.85),
                         with: .color(palette[0].opacity((1-k)*0.9)))
            }
        }
    }
}

// 03 Focus
private final class FocusBR {
    struct Bar    { let x, env, phase: Double }
    struct Ptcl   { let x, y, phase: Double }
    let bars: [Bar]; let ptcls: [Ptcl]
    init() {
        let cx = 200.0
        bars  = (0..<72).map { i in let x = Double(i)/71.0*400; let dx = (x-cx)/cx; return Bar(x: x, env: exp(-dx*dx*7), phase: .random(in: 0...pTWO_PI)) }
        ptcls = (0..<22).map { _ in Ptcl(x: 200 + .random(in: -90...90), y: 175 - .random(in: 15...95), phase: .random(in: 0...pTWO_PI)) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 30
        context.fill(bEllipse(cx: cx, cy: cy, rx: 100+sin(t*3)*16, ry: 55), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.5), location: 0),
                             .init(color: palette[1].opacity(0), location: 0.65)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 110))
        context.stroke(bSeg(CGPoint(x: 0, y: cy), CGPoint(x: dc.W, y: cy)),
                       with: .color(palette[1].opacity(0.18)), lineWidth: 0.4)
        var tips = [CGPoint]()
        context.badgeBloom(radius: 2.8) { ctx in
            for b in bars {
                let hUp = b.env*(75+sin(t*8+b.phase)*55) + b.env*22
                ctx.stroke(bSeg(CGPoint(x: b.x, y: cy-max(2,hUp)),
                                CGPoint(x: b.x, y: cy+max(1,hUp*0.42))),
                           with: .color(palette[1].opacity(0.5+b.env*0.5)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                tips.append(CGPoint(x: b.x, y: cy-hUp))
            }
        }
        context.badgeBloom(radius: 6) { ctx in
            ctx.stroke(bSmooth(tips), with: .color(palette[0].opacity(0.85)), lineWidth: 1.2)
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                ctx.fill(bCircle(cx: p.x, cy: p.y+sin(t*1.6+p.phase)*6, r: 1.1),
                         with: .color(palette[0].opacity(0.3+abs(sin(t*2+p.phase))*0.5)))
            }
        }
    }
}

// 04 Heavy
private final class HeavyBR {
    struct Ptcl { let angle, radius, baseR, phase, speed: Double; let ci: Int }
    let ptcls: [Ptcl]; let seeds: [Double]
    init() {
        ptcls = (0..<80).map { _ in Ptcl(angle: .random(in: 0...pTWO_PI), radius: 80 + .random(in: -10...40), baseR: .random(in: 0.4...1.5), phase: .random(in: 0...pTWO_PI), speed: .random(in: 0.1...0.3), ci: Double.random(in: 0...1) > 0.5 ? 0 : 1) }
        seeds = (0..<36).map { _ in .random(in: 0...1) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 5, R = 80.0
        context.fill(bCircle(cx: cx, cy: cy, r: 110), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.0),  location: 0),
                             .init(color: palette[1].opacity(0.18), location: 0.55),
                             .init(color: palette[1].opacity(0),    location: 0.75)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 110))
        var outer = [CGPoint](), inner = [CGPoint]()
        for i in 0...96 {
            let a = Double(i)/96.0*pTWO_PI
            let n = sin(a*7+t*1.5)*4 + sin(a*13+t*2.2)*3 + sin(a*23+t*1.1)*2.2
            outer.append(CGPoint(x: cx+cos(a)*(R+n),   y: cy+sin(a)*(R+n)))
            inner.append(CGPoint(x: cx+cos(a)*(R+n-7), y: cy+sin(a)*(R+n-7)))
        }
        context.badgeBloom(radius: 2.8) { ctx in
            ctx.stroke(bPoly(outer, closed: true), with: .color(palette[1]),
                       style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        context.stroke(bPoly(inner, closed: true), with: .color(palette[0].opacity(0.7)), lineWidth: 0.8)
        context.stroke(bCircle(cx: cx, cy: cy, r: R), with: .color(palette[0].opacity(0.35)), lineWidth: 0.4)
        context.badgeBloom(radius: 1.6) { ctx in
            for (idx, seed) in seeds.enumerated() {
                let a = Double(idx)/36.0*pTWO_PI
                let h = 4 + abs(sin(t*3+seed*10))*12
                ctx.stroke(bSeg(CGPoint(x: cx+cos(a)*R, y: cy+sin(a)*R),
                                CGPoint(x: cx+cos(a)*(R+h), y: cy+sin(a)*(R+h))),
                           with: .color(palette[0].opacity(0.2+abs(sin(t*2+seed*7))*0.6)),
                           style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
            }
            for p in ptcls {
                let a = p.angle + t*p.speed*0.04
                ctx.fill(bCircle(cx: cx+cos(a)*p.radius, cy: cy+sin(a)*p.radius,
                                 r: p.baseR*(0.5+0.5*abs(sin(t*2+p.phase)))),
                         with: .color(palette[p.ci].opacity(0.6)))
            }
        }
    }
}

// 05 Explorer
private final class ExplorerBR {
    struct Stream { let angle: Double; let ci: Int; let phase: Double }
    struct Ptcl   { let x0, y0, vx, vy, baseR, phase, life, t0: Double; let ci: Int }
    let streams: [Stream]; let ptcls: [Ptcl]
    init() {
        let angles = [-0.45, -0.18, 0.05, 0.25, 0.5]
        streams = angles.enumerated().map { i, a in Stream(angle: a, ci: i % 3, phase: Double(i)) }
        ptcls   = (0..<130).map { _ in Ptcl(x0: .random(in: 0...400), y0: .random(in: 0...310), vx: .random(in: -30...30), vy: .random(in: -15...15), baseR: .random(in: 0.4...2.0), phase: .random(in: 0...pTWO_PI), life: .random(in: 2...6), t0: .random(in: 0...4), ci: .random(in: 0...2)) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 10
        context.fill(bCircle(cx: cx, cy: cy, r: dc.W*0.7), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.35), location: 0),
                             .init(color: palette[2].opacity(0.05), location: 0.7),
                             .init(color: palette[2].opacity(0),    location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: dc.W*0.7))
        context.badgeBloom(radius: 2.8) { ctx in
            for s in streams {
                var pts = [CGPoint](); var x = -20.0
                while x <= dc.W+20 {
                    let baseY = cy + (x-cx)/100*50*tan(s.angle)
                    pts.append(CGPoint(x: x, y: baseY+sin(x*0.04+t*1.5+s.phase)*24+sin(x*0.09+t*2+s.phase)*10))
                    x += 6
                }
                ctx.stroke(bSmooth(pts), with: .color(palette[s.ci].opacity(0.85)),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                let local = ((t+p.t0).truncatingRemainder(dividingBy: p.life)) / p.life
                let op = sin(local * .pi) * 0.85
                ctx.fill(bCircle(cx: p.x0+p.vx*local*2, cy: p.y0+p.vy*local*2+sin(t*1.2+p.phase)*4,
                                 r: max(0.1, p.baseR*(0.5+0.5*sin(local * .pi)))),
                         with: .color(palette[p.ci].opacity(op)))
            }
        }
    }
}

// 06 Fixed
private final class FixedBR {
    let offsets: [Double]
    init() { offsets = (0..<14).map { Double($0) / 14.0 } }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 15
        context.fill(bCircle(cx: cx, cy: cy, r: 150), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 150))
        for i in 0..<30 {
            let x = Double(i)/29.0*dc.W; let env = 1 - abs((x-cx)/cx)*0.6
            context.stroke(bSeg(CGPoint(x: x, y: cy-50*env), CGPoint(x: x, y: cy+50*env)),
                           with: .color(palette[1].opacity(0.18*env)), lineWidth: 0.4)
        }
        for i in 0..<3 {
            var pts = [CGPoint](); var x = 0.0
            while x <= dc.W {
                let env = (1 - abs((x-cx)/cx))*0.85 + 0.15
                pts.append(CGPoint(x: x, y: cy+sin(x*0.06-t*1.6+Double(i)*0.4)*30*env)); x += 4
            }
            context.stroke(bSmooth(pts), with: .color(palette[0].opacity(0.18+Double(i)*0.06)), lineWidth: 1)
        }
        var pts = [CGPoint](); var x = 0.0
        while x <= dc.W {
            let env = (1 - abs((x-cx)/cx))*0.85 + 0.15
            pts.append(CGPoint(x: x, y: cy+sin(x*0.06-t*1.6)*30*env)); x += 3
        }
        context.badgeBloom(radius: 2.8) { ctx in
            ctx.stroke(bSmooth(pts), with: .color(palette[1]),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
        context.stroke(bSmooth(pts.map { CGPoint(x: $0.x, y: $0.y-0.5) }),
                       with: .color(palette[0].opacity(0.7)), lineWidth: 0.8)
        context.badgeBloom(radius: 1.6) { ctx in
            for ox in offsets {
                let x = ((ox+t*0.05).truncatingRemainder(dividingBy: 1)) * dc.W
                let env = (1 - abs((x-cx)/cx))*0.85 + 0.15
                ctx.fill(bCircle(cx: x, cy: cy+sin(x*0.06-t*1.6)*30*env, r: 1.3),
                         with: .color(palette[0]))
            }
        }
    }
}

// 07 Growth
private final class GrowthBR {
    struct Bar  { let x, trend, phase: Double }
    struct Ptcl { let t0, life, x: Double }
    let bars: [Bar]; let ptcls: [Ptcl]
    init() {
        bars  = (0..<36).map { i in Bar(x: 20+Double(i)/35.0*360, trend: pow(Double(i)/35.0,1.3), phase: .random(in: 0...pTWO_PI)) }
        ptcls = (0..<40).map { _ in Ptcl(t0: .random(in: 0...4), life: .random(in: 2...4), x: .random(in: 200...380)) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        context.fill(bCircle(cx: dc.cx, cy: dc.cy, r: 150), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: dc.cx, y: dc.cy), startRadius: 0, endRadius: 150))
        context.badgeBloom(radius: 1.6) { ctx in
            for b in bars {
                let h = (30+b.trend*110) + sin(t*4+b.phase)*(8+b.trend*14)
                ctx.stroke(bSeg(CGPoint(x: b.x, y: dc.H-40), CGPoint(x: b.x, y: dc.H-40-h)),
                           with: .color(palette[1].opacity(0.55)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        }
        var pts = [CGPoint](); var x = 0.0
        while x <= dc.W {
            let k = x/dc.W
            pts.append(CGPoint(x: x, y: (dc.H-50)-pow(k,1.4)*130+sin(x*0.05-t*2)*(8+k*12)+sin(x*0.12+t*1.4)*4))
            x += 3
        }
        context.badgeBloom(radius: 2.8) { ctx in ctx.stroke(bSmooth(pts), with: .color(palette[1]), lineWidth: 1.8) }
        context.stroke(bSmooth(pts.map { CGPoint(x: $0.x, y: $0.y-1) }),
                       with: .color(palette[0].opacity(0.8)), lineWidth: 0.8)
        if let head = pts.dropLast(7).last {
            context.badgeBloom(radius: 6) { ctx in
                ctx.fill(bCircle(cx: head.x, cy: head.y-1, r: 3+sin(t*4)), with: .color(palette[0]))
            }
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                let local = ((t+p.t0).truncatingRemainder(dividingBy: p.life)) / p.life
                let baseY = (dc.H-50) - pow(p.x/dc.W,1.4)*130
                ctx.fill(bCircle(cx: p.x+sin(t*2+p.t0)*3, cy: baseY-local*50, r: 1.0),
                         with: .color(palette[0].opacity(sin(local * .pi)*0.8)))
            }
        }
    }
}

// 08 Nostalgic
private final class NostalgicBR {
    struct Layer { let amp, freq: Double; let ci: Int; let w, op, speed, phase: Double; let hiBloom: Bool }
    struct Ptcl  { let x0, y0, phase: Double }
    let layers: [Layer]; let ptcls: [Ptcl]
    init() {
        layers = [Layer(amp: 38, freq: 0.04, ci: 2, w: 1.4, op: 0.75, speed: 1.0, phase: 0, hiBloom: false),
                  Layer(amp: 30, freq: 0.05, ci: 1, w: 1.6, op: 0.95, speed: 1.3, phase: 1, hiBloom: true),
                  Layer(amp: 22, freq: 0.07, ci: 0, w: 1.2, op: 0.7,  speed: 1.7, phase: 2, hiBloom: false),
                  Layer(amp: 14, freq: 0.10, ci: 0, w: 0.9, op: 0.55, speed: 2.1, phase: 3, hiBloom: false)]
        ptcls = (0..<35).map { _ in Ptcl(x0: .random(in: 0...400), y0: .random(in: 40...270), phase: .random(in: 0...pTWO_PI)) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 15
        context.fill(bCircle(cx: cx, cy: cy, r: 150), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 150))
        for L in layers {
            var pts = [CGPoint](); var x = -10.0
            while x <= dc.W+10 {
                let env = 1 - abs((x-cx)/cx)*0.7
                pts.append(CGPoint(x: x, y: cy+sin(x*L.freq-t*L.speed)*L.amp*env+sin(x*L.freq*1.8+t*L.speed*0.6)*L.amp*0.3*env))
                x += 4
            }
            let col = palette[L.ci].opacity(L.op)
            let r   = L.hiBloom ? 2.8 : 1.6
            context.badgeBloom(radius: r) { ctx in
                ctx.stroke(bSmooth(pts), with: .color(col), style: StrokeStyle(lineWidth: L.w, lineCap: .round))
            }
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                ctx.fill(bCircle(cx: p.x0+sin(t*0.6+p.phase)*8, cy: p.y0+cos(t*0.5+p.phase)*5, r: 0.9),
                         with: .color(palette[0].opacity(0.3+abs(sin(t+p.phase))*0.45)))
            }
        }
    }
}

// 09 Genre
private final class GenreBR {
    struct Strand { let x, phase: Double }
    let strands: [Strand]
    init() { strands = (0..<130).map { i in Strand(x: 10+Double(i)/129.0*380, phase: .random(in: 0...pTWO_PI)) } }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 15
        context.fill(bCircle(cx: cx, cy: cy, r: 160), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 160))
        context.stroke(bSeg(CGPoint(x: 0, y: cy), CGPoint(x: dc.W, y: cy)),
                       with: .color(palette[1].opacity(0.2)), lineWidth: 0.5)
        context.badgeBloom(radius: 1.6) { ctx in
            for s in strands {
                let env = exp(-pow((s.x-cx)/cx, 2)*3.5)
                let h   = env*(4 + abs(sin(s.x*0.3+t*7+s.phase))*38)
                ctx.stroke(bSeg(CGPoint(x: s.x, y: cy-h), CGPoint(x: s.x, y: cy+h*0.6)),
                           with: .color(palette[1].opacity(0.4+env*0.5)),
                           style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }
        }
        var up = [CGPoint](), dn = [CGPoint](); var x = 0.0
        while x <= dc.W {
            let env = exp(-pow((x-cx)/cx, 2)*2.5)
            up.append(CGPoint(x: x, y: cy - env*(10+sin(x*0.45-t*9)*20)))
            dn.append(CGPoint(x: x, y: cy + env*(8+sin(x*0.35-t*7)*12)))
            x += 2
        }
        context.badgeBloom(radius: 2.8) { ctx in
            ctx.stroke(bSmooth(up), with: .color(palette[1]), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
        context.stroke(bSmooth(up.map { CGPoint(x: $0.x, y: $0.y-0.5) }),
                       with: .color(palette[0].opacity(0.8)), lineWidth: 0.7)
        context.badgeBloom(radius: 1.6) { ctx in
            ctx.stroke(bSmooth(dn), with: .color(palette[2].opacity(0.55)), lineWidth: 1.1)
        }
    }
}

// 11 Collector
private final class CollectorBR {
    struct Beam   { let x, phase: Double }
    struct FloatCD { let x, y, R, tilt, phase: Double }
    struct Ptcl   { let x, y, phase: Double; let ci: Int }
    let beams: [Beam]; let floats: [FloatCD]; let ptcls: [Ptcl]
    let stackCount = 14
    init() {
        let cx = 200.0
        beams  = (0..<9).map { i in Beam(x: cx-40+Double(i)*10, phase: .random(in: 0...pTWO_PI)) }
        floats = [FloatCD(x: 56,  y: 170, R: 30, tilt: 0.34, phase: 0.0),
                  FloatCD(x: 348, y: 130, R: 26, tilt: 0.30, phase: 1.7),
                  FloatCD(x: 340, y: 242, R: 20, tilt: 0.36, phase: 3.4)]
        ptcls  = (0..<40).map { _ in Ptcl(x: cx + .random(in: -90...90), y: 165 + .random(in: -90...90), phase: .random(in: 0...pTWO_PI), ci: Double.random(in: 0...1) > 0.5 ? 0 : 1) }
    }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 10
        context.fill(bCircle(cx: cx, cy: cy, r: 140), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 140))
        context.badgeBloom(radius: 1.6) { ctx in
            for b in beams {
                let env = max(0.2, 1 - abs((b.x-cx)/50)*0.5)
                ctx.stroke(bSeg(CGPoint(x: b.x, y: cy-80), CGPoint(x: b.x, y: cy+80)),
                           with: .color(palette[0].opacity(env*(0.3+abs(sin(t*2.5+b.phase))*0.5))),
                           style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
            }
        }
        context.badgeBloom(radius: 6) { ctx in
            ctx.fill(Path(CGRect(x: cx-1.5, y: cy-90, width: 3, height: 180)),
                     with: .linearGradient(
                        Gradient(stops: [.init(color: palette[0].opacity(0),   location: 0),
                                         .init(color: palette[0].opacity(0.7), location: 0.5),
                                         .init(color: palette[0].opacity(0),   location: 1)]),
                        startPoint: CGPoint(x: cx, y: cy-90),
                        endPoint:   CGPoint(x: cx, y: cy+90)))
        }
        context.badgeBloom(radius: 2.8) { ctx in
            for i in 0..<stackCount {
                let k  = Double(i)/Double(stackCount-1)
                let y  = cy - 78 + k*156
                let rx = (68 - abs(0.5-k)*38) + sin(t*2.4+Double(i)*0.4)*4
                let ry = rx * (0.07 + abs(0.5-k)*0.045)
                let op = 0.4 + abs(sin(t*1.1+Double(i)*0.3))*0.5
                ctx.stroke(bEllipse(cx: cx, cy: y, rx: rx,       ry: ry),       with: .color(palette[1].opacity(op)),   lineWidth: 1.1)
                ctx.stroke(bEllipse(cx: cx, cy: y, rx: rx*0.78,  ry: ry*0.78),  with: .color(palette[0].opacity(0.55)), lineWidth: 0.4)
                ctx.stroke(bEllipse(cx: cx, cy: y, rx: rx*0.42,  ry: ry*0.42),  with: .color(palette[0].opacity(0.5)),  lineWidth: 0.4)
                ctx.fill(  bEllipse(cx: cx, cy: y, rx: rx*0.09,  ry: max(0.8, ry*0.65)), with: .color(.black.opacity(0.7)))
            }
        }
        for f in floats {
            let fx = f.x + cos(t*0.55+f.phase)*3
            let fy = f.y + sin(t*0.85+f.phase)*5
            context.badgeBloom(radius: 2.8) { ctx in
                for ring in 0..<4 {
                    let r = f.R * (0.28 + Double(ring+1)/4.0*0.72)
                    ctx.stroke(bEllipse(cx: fx, cy: fy, rx: r, ry: r*f.tilt),
                               with: .color(ring==3 ? palette[1].opacity(0.85) : palette[0].opacity(0.55)),
                               lineWidth: ring==3 ? 1.0 : 0.55)
                }
                ctx.stroke(bEllipse(cx: fx, cy: fy, rx: f.R*0.22, ry: f.R*0.22*f.tilt),
                           with: .color(palette[0].opacity(0.6)), lineWidth: 0.5)
                ctx.fill(  bEllipse(cx: fx, cy: fy, rx: f.R*0.10, ry: f.R*0.10*f.tilt),
                           with: .color(.black.opacity(0.92)))
            }
        }
        var pts = [CGPoint](); var x = cx-60
        while x <= cx+60 {
            let env = exp(-pow((x-cx)/60, 2)*3)
            pts.append(CGPoint(x: x, y: cy-92+sin(x*0.6+t*8)*env*13)); x += 3
        }
        context.badgeBloom(radius: 1.6) { ctx in
            ctx.stroke(bSmooth(pts), with: .color(palette[1].opacity(0.6)), lineWidth: 1)
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                ctx.fill(bCircle(cx: p.x+sin(t*0.8+p.phase)*4, cy: p.y+cos(t*0.7+p.phase)*4, r: 0.9),
                         with: .color(palette[p.ci].opacity(0.25+abs(sin(t+p.phase))*0.4)))
            }
        }
    }
}

// 12 Subscription
private final class SubscriptionBR {
    struct Cfg  { let hex: String; let w, amp, offset, speed, op: Double }
    struct Ptcl { let layer: Int; let t0: Double }
    let layers: [Cfg] = [
        Cfg(hex: "#A06BFF", w: 1.2, amp: 36, offset: 0.0, speed: 1.25, op: 0.55),
        Cfg(hex: "#FA243C", w: 2.0, amp: 32, offset: 0.8, speed: 0.95, op: 1.00),
        Cfg(hex: "#FF7AA3", w: 1.5, amp: 34, offset: 0.4, speed: 1.10, op: 0.85),
        Cfg(hex: "#48C4FF", w: 1.0, amp: 30, offset: 1.6, speed: 1.40, op: 0.55),
    ]
    let ptcls: [Ptcl]
    init() { ptcls = (0..<80).map { _ in Ptcl(layer: .random(in: 0...3), t0: .random(in: 0...4)) } }
    func draw(context: inout GraphicsContext, size: CGSize, t: Double, palette: BadgePalette) {
        let dc = context.enterBadgeDesignSpace(size)
        let cx = dc.cx, cy = dc.cy + 10
        context.fill(bCircle(cx: cx, cy: cy, r: 160), with: .radialGradient(
            Gradient(stops: [.init(color: palette[1].opacity(0.18), location: 0.4),
                             .init(color: palette[1].opacity(0), location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 160))
        var allPts = [[CGPoint]]()
        for L in layers {
            var pts = [CGPoint](); var x = -10.0
            while x <= dc.W+10 {
                let env = 1 - abs((x-cx)/cx)*0.4
                let w1 = sin(x*0.025 - t*L.speed + L.offset) * L.amp * env
                let w2 = sin(x*0.05  + t*L.speed*0.7 + L.offset) * L.amp * 0.4 * env
                pts.append(CGPoint(x: x, y: cy + w1 + w2))
                x += 4
            }
            allPts.append(pts)
        }
        for (i, L) in layers.enumerated() {
            let col  = Color(sankoHex: L.hex)
            let path = bSmooth(allPts[i])
            context.badgeBloom(radius: 6)   { ctx in ctx.stroke(path, with: .color(col.opacity(0.25)), lineWidth: L.w+1) }
            context.badgeBloom(radius: 2.8) { ctx in ctx.stroke(path, with: .color(col.opacity(L.op)), style: StrokeStyle(lineWidth: L.w, lineCap: .round)) }
        }
        context.badgeBloom(radius: 1.6) { ctx in
            for p in ptcls {
                let L     = layers[p.layer]
                let local = ((t*0.15+p.t0).truncatingRemainder(dividingBy: 1))
                let x     = local * dc.W
                let env   = 1 - abs((x-cx)/cx)*0.4
                let y     = cy + sin(x*0.025-t*L.speed+L.offset)*L.amp*env
                          + sin(x*0.05+t*L.speed*0.7+L.offset)*L.amp*0.4*env
                ctx.fill(bCircle(cx: x, cy: y, r: 1.1),
                         with: .color(Color(sankoHex: L.hex).opacity(sin(local * .pi)*0.85)))
            }
        }
    }
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
