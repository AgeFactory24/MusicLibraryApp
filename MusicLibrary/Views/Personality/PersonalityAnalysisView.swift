// PersonalityAnalysisView.swift
// MusicLibrary — "自分の音楽人格を発見する" 体験

import SwiftUI
import UIKit

// MARK: - Main View

struct PersonalityAnalysisView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var vm = PersonalityAnalysisViewModel()
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showExplore = false
    @State private var exploreStartIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("DEV.PreviewPersonality") private var previewPersonalityRaw: String = ""

    private var effectiveTopTag: PersonalityTag? {
        guard let realTag = vm.tags.first else { return nil }
        guard !previewPersonalityRaw.isEmpty,
              let previewPersonality = Personality(rawValue: previewPersonalityRaw) else {
            return realTag
        }
        return PersonalityTag(
            personality: previewPersonality,
            score: realTag.score,
            reason: realTag.reason,
            precision: realTag.precision
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    loadingView
                } else if vm.tags.isEmpty {
                    EmptyPersonalityView()
                } else {
                    contentScroll
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(.white)
        }
        .onAppear { vm.analyze(tracks: libraryVM.tracks) }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ActivityShareSheet(items: [img]) }
        }
        .fullScreenCover(isPresented: $showExplore) {
            PersonalityExploreSheet(userTags: vm.tags, startIndex: exploreStartIndex)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("音楽人格を分析中…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero
                if let top = effectiveTopTag {
                    HeroCard(tag: top, reduceMotion: reduceMotion, onShare: { sharePersonality(tag: top) })
                }

                // Body sections
                VStack(spacing: 24) {
                    if !previewPersonalityRaw.isEmpty {
                        previewBanner
                    }

                    if let metrics = vm.metrics, let top = effectiveTopTag {
                        WhySection(personality: top.personality, metrics: metrics, reduceMotion: reduceMotion)
                    }

                    if vm.tags.count > 1 {
                        OtherFacetsSection(tags: Array(vm.tags.dropFirst()), reduceMotion: reduceMotion)
                    }

                    // 3-B: 横スワイプ探索モード
                    Button {
                        Haptics.play(.medium)
                        if let top = effectiveTopTag,
                           let idx = Personality.allCases.firstIndex(of: top.personality) {
                            exploreStartIndex = idx
                        }
                        showExplore = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.3x2")
                                .font(.subheadline)
                            Text("12のパーソナリティをすべて探索")
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 14)
                        .appCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    PrecisionNoticeView()

                    Color.clear.frame(height: 32)
                }
                .padding(.top, 28)
                .background(Color(.systemBackground))
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var previewBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.caption2)
            Text("DEV PREVIEW: \(previewPersonalityRaw)")
                .font(.caption2.bold())
        }
        .foregroundStyle(.blue)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.blue.opacity(0.1))
        .overlay(
            Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
        .padding(.horizontal)
    }

    @MainActor
    private func sharePersonality(tag: PersonalityTag) {
        Haptics.play(.medium)
        let card = PersonalityShareCard(tag: tag)
        shareImage = ShareImageRenderer().render(card, size: CGSize(width: 600, height: 420))
        showShareSheet = shareImage != nil
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    let tag: PersonalityTag
    let reduceMotion: Bool
    let onShare: () -> Void

    @State private var gradientAnimate = false
    @State private var orbAnimate = false
    @State private var glowPulse = false
    @State private var appeared = false
    @State private var waveStart = Date()

    // デバイスごとの上端余白（ノッチ / Dynamic Island 対応）
    private var topInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top ?? 44
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            heroBackground

            VStack(spacing: 0) {
                // ナビゲーションバー分の余白
                Spacer().frame(height: topInset + 48)

                // グロー + アイコン
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tag.personality.gradient[0].opacity(0.55), .clear],
                                center: .center, startRadius: 0, endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 24)
                        .scaleEffect(glowPulse ? 1.15 : 0.88)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                            value: glowPulse
                        )

                    PersonalityIconSymbol(personality: tag.personality, size: 120)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 20)

                // パーソナリティ名
                Text(tag.personality.rawValue)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)

                // キャッチコピー
                Text(tag.personality.catchphrase)
                    .font(.title3)
                    .italic()
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                // 一言説明
                Text(tag.personality.personalityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 10)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)

                Spacer(minLength: 24)

                // シェアボタン
                Button(action: onShare) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("パーソナリティをシェア")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                }
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 36)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500 + max(0, topInset - 44))
        .onAppear {
            if !reduceMotion {
                gradientAnimate = true
                orbAnimate = true
                glowPulse = true
                waveStart = Date()
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var heroBackground: some View {
        ZStack {
            // ベースグラジェント（ゆっくり方向が変化）
            LinearGradient(
                colors: tag.personality.gradient + [.black.opacity(0.35)],
                startPoint: gradientAnimate ? .topLeading : .bottomTrailing,
                endPoint: gradientAnimate ? .bottomTrailing : .topLeading
            )
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 7).repeatForever(autoreverses: true),
                value: gradientAnimate
            )

            // 波形アニメーション（3-A）
            if !reduceMotion {
                let gradColors = tag.personality.gradient
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSince(waveStart)
                    Canvas { drawCtx, sz in
                        drawHeroWaveCanvas(&drawCtx, size: sz, t: t, colors: gradColors)
                    }
                }
                .blendMode(.screen)
            }

            // フローティング オーブ（拡散光）
            if !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.22), .clear],
                            center: .center, startRadius: 0, endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .offset(x: orbAnimate ? -70 : 70, y: orbAnimate ? -100 : 40)
                    .blur(radius: 28)
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: orbAnimate)
            }

            // 下部フェード（コンテンツ背景へのなじみ）
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: UnitPoint(x: 0.5, y: 0.72),
                endPoint: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Why Section

private struct WhySection: View {
    let personality: Personality
    let metrics: ListeningMetrics
    let reduceMotion: Bool

    private struct MetricDef {
        let icon: String
        let label: String
        let value: Double
        let color: Color
    }

    private var metricDefs: [MetricDef] {
        [
            MetricDef(icon: "person.fill",
                      label: "アーティスト集中度",
                      value: metrics.top1ArtistRatio,
                      color: personality.gradient.first ?? .pink),
            MetricDef(icon: "arrow.triangle.2.circlepath",
                      label: "お気に入り曲リピート率",
                      value: metrics.top10TrackRatio,
                      color: .orange),
            MetricDef(icon: "music.note.list",
                      label: "ジャンル集中度",
                      value: metrics.topGenreRatio,
                      color: .teal),
            MetricDef(icon: "opticaldisc",
                      label: "ローカル音源率",
                      value: metrics.localPlayRatio,
                      color: .blue)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "なぜこの人格？")

            VStack(spacing: 0) {
                // 数値バー × 4
                ForEach(Array(metricDefs.enumerated()), id: \.offset) { i, m in
                    MetricBarRow(icon: m.icon, label: m.label,
                                 value: m.value, color: m.color,
                                 delay: Double(i) * 0.08,
                                 reduceMotion: reduceMotion)
                    if i < metricDefs.count - 1 {
                        Divider().padding(.leading, 28).opacity(0.4)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 一言インサイト
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption2)
                    .foregroundStyle(personality.gradient.first ?? .pink)
                    .padding(.top, 2)
                Text(insightText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal)
    }

    private var insightText: String {
        let artist = metrics.top1ArtistName
        let genre  = metrics.topGenreName
        let total  = metrics.totalPlayCount
        switch personality {
        case .obsessedFan:
            return "再生の \(pct(metrics.top1ArtistRatio)) が \(artist) です。それが「推しが本気」の証明。"
        case .singleFocus:
            return "TOP10楽曲で全再生の \(pct(metrics.top10TrackRatio)) を占めています。一曲を深く掘り下げるスタイル。"
        case .heavyRotator:
            return "同じ曲を何度も聴き込む、熟練のリスニング。曲の奥深さを知っています。"
        case .genreAddict:
            return "\(genre) への集中度 \(pct(metrics.topGenreRatio))。そのジャンルがあなたの言語です。"
        case .collector:
            return "再生の \(pct(metrics.localPlayRatio)) がローカル音源。CDで音楽を「所有する」文化の体現者。"
        case .streamingFan:
            return "再生の \(pct(metrics.streamingPlayRatio)) がApple Music。デジタル音楽の最前線にいます。"
        case .legend:
            return "累計 \(total.formatted()) 回再生。積み上げてきた時間が、すべてを語ります。"
        case .balanced:
            return "\(metrics.uniqueArtistCount) 組のアーティスト、均等なジャンル分散。理想的な音楽バランスです。"
        case .loyalListener:
            return "TOP10アーティストで \(pct(metrics.top10ArtistRatio))。信頼のラインナップを持つリスナーです。"
        case .explorer:
            return "常に新しい音楽を探し求める、音楽探検家。その好奇心が音楽体験を広げています。"
        case .growingListener:
            return "日々アップデートされるライブラリ。音楽と共に、あなた自身も進化しています。"
        case .nostalgic:
            return "育ててきた名曲たちを、今日も大切に聴いています。そこには帰れる場所がある。"
        }
    }

    private func pct(_ v: Double) -> String { "\(Int(v * 100))%" }
}

// MARK: - Metric Bar Row

private struct MetricBarRow: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color
    let delay: Double
    let reduceMotion: Bool

    @State private var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .frame(width: 14)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [color, color.opacity(0.55)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onAppear {
            let target = min(max(value, 0), 1)
            if reduceMotion {
                progress = target
            } else {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.68).delay(delay)) {
                    progress = target
                }
            }
        }
    }
}

// MARK: - Other Facets Section

private struct OtherFacetsSection: View {
    let tags: [PersonalityTag]
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "あなたの他の面")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(tags.enumerated()), id: \.element.id) { i, tag in
                        OtherFacetCard(tag: tag, delay: Double(i) * 0.06, reduceMotion: reduceMotion)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct OtherFacetCard: View {
    let tag: PersonalityTag
    let delay: Double
    let reduceMotion: Bool

    @State private var appeared = false
    @State private var barProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PersonalityIconSymbol(personality: tag.personality, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(tag.personality.rawValue)
                            .font(.caption.bold())
                            .lineLimit(1)
                        if tag.precision == .estimated {
                            EstimatedBadge()
                        }
                    }
                    Text(tag.personality.catchphrase)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }

            Text(tag.reason)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(LinearGradient(
                            colors: tag.personality.gradient,
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * barProgress)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .frame(width: 230)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            if reduceMotion {
                appeared = true
                barProgress = min(tag.score, 1)
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(delay)) {
                    appeared = true
                }
                withAnimation(.spring(response: 0.7).delay(delay + 0.15)) {
                    barProgress = min(tag.score, 1)
                }
            }
        }
    }
}

// MARK: - Precision Notice

private struct PrecisionNoticeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("データ精度について")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text("「推定」マーク付きのタグは dateAdded を基に算出しています。Apple Musicの制約により正確な再生履歴は取得できないため、推定値として参考にしてください。利用継続で詳細分析の精度が向上します。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - 推定バッジ（module-level）

struct EstimatedBadge: View {
    var body: some View {
        Text("推定")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.2))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }
}

// MARK: - 空状態

private struct EmptyPersonalityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("データが不足しています")
                .font(.headline)
            Text("楽曲を再生するとリスニングパーソナリティが分析されます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - シェア用カード

private struct PersonalityShareCard: View {
    let tag: PersonalityTag

    var body: some View {
        ZStack {
            LinearGradient(
                colors: tag.personality.gradient + [.black.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 14) {
                PersonalityIconSymbol(personality: tag.personality, size: 110)

                Text(tag.personality.rawValue)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(tag.personality.catchphrase)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 0.5)
                    .padding(.horizontal, 48)

                Text(tag.personality.personalityDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                HStack(spacing: 5) {
                    Image("AppLogoImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 2)
                    Text("MusicLibrary")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 4)
            }
            .padding(44)
        }
    }
}

// MARK: - 3-B 横スワイプ探索モード

struct PersonalityExploreSheet: View {
    let userTags: [PersonalityTag]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var waveStart = Date()

    private let allPersonalities = Personality.allCases

    private func userScore(for p: Personality) -> Double? {
        userTags.first(where: { $0.personality == p })?.score
    }
    private var topPersonality: Personality? { userTags.first?.personality }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // グラデーション背景（ページに合わせて変化）
            let colors = allPersonalities[currentIndex].gradient
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentIndex)

            // 静止波形
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince(waveStart)
                Canvas { drawCtx, sz in
                    drawHeroWaveCanvas(&drawCtx, size: sz, t: t, colors: colors)
                }
            }
            .blendMode(.screen)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentIndex)

            // ダークオーバーレイ
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 0) {
                // 閉じるボタン
                HStack {
                    Button {
                        Haptics.play(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Spacer()
                    Text("\(currentIndex + 1) / \(allPersonalities.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, 56)
                .padding(.bottom, AppTheme.Spacing.sm)

                // スワイプカルーセル
                TabView(selection: $currentIndex) {
                    ForEach(Array(allPersonalities.enumerated()), id: \.element) { i, personality in
                        PersonalityExploreCard(
                            personality: personality,
                            userScore: userScore(for: personality),
                            isTop: personality == topPersonality
                        )
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear {
            currentIndex = startIndex
            waveStart = Date()
        }
    }
}

private struct PersonalityExploreCard: View {
    let personality: Personality
    let userScore: Double?
    let isTop: Bool

    @State private var appeared = false
    @State private var barProgress: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {

                // バッジ
                ZStack {
                    if isTop || userScore != nil {
                        Circle()
                            .fill(RadialGradient(
                                colors: [
                                    (personality.gradient.first ?? .pink).opacity(0.45),
                                    .clear
                                ],
                                center: .center, startRadius: 0, endRadius: 100
                            ))
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                    }
                    PersonalityIconSymbol(personality: personality, size: 140)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.65).delay(0.05), value: appeared)

                // あなたの人格バッジ
                if isTop {
                    Label("あなたの人格", systemImage: "star.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.22))
                        .clipShape(Capsule())
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                }

                // 名前
                Text(personality.rawValue)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: (personality.gradient.first ?? .pink).opacity(0.7), radius: 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.45).delay(0.15), value: appeared)

                // キャッチコピー
                Text(personality.catchphrase)
                    .font(.title3.italic())
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.22), value: appeared)

                // 説明
                Text(personality.personalityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.3), value: appeared)

                // スコアバー
                if let score = userScore {
                    VStack(spacing: 10) {
                        Text("あなたとの一致度")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.2))
                                Capsule()
                                    .fill(.white)
                                    .frame(width: geo.size.width * barProgress)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, AppTheme.Spacing.xl)

                        Text("\(Int(score * 100))%")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                } else {
                    Text("現在のあなたとは異なる傾向")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xl)
            .padding(.bottom, 60)
        }
        .onAppear {
            appeared = true
            if let score = userScore {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.45)) {
                    barProgress = min(score, 1)
                }
            }
        }
        .onDisappear {
            appeared = false
            barProgress = 0
        }
    }
}

// MARK: - Hero波形描画（3-A パーソナリティ画面背景を波形に）

private func drawHeroWaveCanvas(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    t: Double,
    colors: [Color]
) {
    let w = size.width
    let h = size.height
    let c1 = colors.first ?? .pink
    let c2 = colors.last ?? .purple

    let defs: [(freq: Double, amp: Double, spd: Double, yFrac: Double, usesC1: Bool, op: Double)] = [
        (0.010, h * 0.07, 0.60, 0.18, true,  0.20),
        (0.008, h * 0.09, 0.95, 0.35, false, 0.24),
        (0.013, h * 0.06, 0.80, 0.52, true,  0.17),
        (0.009, h * 0.08, 1.15, 0.68, false, 0.21),
    ]
    for wd in defs {
        let wc = wd.usesC1 ? c1 : c2
        var pts = [CGPoint]()
        var x: Double = 0
        while x <= w {
            let y = h * wd.yFrac
                + sin(x * wd.freq - t * wd.spd) * wd.amp
                + sin(x * wd.freq * 1.7 + t * wd.spd * 0.55) * wd.amp * 0.35
            pts.append(CGPoint(x: x, y: y))
            x += 4
        }
        guard pts.count >= 2 else { continue }
        var path = Path()
        path.move(to: pts[0])
        for j in 1..<pts.count - 1 {
            let m = CGPoint(x: (pts[j].x + pts[j+1].x) / 2,
                            y: (pts[j].y + pts[j+1].y) / 2)
            path.addQuadCurve(to: m, control: pts[j])
        }
        path.addLine(to: pts.last!)
        ctx.stroke(path, with: .color(wc.opacity(wd.op)), lineWidth: 1.8)
    }
}

// MARK: - UIActivityViewController ラッパー（module-level）

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
