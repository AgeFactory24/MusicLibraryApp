//
//  ReportStoryView.swift
//  MusicLibrary
//

import SwiftUI
import UIKit

struct StoryReportData {
    let title: String
    let totalPlayCount: Int
    let totalPlayTime: TimeInterval
    let topArtists: [Artist]
    let topTracks: [Track]
    let genreData: [GenreData]
    let topPeriodLabel: String
    let topPeriodPlayCount: Int
    let topPeriodTrack: Track?
    let topPeriodSubtitle: String
    let personality: ListenerPersonality

    var totalPlayTimeFormatted: String {
        let totalSeconds = max(0, Int(totalPlayTime))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else if minutes > 0 {
            return "\(minutes)分"
        } else {
            return "\(totalSeconds)秒"
        }
    }
}

extension MonthlyReport {
    func toStoryData() -> StoryReportData {
        StoryReportData(
            title: monthLabel,
            totalPlayCount: totalPlayCount,
            totalPlayTime: totalPlayTime,
            topArtists: topArtists,
            topTracks: topTracks,
            genreData: genreData,
            topPeriodLabel: topDay.map { "\($0.day)日" } ?? "—",
            topPeriodPlayCount: topDay?.playCount ?? 0,
            topPeriodTrack: topDay?.topTrack,
            topPeriodSubtitle: "最も聴いた日",
            personality: personality
        )
    }
}

extension YearlyReport {
    func toStoryData() -> StoryReportData {
        StoryReportData(
            title: yearLabel,
            totalPlayCount: totalPlayCount,
            totalPlayTime: totalPlayTime,
            topArtists: topArtists,
            topTracks: topTracks,
            genreData: genreData,
            topPeriodLabel: topMonth.map { "\($0.month)月" } ?? "—",
            topPeriodPlayCount: topMonth?.playCount ?? 0,
            topPeriodTrack: topMonth?.topTrack,
            topPeriodSubtitle: "最も聴いた月",
            personality: personality
        )
    }
}

// MARK: - ストーリー画面

struct ReportStoryView: View {
    let data: StoryReportData
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileService: UserProfileService

    @State private var currentPage: Int = 0
    @State private var progress: Double = 0
    @State private var autoAdvanceTimer: Timer?
    @State private var dragOffset: CGFloat = 0
    @State private var showShareSheet = false

    private let pageCount = 7
    private let pageDuration: TimeInterval = 10.0

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                pageContent(for: currentPage)
                    .id(currentPage)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            topOverlay

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goPrevious() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goNext() }
            }
            .ignoresSafeArea()

            if currentPage == pageCount - 1 {
                shareButtonOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .offset(y: dragOffset)
        .gesture(dismissGesture)
        .onAppear { startTimer() }
        .onDisappear {
            autoAdvanceTimer?.invalidate()
            autoAdvanceTimer = nil
        }
        .sheet(isPresented: $showShareSheet) {
            StoryShareSheet(data: data, profileService: profileService)
        }
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                    autoAdvanceTimer?.invalidate()
                }
            }
            .onEnded { value in
                if value.translation.height > 100 {
                    Haptics.play(.light)
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                    startTimer()
                }
            }
    }

    private var topOverlay: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<pageCount, id: \.self) { index in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.3))
                            Capsule()
                                .fill(.white)
                                .frame(width: capsuleWidth(index: index, total: geo.size.width))
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(.horizontal, 12)

            HStack {
                Spacer()
                ProfileBadge()
            }
            .padding(.horizontal, 12)
        }
        .padding(.top, 8)
    }

    private func capsuleWidth(index: Int, total: CGFloat) -> CGFloat {
        if index < currentPage { return total }
        if index == currentPage { return total * progress }
        return 0
    }

    private var shareButtonOverlay: some View {
        VStack {
            Spacer()
            Button {
                Haptics.play(.medium)
                showShareSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.headline)
                    Text("シェアカードを作成")
                        .font(.headline)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.white)
                .foregroundStyle(data.personality.gradient.first ?? .pink)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            }
            .padding(.bottom, 60)
        }
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private func pageContent(for index: Int) -> some View {
        switch index {
        case 0: IntroPage(data: data, displayName: profileService.displayName)
        case 1: TotalPlaysPage(data: data, displayName: profileService.displayName)
        case 2: GenrePage(data: data)
        case 3: TopArtistsPage(data: data)
        case 4: TopTracksPage(data: data)
        case 5: TopPeriodPage(data: data)
        case 6: PersonalityPage(data: data, displayName: profileService.displayName)
        default: IntroPage(data: data, displayName: profileService.displayName)
        }
    }

    private func goNext() {
        guard currentPage < pageCount - 1 else { return }
        Haptics.play(.light)
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPage += 1
        }
        resetTimer()
    }

    private func goPrevious() {
        guard currentPage > 0 else { return }
        Haptics.play(.light)
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPage -= 1
        }
        resetTimer()
    }

    private func startTimer() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
        progress = 0

        if currentPage == pageCount - 1 {
            return
        }

        let interval: TimeInterval = 0.05
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                progress += interval / pageDuration
                if progress >= 1.0 {
                    progress = 0
                    if currentPage < pageCount - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentPage += 1
                        }
                    } else {
                        autoAdvanceTimer?.invalidate()
                        autoAdvanceTimer = nil
                    }
                }
            }
        }
    }

    private func resetTimer() {
        progress = 0
        startTimer()
    }
}

// MARK: - プロフィールバッジ

private struct ProfileBadge: View {
    @EnvironmentObject var profileService: UserProfileService

    var body: some View {
        HStack(spacing: 8) {
            if let icon = profileService.iconImage {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1.5))
            } else {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
            }
            Text(profileService.displayName)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - グラデ背景

private struct StoryBackground: View {
    let colors: [Color]
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Pages

private struct IntroPage: View {
    let data: StoryReportData
    let displayName: String
    @State private var animate = false

    var body: some View {
        ZStack {
            StoryBackground(colors: [.purple, .pink])

            VStack(spacing: 24) {
                Spacer()

                Text(data.title)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)

                Text("MUSIC LIBRARY")
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(8)
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(animate ? 1 : 0)

                Text("\(displayName)のリスニングレポート")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animate ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animate = true
            }
        }
    }
}

private struct TotalPlaysPage: View {
    let data: StoryReportData
    let displayName: String
    @State private var animate = false
    @State private var counterStart: Date = .distantFuture

    private var contextText: String {
        let secs = Int(data.totalPlayTime)
        let h = secs / 3600
        let d = h / 24
        if d >= 1 {
            let rh = h - d * 24
            return rh > 0 ? "≈ \(d)日\(rh)時間分の音楽" : "≈ \(d)日分の音楽"
        } else if h >= 1 {
            let rm = (secs % 3600) / 60
            return rm > 0 ? "≈ \(h)時間\(rm)分の音楽" : "≈ \(h)時間分の音楽"
        } else {
            return "≈ \(max(1, secs / 60))分の音楽"
        }
    }

    var body: some View {
        ZStack {
            StoryBackground(colors: [.pink, .orange])

            VStack(spacing: 16) {
                Spacer()

                Text("\(displayName)は")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                VStack(spacing: 6) {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
                        let elapsed = max(0, ctx.date.timeIntervalSince(counterStart))
                        let progress = min(1.0, elapsed / 1.5)
                        let eased = 1.0 - pow(1.0 - progress, 3)
                        let count = Int(Double(data.totalPlayCount) * eased)
                        Text("\(count)")
                            .font(.system(size: 100, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }

                    Text(contextText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.55), value: animate)
                }
                .scaleEffect(animate ? 1 : 0.3)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animate)

                Text("回の再生をしました")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text(data.totalPlayTimeFormatted)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("音楽と共にした時間")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animate)

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            withAnimation { animate = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                counterStart = Date()
            }
        }
    }
}

private struct GenrePage: View {
    let data: StoryReportData
    @State private var animate = false

    var body: some View {
        ZStack {
            StoryBackground(colors: [.cyan, .blue])

            VStack(spacing: 16) {
                Spacer().frame(height: 100)

                Text("GENRE")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.7))
                Text("ジャンル別再生分布")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Spacer().frame(height: 16)

                if data.genreData.isEmpty {
                    Text("データなし")
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(data.genreData.prefix(7).enumerated()), id: \.offset) { index, genre in
                            GenreBar(
                                genre: genre,
                                maxCount: data.genreData.first?.playCount ?? 1,
                                index: index,
                                animate: animate
                            )
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer().frame(height: 60)
                }
            }
        }
        .onAppear { animate = true }
    }
}

private struct GenreBar: View {
    let genre: GenreData
    let maxCount: Int
    let index: Int
    let animate: Bool

    private var ratio: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(genre.playCount) / CGFloat(maxCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(genre.genre)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(genre.playCount)回")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule()
                        .fill(.white)
                        .frame(width: animate ? geo.size.width * ratio : 0)
                        .animation(
                            .easeOut(duration: 0.7).delay(Double(index) * 0.1),
                            value: animate
                        )
                }
            }
            .frame(height: 8)
        }
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: animate)
    }
}

// MARK: - TOP Artists（10件1画面に収まるよう縮小）

private struct TopArtistsPage: View {
    let data: StoryReportData
    @State private var animate = false

    var body: some View {
        ZStack {
            StoryBackground(colors: [.indigo, .purple])

            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 4) {
                    Text("TOP ARTISTS")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("最も聴いたアーティスト")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.top, 80)
                .padding(.bottom, 20)

                // ランキング10件（小さくして1画面に収める）
                VStack(spacing: 6) {
                    ForEach(Array(data.topArtists.prefix(10).enumerated()), id: \.element.id) { index, artist in
                        CompactArtistRow(rank: index + 1, artist: artist, animate: animate)
                    }
                }
                .padding(.horizontal, 16)

//                Spacer(minLength: 60)
            }
        }
        .onAppear { animate = true }
    }
}

private struct CompactArtistRow: View {
    let rank: Int
    let artist: Artist
    let animate: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(rank == 1 ? .yellow : .white)
                .frame(width: 36, alignment: .leading)

            ArtistArtworkView(artist: artist, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(artist.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(artist.totalPlayCount)回")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -50)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7).delay(Double(rank - 1) * 0.04),
            value: animate
        )
    }
}

// MARK: - TOP Tracks（10件1画面）

private struct TopTracksPage: View {
    let data: StoryReportData
    @State private var animate = false

    var body: some View {
        ZStack {
            StoryBackground(colors: [.teal, .cyan])

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("TOP TRACKS")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("最も聴いた楽曲")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.top, 80)
                .padding(.bottom, 20)

                VStack(spacing: 6) {
                    ForEach(Array(data.topTracks.prefix(10).enumerated()), id: \.element.id) { index, track in
                        CompactTrackRow(rank: index + 1, track: track, animate: animate)
                    }
                }
                .padding(.horizontal, 16)

//                Spacer(minLength: 60)
            }
        }
        .onAppear { animate = true }
    }
}

private struct CompactTrackRow: View {
    let rank: Int
    let track: Track
    let animate: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(rank == 1 ? .yellow : .white)
                .frame(width: 30, alignment: .leading)

            TrackArtworkView(track: track, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            Text("\(track.playCount)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -50)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7).delay(Double(rank - 1) * 0.04),
            value: animate
        )
    }
}

private struct TopPeriodPage: View {
    let data: StoryReportData
    @State private var animate = false

    var body: some View {
        ZStack {
            StoryBackground(colors: [.green, .teal])

            VStack(spacing: 24) {
                Spacer()

                Text(data.topPeriodSubtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))

                Text(data.topPeriodLabel)
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.5)

                Text("\(data.topPeriodPlayCount)回再生")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer().frame(height: 20)

                if let topTrack = data.topPeriodTrack {
                    VStack(spacing: 8) {
                        Text("ヘビロテ")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))

                        HStack(spacing: 12) {
                            TrackArtworkView(track: topTrack, size: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topTrack.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(topTrack.artistName)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(14)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .opacity(animate ? 1 : 0)
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animate = true
            }
        }
    }
}

private struct PersonalityPage: View {
    let data: StoryReportData
    let displayName: String
    @State private var animate = false
    @State private var waveStart = Date()

    var body: some View {
        ZStack {
            // Animated wave background
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince(waveStart)
                Canvas { drawCtx, sz in
                    drawPersonalityWaveBackground(
                        &drawCtx, size: sz, t: t,
                        colors: data.personality.gradient
                    )
                }
            }
            .ignoresSafeArea()

            // Darkening overlay for text legibility
            LinearGradient(
                colors: [.black.opacity(0.28), .clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("\(displayName)は")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)
                    .padding(.bottom, 20)

                // Badge with expanding glow rings
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: data.personality.gradient.map {
                                        $0.opacity(max(0, 0.42 - Double(i) * 0.12))
                                    },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: max(0.5, 1.8 - Double(i) * 0.5)
                            )
                            .frame(
                                width: 186 + CGFloat(i * 44),
                                height: 186 + CGFloat(i * 44)
                            )
                            .scaleEffect(animate ? 1.0 : 0.3)
                            .opacity(animate ? 1 : 0)
                            .animation(
                                .spring(response: 1.0, dampingFraction: 0.5)
                                    .delay(0.18 + Double(i) * 0.12),
                                value: animate
                            )
                    }

                    if let p = Personality.allCases.first(where: {
                        $0.rawValue == data.personality.title
                    }) {
                        PersonalityIconSymbol(personality: p, size: 160)
                            .shadow(
                                color: (data.personality.gradient.first ?? .pink).opacity(0.8),
                                radius: 28
                            )
                    } else {
                        Text(data.personality.emoji)
                            .font(.system(size: 120))
                    }
                }
                .scaleEffect(animate ? 1.0 : 0.15)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.85, dampingFraction: 0.5).delay(0.15), value: animate)
                .padding(.bottom, 28)

                // Title with neon glow
                Text(data.personality.title)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(
                        color: (data.personality.gradient.first ?? .pink).opacity(0.9),
                        radius: 22
                    )
                    .shadow(
                        color: (data.personality.gradient.first ?? .pink).opacity(0.5),
                        radius: 44
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.35), value: animate)
                    .padding(.bottom, 14)

                Text(data.personality.description)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animate)
                    .padding(.bottom, 20)

                Text("あなたの音楽の旅が、この人格を生んだ")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: animate)

                Spacer().frame(height: 180)
            }
        }
        .onAppear {
            waveStart = Date()
            animate = true
        }
    }
}

// MARK: - Wave background (4-D 覚醒ページ)

private func drawPersonalityWaveBackground(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    t: Double,
    colors: [Color]
) {
    let w = size.width
    let h = size.height
    let c1 = colors.first ?? .pink
    let c2 = colors.last ?? .purple

    ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
            Gradient(colors: [c1, c2]),
            startPoint: .zero,
            endPoint: CGPoint(x: w, y: h)
        )
    )

    ctx.blendMode = .screen
    let defs: [(freq: Double, amp: Double, spd: Double, yFrac: Double, c1: Bool, op: Double)] = [
        (0.013, h * 0.09, 0.75, 0.20, true,  0.22),
        (0.009, h * 0.11, 1.10, 0.36, false, 0.26),
        (0.016, h * 0.07, 0.90, 0.52, true,  0.18),
        (0.011, h * 0.10, 1.28, 0.67, false, 0.22),
        (0.014, h * 0.08, 0.65, 0.82, true,  0.20),
    ]
    for wd in defs {
        let wc = wd.c1 ? c1 : c2
        var pts = [CGPoint]()
        var x: Double = 0
        while x <= w {
            let y = h * wd.yFrac
                + sin(x * wd.freq - t * wd.spd) * wd.amp
                + sin(x * wd.freq * 1.73 + t * wd.spd * 0.55) * wd.amp * 0.38
            pts.append(CGPoint(x: x, y: y))
            x += 3
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
        ctx.stroke(path, with: .color(wc.opacity(wd.op)), lineWidth: 2.0)
    }
    ctx.blendMode = .normal
}
