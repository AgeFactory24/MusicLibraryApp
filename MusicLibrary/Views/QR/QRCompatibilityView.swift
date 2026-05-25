//
//  QRCompatibilityView.swift
//  MusicLibrary
//

import SwiftUI
import VisionKit
import Vision
import AVFoundation

// MARK: - エントリービュー（More画面から起動）

struct QRCompatibilityView: View {
    @EnvironmentObject var statsVM: StatisticsViewModel
    @EnvironmentObject var rankingVM: RankingViewModel
    @EnvironmentObject var profileService: UserProfileService
    @EnvironmentObject var libraryVM: LibraryViewModel

    @StateObject private var genreVM = GenreAnalysisViewModel()

    @State private var showScanner = false
    @State private var scanError: String?
    @State private var compatibilityResult: CompatibilityResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let result = compatibilityResult {
                    CompatibilityResultCard(result: result)
                    Button {
                        compatibilityResult = nil
                    } label: {
                        Label("もう一度スキャン", systemImage: "qrcode.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }
                } else {
                    scanPromptSection
                }
            }
            .padding(.vertical, 32)
        }
        .navigationTitle("音楽相性チェック")
        .onAppear { genreVM.build(from: libraryVM.tracks) }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerSheet { payload in
                showScanner = false
                handleScanned(payload: payload)
            }
        }
        .alert("スキャンエラー", isPresented: Binding(
            get: { scanError != nil },
            set: { if !$0 { scanError = nil } }
        )) {
            Button("OK") { scanError = nil }
        } message: {
            Text(scanError ?? "")
        }
    }

    private var scanPromptSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.pink)

            VStack(spacing: 8) {
                Text("友達の音楽QRをスキャン")
                    .font(.title3.bold())
                Text("月別・年間レポートのシェア画像に\n埋め込まれたQRコードを読み取ります")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                requestCameraAndScan()
            } label: {
                Label("QRコードをスキャン", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            howItWorksSection
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使い方")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(spacing: 14) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(.pink)
                            .clipShape(Circle())
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    if idx < steps.count - 1 { Divider().padding(.leading, 52) }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private let steps = [
        "友達に月別・年間レポートをシェアしてもらう",
        "シェア画像の右下にあるQRをスキャン",
        "音楽の相性スコアを確認しよう"
    ]

    private func requestCameraAndScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showScanner = true }
                    else { scanError = "カメラへのアクセスを許可してください" }
                }
            }
        default:
            scanError = "設定アプリからカメラへのアクセスを許可してください"
        }
    }

    private func handleScanned(payload: String) {
        guard let partner = QRCodeService.decode(payload) else {
            scanError = "QRコードを読み取れませんでした。MusicLibraryのシェア画像のQRか確認してください"
            return
        }
        guard let myProfile = buildMyProfile() else {
            scanError = "プロフィールデータが準備できていません。しばらくしてから再試行してください"
            return
        }
        compatibilityResult = CompatibilityEngine.calculate(me: myProfile, partner: partner)
    }

    private func buildMyProfile() -> ListeningProfile? {
        guard let stats = statsVM.stats,
              let tag = rankingVM.homePersonalityTag else { return nil }
        let artists = rankingVM.homeTopArtists.prefix(5).map(\.name)
        let genres = genreVM.genreData.prefix(5).map { g -> ProfileGenre in
            let ratio = genreVM.totalPlayCount > 0
                ? Double(g.playCount) / Double(genreVM.totalPlayCount) : 0
            return ProfileGenre(name: g.genre, ratio: ratio)
        }
        return ListeningProfile(
            version: 1,
            displayName: profileService.displayName,
            personalityType: tag.personality.rawValue,
            topArtistNames: Array(artists),
            topGenres: Array(genres),
            cdRatio: stats.localPlayRatio,
            totalPlayCount: stats.totalPlayCount,
            generatedAt: Date()
        )
    }
}

// MARK: - QRスキャナーシート

struct QRScannerSheet: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    QRDataScannerView(onScan: onScan)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "スキャン非対応",
                        systemImage: "camera.fill",
                        description: Text("このデバイスではQRスキャンに対応していません")
                    )
                }
            }
            .navigationTitle("QRをスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DataScannerViewController Wrapper

struct QRDataScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        // startScanning は viewDidAppear 相当のタイミングで実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? vc.startScanning()
        }
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        // startScanning は makeUIViewController で一度だけ呼ぶため、ここでは何もしない
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var scanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard !scanned, case .barcode(let code) = item,
                  let payload = code.payloadStringValue else { return }
            scanned = true
            Haptics.play(.success)
            onScan(payload)
        }
    }
}

// MARK: - 相性結果カード

struct CompatibilityResultCard: View {
    let result: CompatibilityResult

    var body: some View {
        VStack(spacing: 20) {
            scoreHeader
            Divider()
            detailRows
            if !result.commonArtists.isEmpty {
                commonArtistsSection
            }
            reasonSection
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(result.myProfile.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.pink)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(result.level.emoji)
                        .font(.system(size: 36))
                    Text("\(result.score)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(result.level.color)
                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(result.partnerProfile.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.purple)
                }
            }

            Text(result.level.label)
                .font(.title3.bold())
                .foregroundStyle(result.level.color)
        }
    }

    private var detailRows: some View {
        VStack(spacing: 10) {
            scoreRow(label: "共通アーティスト", score: result.artistScore, icon: "music.mic", weight: "40%")
            scoreRow(label: "パーソナリティ", score: result.personalityScore, icon: "person.crop.circle", weight: "20%")
            scoreRow(label: "ジャンル傾向", score: result.genreScore, icon: "music.note.list", weight: "20%")
            scoreRow(label: "音源へのこだわり", score: result.trendScore, icon: "opticaldisc", weight: "20%")
        }
    }

    private func scoreRow(label: String, score: Double, icon: String, weight: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(weight)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(score * 100))pt")
                    .font(.caption.bold())
                    .foregroundStyle(.pink)
                    .frame(width: 38, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(Color.pink.gradient)
                        .frame(width: max(geo.size.width * score, 4))
                }
            }
            .frame(height: 5)
        }
    }

    private var commonArtistsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("共通アーティスト", systemImage: "star.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(result.commonArtists, id: \.self) { name in
                        Text(name)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.pink.opacity(0.15))
                            .foregroundStyle(.pink)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var reasonSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(.pink.opacity(0.6))
            Text(result.reason)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.pink.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
