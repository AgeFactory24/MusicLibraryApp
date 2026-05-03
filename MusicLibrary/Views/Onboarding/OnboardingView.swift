//
//  OnboardingView.swift
//  MusicLibrary
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var authService: MusicAuthService
    @State private var currentPage = 0
    @State private var animateGradient = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "opticaldisc",
            title: "CD取り込み音源も\n分析できます",
            subtitle: "Apple Music の Replay では\n反映されないCD音源も含めて、\nあなたの全リスニングを記録します",
            colors: [.blue, .purple],
            secondaryIcons: ["music.note", "music.note.list", "headphones"]
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "月別・時間帯別で\n振り返ろう",
            subtitle: "いつ、どんな音楽を聴いたか。\n月別レポートや時間帯分析で\nあなたの音楽習慣が見えてきます",
            colors: [.pink, .orange],
            secondaryIcons: ["calendar", "clock.fill", "chart.line.uptrend.xyaxis"]
        ),
        OnboardingPage(
            icon: "square.and.arrow.up.fill",
            title: "シェアカードで\nSNSに共有",
            subtitle: "Wrapped風のストーリーカードを\nワンタップで生成。\nInstagramやXに即シェア🎵",
            colors: [.purple, .pink],
            secondaryIcons: ["sparkles", "heart.fill", "star.fill"]
        )
    ]

    var body: some View {
        ZStack {
            // 動的な背景グラデーション（ページに応じて色変化）
            LinearGradient(
                colors: pages[currentPage].colors,
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            // 装飾用の浮遊アイコン
            FloatingIconsLayer(
                icons: pages[currentPage].secondaryIcons,
                pageID: currentPage
            )

            VStack(spacing: 0) {
                // スキップボタン
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            Haptics.play(.light)
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        } label: {
                            Text("スキップ")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            page: page,
                            isLast: index == pages.count - 1,
                            isCurrent: currentPage == index,
                            onAuthorize: {
                                Task {
                                    Haptics.play(.medium)
                                    await authService.requestAuthorization()
                                    if authService.isAuthorized {
                                        Haptics.play(.success)
                                        withAnimation {
                                            hasCompletedOnboarding = true
                                        }
                                    }
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    Haptics.play(.light)
                }

                // ページインジケータ
                pageIndicator
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            animateGradient = true
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? .white : .white.opacity(0.3))
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - ページモデル

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]
    let secondaryIcons: [String]
}

// MARK: - 1ページView

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLast: Bool
    let isCurrent: Bool
    let onAuthorize: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -30
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // メインアイコン（アニメーション付き）
            ZStack {
                // 背景円（パルスアニメーション）
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 200 + CGFloat(i * 40), height: 200 + CGFloat(i * 40))
                        .scaleEffect(isCurrent ? 1 : 0.8)
                        .opacity(isCurrent ? 1 : 0)
                        .animation(
                            .easeOut(duration: 1.0).delay(Double(i) * 0.1),
                            value: isCurrent
                        )
                }

                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(.white)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .shadow(color: .white.opacity(0.5), radius: 20)
            }

            // テキスト
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(contentOpacity)
            }

            Spacer()

            // 最終ページのみ認証ボタン
            if isLast {
                Button {
                    onAuthorize()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.headline.bold())
                        Text("Apple Musicを連携する")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundStyle(page.colors.first ?? .pink)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                .opacity(contentOpacity)
            } else {
                Color.clear.frame(height: 60)
            }
        }
        .onAppear {
            if isCurrent { animateIn() }
        }
        .onChange(of: isCurrent) { _, newValue in
            if newValue { animateIn() }
        }
    }

    private func animateIn() {
        iconScale = 0.5
        iconRotation = -30
        contentOpacity = 0

        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1
            iconRotation = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            contentOpacity = 1
        }
    }
}

// MARK: - 浮遊する装飾アイコン

private struct FloatingIconsLayer: View {
    let icons: [String]
    let pageID: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    FloatingIcon(
                        symbol: icons[index],
                        size: geo.size,
                        seed: index + pageID * 7
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct FloatingIcon: View {
    let symbol: String
    let size: CGSize
    let seed: Int

    @State private var animate = false

    private var startX: CGFloat {
        CGFloat((seed * 73) % 100) / 100 * size.width
    }
    private var startY: CGFloat {
        CGFloat((seed * 41 + 30) % 100) / 100 * size.height
    }
    private var deltaY: CGFloat { CGFloat(((seed * 17) % 40) - 20) }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 40))
            .foregroundStyle(.white.opacity(0.18))
            .position(x: startX, y: startY + (animate ? deltaY : -deltaY))
            .blur(radius: 0.5)
            .animation(
                .easeInOut(duration: Double(3 + seed % 3))
                    .repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { animate = true }
    }
}
