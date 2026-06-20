//
//  StoryShareSheet.swift
//  MusicLibrary
//

import SwiftUI
import UIKit

struct StoryShareSheet: View {
    let data: StoryReportData
    let profileService: UserProfileService

    @EnvironmentObject var artworkService: ArtworkService

    @Environment(\.dismiss) var dismiss
    @State private var instagramImage: UIImage?
    @State private var twitterImage: UIImage?
    @State private var isGenerating = false
    @State private var statusMessage: String?
    @State private var showPrivacyAlert = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isGenerating {
                    ProgressView("カードを生成中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            sharePreviewSection(
                                title: "Instagram Story",
                                size: "1080 × 1920",
                                image: instagramImage,
                                aspectRatio: 1080.0 / 1920.0,
                                destination: .instagram
                            )

                            sharePreviewSection(
                                title: "X (Twitter)",
                                size: "1200 × 630",
                                image: twitterImage,
                                aspectRatio: 1200.0 / 630.0,
                                destination: .twitter
                            )
                        }
                        .padding()
                    }
                }

                if let message = statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle("シェアカード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { /* 画像生成はプライバシー確認後 */ }
            .alert("プロフィール情報の共有", isPresented: $showPrivacyAlert) {
                Button("確認して続ける") {
                    Task { await generateImages() }
                }
                Button("キャンセル", role: .cancel) { dismiss() }
            } message: {
                Text("シェア画像の右下に音楽プロフィールがQRコードとして埋め込まれます。\n\n含まれる情報：\n・パーソナリティ\n・TOPアーティスト\n・ジャンル傾向\n・音源比率\n\n再生履歴・楽曲履歴は含まれません。")
            }
        }
    }

    @ViewBuilder
    private func sharePreviewSection(
        title: String,
        size: String,
        image: UIImage?,
        aspectRatio: CGFloat,
        destination: ShareDestination
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: destination.icon)
                    .foregroundStyle(.pink)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(size)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .frame(maxHeight: aspectRatio > 1 ? 200 : 500)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await share(image: image, to: destination) }
                } label: {
                    Label("シェア", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task { await save(image: image) }
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 画像生成

    @MainActor
    private func generateImages() async {
        isGenerating = true

        // 1. パーソナリティアイコンを静止UIImageとして事前レンダリング
        let personalityIconImage = renderPersonalityIcon()

        // 2. アーティスト画像を事前ロード（TOP5）
        var artistImages: [UIImage?] = []
        for artist in data.topArtists.prefix(10) {
            let img = await artworkService.loadArtistImage(artistName: artist.name)
            artistImages.append(img)
        }

        // 3. 楽曲アートワークを事前ロード（TOP5）
        let trackImages: [UIImage?] = data.topTracks.prefix(10).map { track in
            guard let pid = UInt64(track.id) else { return nil }
            return artworkService.fetchTrackArtwork(persistentID: pid)
        }

        let renderer = ShareImageRenderer()
        let profile = data.toListeningProfile(displayName: profileService.displayName)
        let qrString = QRCodeService.encode(profile)
        let qrImage: UIImage? = qrString.flatMap { QRCodeService.generateQRImage(from: $0, size: 300) }

        // Instagram縦長
        let igCard = ShareCardContent(
            data: data,
            displayName: profileService.displayName,
            iconImage: profileService.iconImage,
            personalityIconImage: personalityIconImage,
            artistImages: artistImages,
            trackImages: trackImages,
            isVertical: true
        )
        var igBase = renderer.render(
            igCard.frame(width: 1080, height: 1920),
            size: CGSize(width: 1080, height: 1920)
        )
        if let base = igBase, let qr = qrImage {
            igBase = QRCodeService.compositeQR(onto: base, qrImage: qr)
        }
        instagramImage = igBase

        // Twitter横長
        let twCard = ShareCardContent(
            data: data,
            displayName: profileService.displayName,
            iconImage: profileService.iconImage,
            personalityIconImage: personalityIconImage,
            artistImages: artistImages,
            trackImages: trackImages,
            isVertical: false
        )
        var twBase = renderer.render(
            twCard.frame(width: 1200, height: 630),
            size: CGSize(width: 1200, height: 630)
        )
        if let base = twBase, let qr = qrImage {
            twBase = QRCodeService.compositeQR(onto: base, qrImage: qr, marginRatio: 0.025)
        }
        twitterImage = twBase

        isGenerating = false
        Haptics.play(.success)
    }

    @MainActor
    private func renderPersonalityIcon() -> UIImage? {
        guard let p = Personality.allCases.first(where: {
            $0.rawValue == data.personality.title
        }) else { return nil }
        let size: CGFloat = 300
        let view = PersonalityIconSymbol(personality: p, size: size)
            .frame(width: size, height: size)
        let ir = ImageRenderer(content: view)
        ir.scale = 2.0
        return ir.uiImage
    }

    private func share(image: UIImage?, to destination: ShareDestination) async {
        guard let image else { return }
        switch destination {
        case .instagram:
            let success = await SocialShareService.shareToInstagramStory(image: image)
            if !success {
                Haptics.play(.error)
                statusMessage = "Instagramを開けませんでした"
            } else {
                Haptics.play(.success)
            }
        case .twitter:
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = scene.windows.first?.rootViewController else { return }
            let topVC = rootVC.presentedViewController ?? rootVC
            SocialShareService.presentShareSheet(image: image, from: topVC)
            Haptics.play(.success)
        }
    }

    private func save(image: UIImage?) async {
        guard let image else { return }
        let saved = await SocialShareService.saveToPhotos(image: image)
        if saved {
            Haptics.play(.success)
            statusMessage = "写真ライブラリに保存しました"
        } else {
            Haptics.play(.error)
            statusMessage = "保存に失敗しました"
        }
    }
}

// MARK: - シェアカード本体

struct ShareCardContent: View {
    let data: StoryReportData
    let displayName: String
    let iconImage: UIImage?
    let personalityIconImage: UIImage?   // 事前レンダリング済みパーソナリティアイコン
    let artistImages: [UIImage?]         // TOP5 アーティスト画像
    let trackImages: [UIImage?]          // TOP5 楽曲アートワーク
    let isVertical: Bool

    var body: some View {
        ZStack {
            // ベースグラデーション
            LinearGradient(
                colors: data.personality.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 静止波形
            Canvas { ctx, sz in
                drawShareWaves(&ctx, size: sz, colors: data.personality.gradient)
            }
            .blendMode(.screen)

            // ダークオーバーレイ（文字可読性向上）
            LinearGradient(
                colors: [.black.opacity(0.52), .black.opacity(0.30), .black.opacity(0.60)],
                startPoint: .top,
                endPoint: .bottom
            )

            if isVertical {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
    }

    // MARK: - 縦長（Instagram 1080×1920）

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── ヘッダー ──
            HStack(spacing: 18) {
                userAvatar(size: 88)
                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("MUSIC LIBRARY")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }

            Spacer().frame(height: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(data.title)
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("リスニングレポート")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer().frame(height: 32)

            // ── 統計 ──
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(data.totalPlayCount)")
                    .font(.system(size: 118, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("回再生")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.8))
                Text(data.totalPlayTimeFormatted)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer().frame(height: 36)

            // ── YOU ARE ──
            HStack(spacing: 22) {
                personalityBadge(size: 116)

                VStack(alignment: .leading, spacing: 7) {
                    Text("YOU ARE")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.60))
                    Text(data.personality.title)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    Text(data.personality.description)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Spacer().frame(height: 20)

            // ── ランキング（2列）──
            HStack(alignment: .top, spacing: 24) {
                // TOP ARTISTS
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("TOP ARTISTS")
                    ForEach(Array(data.topArtists.prefix(10).enumerated()), id: \.element.id) { i, artist in
                        artistRow(index: i, name: artist.name, plays: artist.totalPlayCount,
                                  image: i < artistImages.count ? artistImages[i] : nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // TOP TRACKS
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("TOP TRACKS")
                    ForEach(Array(data.topTracks.prefix(10).enumerated()), id: \.element.id) { i, track in
                        trackRow(index: i, title: track.title, artist: track.artistName,
                                 plays: track.playCount,
                                 image: i < trackImages.count ? trackImages[i] : nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            // ── フッター ──
            HStack {
                Image("AppLogoImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text("MusicLibrary")
                    .font(.system(size: 24, weight: .heavy))
                Spacer()
                Text("#MusicLibrary")
                    .font(.system(size: 20, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 80)
    }

    // MARK: - 横長（Twitter 1200×630）

    private var horizontalLayout: some View {
        HStack(spacing: 0) {
            // 左：ユーザー情報 + 統計 + YOU ARE
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    userAvatar(size: 48)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("MUSIC LIBRARY")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Text(data.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(data.totalPlayCount)回再生")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(data.totalPlayTimeFormatted)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                HStack(spacing: 10) {
                    personalityBadge(size: 44)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("YOU ARE")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(data.personality.title)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(width: 260)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            // 仕切り
            Rectangle().fill(.white.opacity(0.20)).frame(width: 1)

            // 中央：TOP ARTISTS
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("TOP ARTISTS", size: 11)
                ForEach(Array(data.topArtists.prefix(10).enumerated()), id: \.element.id) { i, artist in
                    artistRow(index: i, name: artist.name, plays: artist.totalPlayCount,
                              image: i < artistImages.count ? artistImages[i] : nil,
                              artSize: 40, nameSize: 16, playsSize: 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)

            // 仕切り
            Rectangle().fill(.white.opacity(0.20)).frame(width: 1)

            // 右：TOP TRACKS
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("TOP TRACKS", size: 11)
                ForEach(Array(data.topTracks.prefix(10).enumerated()), id: \.element.id) { i, track in
                    trackRow(index: i, title: track.title, artist: track.artistName,
                             plays: track.playCount,
                             image: i < trackImages.count ? trackImages[i] : nil,
                             artSize: 40, titleSize: 15, artistSize: 12, playsSize: 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    // MARK: - パーツ

    @ViewBuilder
    private func userAvatar(size: CGFloat) -> some View {
        if let icon = iconImage {
            Image(uiImage: icon)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: max(2, size * 0.04)))
        } else {
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.44))
                        .foregroundStyle(.white)
                }
        }
    }

    @ViewBuilder
    private func personalityBadge(size: CGFloat) -> some View {
        if let img = personalityIconImage {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient(
                    colors: data.personality.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .overlay {
                    Text(data.personality.emoji)
                        .font(.system(size: size * 0.48))
                }
        }
    }

    private func sectionLabel(_ title: String, size: CGFloat = 22) -> some View {
        Text(title)
            .font(.system(size: size, weight: .heavy))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.65))
    }

    private func artistRow(
        index: Int, name: String, plays: Int, image: UIImage?,
        artSize: CGFloat = 68, nameSize: CGFloat = 30, playsSize: CGFloat = 23
    ) -> some View {
        HStack(spacing: 10) {
            if let img = image {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: artSize, height: artSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: artSize, height: artSize)
                    .overlay {
                        Text("\(index + 1)")
                            .font(.system(size: artSize * 0.4, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: nameSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(plays)回")
                    .font(.system(size: playsSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer(minLength: 0)
        }
    }

    private func trackRow(
        index: Int, title: String, artist: String, plays: Int, image: UIImage?,
        artSize: CGFloat = 68, titleSize: CGFloat = 28, artistSize: CGFloat = 20, playsSize: CGFloat = 23
    ) -> some View {
        HStack(spacing: 10) {
            if let img = image {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: artSize, height: artSize)
                    .clipShape(RoundedRectangle(cornerRadius: artSize * 0.18))
            } else {
                RoundedRectangle(cornerRadius: artSize * 0.18)
                    .fill(.white.opacity(0.15))
                    .frame(width: artSize, height: artSize)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: artSize * 0.38))
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(artist)
                    .font(.system(size: artistSize))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("\(plays)")
                .font(.system(size: playsSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - 静止波形描画（シェアカード用）

private func drawShareWaves(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    colors: [Color]
) {
    let w = size.width
    let h = size.height
    let c1 = colors.first ?? .pink
    let c2 = colors.last ?? .purple
    let t = 1.5 // 固定時刻（静止スナップショット）

    let defs: [(freq: Double, amp: Double, spd: Double, yFrac: Double, usesC1: Bool, op: Double)] = [
        (0.013, h * 0.09, 0.75, 0.18, true,  0.22),
        (0.009, h * 0.11, 1.10, 0.34, false, 0.26),
        (0.016, h * 0.07, 0.90, 0.50, true,  0.18),
        (0.011, h * 0.10, 1.28, 0.65, false, 0.22),
        (0.014, h * 0.08, 0.65, 0.80, true,  0.19),
    ]
    for wd in defs {
        let wc = wd.usesC1 ? c1 : c2
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
        ctx.stroke(path, with: .color(wc.opacity(wd.op)), lineWidth: 2.5)
    }
}
