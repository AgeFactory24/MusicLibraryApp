//
//  QRCompatibilityView.swift
//  MusicLibrary
//

import SwiftUI
import VisionKit
import Vision
import AVFoundation
import PhotosUI

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
    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false

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
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            processPhotoForQR(newItem)
        }
        .overlay {
            if isProcessingPhoto {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("QRを検出中...")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
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

            VStack(spacing: 12) {
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

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("アルバムから選択", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
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

    private func processPhotoForQR(_ item: PhotosPickerItem) {
        isProcessingPhoto = true
        photoItem = nil
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                scanError = "画像を読み込めませんでした"
                isProcessingPhoto = false
                return
            }
            let payload = await Task.detached(priority: .userInitiated) {
                Self.detectQRCode(in: image)
            }.value
            isProcessingPhoto = false
            if let payload {
                handleScanned(payload: payload)
            } else {
                scanError = "QRコードが見つかりませんでした。シェア画像の右下のQRが写っているか確認してください"
            }
        }
    }

    static func detectQRCode(in image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return (request.results as? [VNBarcodeObservation])?
            .first { $0.symbology == .qr }?
            .payloadStringValue
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
        let tracks = libraryVM.tracks
        guard !tracks.isEmpty else { return nil }

        // statsVM / rankingVM が未ロードでも tracks から直接計算してフォールバック
        let metrics = PersonalityAnalysisEngine.buildMetrics(from: tracks)
        let totalPlayCount = statsVM.stats?.totalPlayCount ?? metrics.totalPlayCount
        let cdRatio = statsVM.stats?.localPlayRatio ?? metrics.localPlayRatio

        let personalityType = rankingVM.homePersonalityTag?.personality.rawValue
            ?? PersonalityAnalysisEngine.evaluate(metrics: metrics, topCount: 1)
                .first?.personality.rawValue ?? "バランス派"

        let artists: [String] = rankingVM.homeTopArtists.isEmpty
            ? Array(libraryVM.artists
                .sorted { $0.totalPlayCount > $1.totalPlayCount }
                .prefix(5)
                .map(\.name))
            : Array(rankingVM.homeTopArtists.prefix(5).map(\.name))

        let genres = genreVM.genreData.prefix(5).map { g -> ProfileGenre in
            let ratio = genreVM.totalPlayCount > 0
                ? Double(g.playCount) / Double(genreVM.totalPlayCount) : 0
            return ProfileGenre(name: g.genre, ratio: ratio)
        }

        return ListeningProfile(
            version: 1,
            displayName: profileService.displayName,
            personalityType: personalityType,
            topArtistNames: artists,
            topGenres: Array(genres),
            cdRatio: cdRatio,
            totalPlayCount: totalPlayCount,
            generatedAt: Date()
        )
    }
}

// MARK: - QRスキャナーシート

struct QRScannerSheet: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var photoError: String?

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
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("アルバム", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isProcessingPhoto)
                }
            }
            .overlay {
                if isProcessingPhoto {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("QRを検出中...")
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                isProcessingPhoto = true
                photoItem = nil
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        photoError = "画像を読み込めませんでした"
                        isProcessingPhoto = false
                        return
                    }
                    let payload = await Task.detached(priority: .userInitiated) {
                        QRCompatibilityView.detectQRCode(in: image)
                    }.value
                    isProcessingPhoto = false
                    if let payload {
                        dismiss()
                        onScan(payload)
                    } else {
                        photoError = "QRコードが見つかりませんでした"
                    }
                }
            }
            .alert("読み取りエラー", isPresented: Binding(
                get: { photoError != nil },
                set: { if !$0 { photoError = nil } }
            )) {
                Button("OK") { photoError = nil }
            } message: {
                Text(photoError ?? "")
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
    @EnvironmentObject var libraryVM: LibraryViewModel

    @State private var displayedScore: Int = 0
    @State private var barProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            personalityHeader
                .padding()
                .onAppear {
                    startScoreAnimation()
                    withAnimation(.easeOut(duration: 1.4)) {
                        barProgress = 1.0
                    }
                }

            Divider()

            detailRows
                .padding()

            if !result.commonArtists.isEmpty {
                Divider()
                commonArtistsSection
                    .padding()
            }

            if !result.reason.isEmpty {
                Divider()
                Text(result.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - ヘッダー（パーソナリティ画像 + スコア）

    private var personalityHeader: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 0) {
                profileColumn(profile: result.myProfile)
                scoreColumn
                profileColumn(profile: result.partnerProfile)
            }

            Text(result.level.label)
                .font(.headline.bold())
                .foregroundStyle(result.level.color)
        }
    }

    private func profileColumn(profile: ListeningProfile) -> some View {
        VStack(spacing: 6) {
            personalityIcon(for: profile.personalityType, size: 72)
            Text(profile.displayName)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(profile.personalityType)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var scoreColumn: some View {
        VStack(spacing: 2) {
            Text("\(displayedScore)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(result.level.color)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(displayedScore)))
            Text("/ 100")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80)
    }

    private func startScoreAnimation() {
        let target = result.score
        Task { @MainActor in
            let duration = 1.4
            let startTime = Date()
            while true {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / duration, 1.0)
                let eased = 1.0 - pow(1.0 - progress, 3.0)
                displayedScore = Int(Double(target) * eased)
                if progress >= 1.0 {
                    displayedScore = target
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    @ViewBuilder
    private func personalityIcon(for type: String, size: CGFloat) -> some View {
        if let p = Personality(rawValue: type) {
            PersonalityIconSymbol(personality: p, size: size)
        } else {
            Circle()
                .fill(LinearGradient(
                    colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
        }
    }

    // MARK: - スコアバー

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
                        .frame(width: max(geo.size.width * score * barProgress, 0))
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - 共通アーティスト

    private func artist(named name: String) -> Artist {
        libraryVM.artists.first(where: { $0.name == name })
            ?? Artist(id: name, name: name, artworkURL: nil, tracks: [])
    }

    private var commonArtistsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("共通アーティスト")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(result.commonArtists, id: \.self) { name in
                        VStack(spacing: 6) {
                            ArtistArtworkView(artist: artist(named: name), size: 52)
                            Text(name)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
