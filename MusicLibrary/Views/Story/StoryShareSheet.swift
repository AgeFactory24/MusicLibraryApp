//
//  StoryShareSheet.swift
//  MusicLibrary
//

import SwiftUI
import UIKit

struct StoryShareSheet: View {
    let data: StoryReportData
    let profileService: UserProfileService

    @Environment(\.dismiss) var dismiss
    @State private var instagramImage: UIImage?
    @State private var twitterImage: UIImage?
    @State private var isGenerating = true
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isGenerating {
                    ProgressView("カードを生成中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Instagram プレビュー
                            sharePreviewSection(
                                title: "Instagram Story",
                                size: "1080 × 1920",
                                image: instagramImage,
                                aspectRatio: 1080.0 / 1920.0,
                                destination: .instagram
                            )

                            // X プレビュー
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
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task { await generateImages() }
        }
    }

    // MARK: - プレビューセクション

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
                    .frame(maxHeight: aspectRatio > 1 ? 200 : 400)
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

        // Instagram (1080x1920)
        let igCard = ShareCardContent(
            data: data,
            displayName: profileService.displayName,
            iconImage: profileService.iconImage,
            isVertical: true
        )
        let renderer = ShareImageRenderer()
        instagramImage = renderer.render(
            igCard.frame(width: 1080, height: 1920),
            size: CGSize(width: 1080, height: 1920)
        )

        // Twitter (1200x630)
        let twCard = ShareCardContent(
            data: data,
            displayName: profileService.displayName,
            iconImage: profileService.iconImage,
            isVertical: false
        )
        twitterImage = renderer.render(
            twCard.frame(width: 1200, height: 630),
            size: CGSize(width: 1200, height: 630)
        )

        isGenerating = false
        Haptics.play(.success)
    }

    // MARK: - シェア

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
            // X はShareSheet経由
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = scene.windows.first?.rootViewController else {
                return
            }
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

// MARK: - 共通シェアカードコンテンツ

struct ShareCardContent: View {
    let data: StoryReportData
    let displayName: String
    let iconImage: UIImage?
    let isVertical: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: data.personality.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if isVertical {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
    }

    // MARK: - 縦長（Instagram）

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 28) {
            // ユーザー情報
            HStack(spacing: 14) {
                if let icon = iconImage {
                    Image(uiImage: icon)
                        .resizable().scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                } else {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Text("MUSIC LIBRARY")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }

            // 期間
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("リスニングレポート")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // 大きな数字
            VStack(alignment: .leading, spacing: 0) {
                Text("\(data.totalPlayCount)")
                    .font(.system(size: 130, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                HStack {
                    Text("回再生")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Text(data.totalPlayTimeFormatted)
                        .font(.system(size: 24, weight: .bold))
                }
                .foregroundStyle(.white)
            }

            Divider().background(.white.opacity(0.4))

            // パーソナリティ
            HStack(spacing: 16) {
                Text(data.personality.emoji)
                    .font(.system(size: 60))
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOU ARE")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(data.personality.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            // TOP3 アーティスト
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP ARTISTS")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.7))
                ForEach(Array(data.topArtists.prefix(3).enumerated()), id: \.element.id) { index, artist in
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 40, alignment: .leading)
                        Text(artist.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(artist.totalPlayCount)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }

            // TOP3 楽曲
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP TRACKS")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.7))
                ForEach(Array(data.topTracks.prefix(3).enumerated()), id: \.element.id) { index, track in
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 36, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(track.artistName)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(track.playCount)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }

            Spacer()

            HStack {
                Image(systemName: "music.note")
                Text("MusicLibrary")
                    .font(.system(size: 16, weight: .heavy))
                Spacer()
                Text("#MusicLibrary")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(60)
    }

    // MARK: - 横長（Twitter）

    private var horizontalLayout: some View {
        HStack(spacing: 32) {
            // 左：ユーザー情報＋数字
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if let icon = iconImage {
                        Image(uiImage: icon)
                            .resizable().scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    } else {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("MUSIC LIBRARY")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Text(data.title)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(data.totalPlayCount)回再生")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(data.totalPlayTimeFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                HStack(spacing: 12) {
                    Text(data.personality.emoji)
                        .font(.system(size: 36))
                    VStack(alignment: .leading) {
                        Text("YOU ARE")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(data.personality.title)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }

            Divider().background(.white.opacity(0.3))

            // 右：TOP3アーティスト＆楽曲
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOP ARTISTS")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))
                    ForEach(Array(data.topArtists.prefix(3).enumerated()), id: \.element.id) { index, artist in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, alignment: .leading)
                            Text(artist.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer()
                            Text("\(artist.totalPlayCount)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("TOP TRACKS")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))
                    ForEach(Array(data.topTracks.prefix(3).enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, alignment: .leading)
                            Text(track.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer()
                            Text("\(track.playCount)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(40)
    }
}
