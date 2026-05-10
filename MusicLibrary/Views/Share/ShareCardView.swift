//
//  ShareCardView.swift
//  MusicLibrary
//

import SwiftUI

/// シェア用カードのプレビュー＆書き出し画面
struct ShareCardView: View {
    let report: MonthlyReport
    @Environment(\.dismiss) var dismiss
    @State private var renderedImage: UIImage?
    @State private var selectedTheme: CardTheme = .gradient

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // プレビュー
                ScrollView {
                    cardPreview
                        .padding()
                }

                // テーマ選択
                themePicker

                // シェアボタン
                if let image = renderedImage {
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(
                            "\(report.monthLabel)のリスニングレポート",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Label("画像をシェア", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }
                } else {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("レポートをシェア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear { generateImage() }
            .onChange(of: selectedTheme) { _, _ in generateImage() }
        }
    }

    private var cardPreview: some View {
        ShareCard(report: report, theme: selectedTheme)
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CardTheme.allCases, id: \.self) { theme in
                    Button {
                        selectedTheme = theme
                    } label: {
                        Circle()
                            .fill(theme.previewGradient)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedTheme == theme {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 3)
                                        .padding(2)
                                }
                            }
                            .shadow(radius: selectedTheme == theme ? 4 : 0)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func generateImage() {
        let renderer = ShareImageRenderer()
        Task { @MainActor in
            renderedImage = renderer.render(
                ShareCard(report: report, theme: selectedTheme)
                    .frame(width: 1080, height: 1920),
                size: CGSize(width: 1080, height: 1920)
            )
        }
    }
}

// MARK: - シェアカード本体

struct ShareCard: View {
    let report: MonthlyReport
    let theme: CardTheme
    var isPreview: Bool = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 6) {
                    Text("MUSIC LIBRARY")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(theme.accentColor)
                    Text(report.monthLabel)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(theme.textColor)
                    Text("のリスニングレポート")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.textColor.opacity(0.8))
                }

                Spacer().frame(height: 4)

                // 大きな数字
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(report.totalPlayCount)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundStyle(theme.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    HStack {
                        Text("回再生")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(theme.textColor)
                        Spacer()
                        Text(report.totalPlayTimeFormatted)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(theme.textColor)
                    }
                }

                Divider().background(theme.textColor.opacity(0.3))

                // TOP楽曲
                VStack(alignment: .leading, spacing: 12) {
                    Text("TOP TRACKS")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(3)
                        .foregroundStyle(theme.accentColor)

                    ForEach(Array(report.topTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 14) {
                            Text("\(index + 1)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(theme.accentColor)
                                .frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(theme.textColor)
                                    .lineLimit(1)
                                Text(track.artistName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.textColor.opacity(0.7))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("\(track.playCount)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(theme.accentColor)
                        }
                    }
                }

                Spacer()

                // フッター
                HStack {
                    Image("AppLogoImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    Text("MusicLibrary")
                        .font(.system(size: 16, weight: .heavy))
                    Spacer()
                    Text("#MusicLibrary")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(theme.textColor.opacity(0.6))
            }
            .padding(40)
        }
        .frame(width: 1080, height: 1920)
        .scaleEffect(isPreview ? 1.0 : 0.35)
        .frame(width: 1080 * 0.35, height: 1920 * 0.35)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - テーマ

enum CardTheme: String, CaseIterable {
    case gradient
    case dark
    case light
    case sunset
    case midnight

    var background: AnyView {
        switch self {
        case .gradient:
            return AnyView(LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .dark:
            return AnyView(Color.black)
        case .light:
            return AnyView(Color(.systemBackground))
        case .sunset:
            return AnyView(LinearGradient(
                colors: [.orange, .pink, .purple],
                startPoint: .top,
                endPoint: .bottom
            ))
        case .midnight:
            return AnyView(LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.05, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
    }

    var previewGradient: LinearGradient {
        switch self {
        case .gradient:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [.black, .black], startPoint: .top, endPoint: .bottom)
        case .light:
            return LinearGradient(colors: [.white, Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
        case .sunset:
            return LinearGradient(colors: [.orange, .purple], startPoint: .top, endPoint: .bottom)
        case .midnight:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.05, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var textColor: Color {
        switch self {
        case .light: return .black
        default: return .white
        }
    }

    var accentColor: Color {
        switch self {
        case .light: return .pink
        case .dark: return .pink
        case .gradient: return .yellow
        case .sunset: return .yellow
        case .midnight: return .pink
        }
    }
}
