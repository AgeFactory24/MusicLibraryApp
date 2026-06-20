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

// MARK: - 相性結果カード（5-A + 5-B）

struct CompatibilityResultCard: View {
    let result: CompatibilityResult
    @EnvironmentObject var libraryVM: LibraryViewModel

    @State private var barProgress: Double = 0

    private var myColor: Color {
        Personality(rawValue: result.myProfile.personalityType)?.gradient.first ?? .pink
    }
    private var partnerColor: Color {
        Personality(rawValue: result.partnerProfile.personalityType)?.gradient.first ?? .purple
    }

    var body: some View {
        VStack(spacing: 0) {
            compatibilityHeader
                .padding()
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4)) { barProgress = 1.0 }
                }

            Divider()
            detailRows.padding()

            if !result.commonArtists.isEmpty {
                Divider()
                commonArtistsSection.padding()
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

    // MARK: - 5-A + 5-B ヘッダー

    private var compatibilityHeader: some View {
        VStack(spacing: 16) {
            // 5-A: 引き合う / 反発するバッジアニメーション
            BadgeAttractionView(
                myPersonality:      result.myProfile.personalityType,
                partnerPersonality: result.partnerProfile.personalityType,
                myName:             result.myProfile.displayName,
                partnerName:        result.partnerProfile.displayName,
                score:              result.score
            )

            // 5-B: 数値スコアの代わりに波形の重なりで相性を表現
            WaveOverlapView(
                score:        Double(result.score) / 100.0,
                myColor:      myColor,
                partnerColor: partnerColor
            )

            Text(result.level.label)
                .font(.headline.bold())
                .foregroundStyle(result.level.color)
        }
    }

    // MARK: - スコアバー（詳細）

    private var detailRows: some View {
        VStack(spacing: 10) {
            scoreRow(label: "共通アーティスト", score: result.artistScore, icon: "music.mic",         weight: "40%")
            scoreRow(label: "パーソナリティ",   score: result.personalityScore, icon: "person.crop.circle", weight: "20%")
            scoreRow(label: "ジャンル傾向",     score: result.genreScore,        icon: "music.note.list",   weight: "20%")
            scoreRow(label: "音源へのこだわり", score: result.trendScore,        icon: "opticaldisc",       weight: "20%")
        }
    }

    private func scoreRow(label: String, score: Double, icon: String, weight: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(weight).font(.caption2).foregroundStyle(.secondary)
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
                            Text(name).font(.caption2).lineLimit(1).frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - 5-A: バッジ引き合い / 反発アニメーション

private struct BadgeAttractionView: View {
    let myPersonality:      String
    let partnerPersonality: String
    let myName:             String
    let partnerName:        String
    let score:              Int

    @State private var arrived     = false
    @State private var pulsing     = false   // 高相性：同期パルス
    @State private var repelDist: CGFloat = 0 // 低相性：反発量

    private var isHighCompat: Bool { score >= 60 }
    private var myColor:      Color { Personality(rawValue: myPersonality)?.gradient.first      ?? .pink   }
    private var partnerColor: Color { Personality(rawValue: partnerPersonality)?.gradient.first ?? .purple }

    var body: some View {
        ZStack {
            // 高相性：中央グロー
            if isHighCompat {
                Circle()
                    .fill(RadialGradient(
                        colors: [.white.opacity(0.55), .clear],
                        center: .center, startRadius: 0, endRadius: 26
                    ))
                    .frame(width: 52, height: 52)
                    .blur(radius: 11)
                    .scaleEffect(pulsing ? 1.55 : 0.55)
                    .opacity(arrived ? 1 : 0)
                    .animation(
                        arrived ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true) : .default,
                        value: pulsing
                    )
            }

            HStack(spacing: 20) {
                // 自分バッジ（左から登場）
                VStack(spacing: 5) {
                    badgeIcon(for: myPersonality, size: 76)
                        .shadow(color: myColor.opacity(pulsing && isHighCompat ? 0.75 : 0.20), radius: 18)
                        .scaleEffect(isHighCompat && pulsing ? 1.08 : 1.0)
                        .animation(
                            arrived && isHighCompat
                                ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                                : .default,
                            value: pulsing
                        )
                    Text(myName).font(.caption.bold()).foregroundStyle(.primary).lineLimit(1)
                    Text(myPersonality).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                // 登場オフセット（到着 or 画面外）
                .offset(x: arrived ? 0 : -115)
                .animation(.spring(response: 0.85, dampingFraction: 0.65).delay(0.15), value: arrived)
                // 低相性：左へ反発
                .offset(x: -repelDist)

                // 相手バッジ（右から登場）
                VStack(spacing: 5) {
                    badgeIcon(for: partnerPersonality, size: 76)
                        .shadow(color: partnerColor.opacity(pulsing && isHighCompat ? 0.75 : 0.20), radius: 18)
                        .scaleEffect(isHighCompat && pulsing ? 1.08 : 1.0)
                        .animation(
                            arrived && isHighCompat
                                ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                                : .default,
                            value: pulsing
                        )
                    Text(partnerName).font(.caption.bold()).foregroundStyle(.primary).lineLimit(1)
                    Text(partnerPersonality).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .offset(x: arrived ? 0 : 115)
                .animation(.spring(response: 0.85, dampingFraction: 0.65).delay(0.15), value: arrived)
                // 低相性：右へ反発
                .offset(x: repelDist)
            }
        }
        .frame(height: 130)
        .clipped()
        .onAppear {
            // Step 1: 両バッジが中央へ引き合う
            withAnimation(.spring(response: 0.85, dampingFraction: 0.65).delay(0.15)) {
                arrived = true
            }
            // Step 2: 相性によって演出を分岐
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                if isHighCompat {
                    // 高相性: 同期パルス
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                } else {
                    // 低相性: 反発オシレーション
                    withAnimation(.easeInOut(duration: 0.80).repeatForever(autoreverses: true)) {
                        repelDist = 10
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func badgeIcon(for type: String, size: CGFloat) -> some View {
        if let p = Personality(rawValue: type) {
            PersonalityIconSymbol(personality: p, size: size)
        } else {
            Circle()
                .fill(LinearGradient(
                    colors: [.pink.opacity(0.4), .purple.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - 5-B: 波形の重なりで相性を表現

private struct WaveOverlapView: View {
    let score:        Double   // 0..1
    let myColor:      Color
    let partnerColor: Color

    @State private var startDate = Date()
    @State private var appeared  = false

    var body: some View {
        VStack(spacing: 6) {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSince(startDate)
                Canvas { ctx, size in
                    guard appeared else { return }

                    let w   = size.width
                    let h   = size.height
                    let cy  = h / 2
                    let amp = h * 0.30
                    // 高スコア → 位相差小 → 波形が重なる
                    let phaseDiff = (1.0 - score) * .pi * 1.5

                    // 波形ポイントを事前計算
                    var myPts:  [(Double, Double)] = []
                    var prtPts: [(Double, Double)] = []
                    var x = 0.0
                    while x <= w + 4 {
                        myPts.append((x, cy + amp * sin(x * 0.046 - t * 1.7)))
                        prtPts.append((x, cy + amp * sin(x * 0.046 - t * 1.7 + phaseDiff)))
                        x += 4
                    }

                    // 重なり部分グロー（スクリーン合成）
                    ctx.blendMode = .screen
                    for i in 0..<myPts.count {
                        let (px, myY)  = myPts[i]
                        let (_, prtY)  = prtPts[i]
                        let proximity  = max(0.0, 1.0 - abs(myY - prtY) / (amp * 1.6))
                        let op         = proximity * 0.82 * score
                        guard op > 0.04 else { continue }
                        let gy = (myY + prtY) / 2
                        var g  = Path()
                        g.addEllipse(in: CGRect(x: px - 5, y: gy - 5, width: 10, height: 10))
                        ctx.fill(g, with: .color(Color.white.opacity(op)))
                    }
                    ctx.blendMode = .normal

                    // 自分の波形
                    var myPath = Path()
                    for (i, (px, py)) in myPts.enumerated() {
                        if i == 0 { myPath.move(to: CGPoint(x: px, y: py)) }
                        else       { myPath.addLine(to: CGPoint(x: px, y: py)) }
                    }
                    ctx.stroke(myPath, with: .color(myColor.opacity(0.85)), lineWidth: 1.5)

                    // 相手の波形
                    var prtPath = Path()
                    for (i, (px, py)) in prtPts.enumerated() {
                        if i == 0 { prtPath.move(to: CGPoint(x: px, y: py)) }
                        else       { prtPath.addLine(to: CGPoint(x: px, y: py)) }
                    }
                    ctx.stroke(prtPath, with: .color(partnerColor.opacity(0.85)), lineWidth: 1.5)
                }
            }
            .frame(height: 68)
            .background(Color(.systemBackground).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(appeared ? 1 : 0)

            // 凡例 + スコア数値
            HStack {
                Circle().fill(myColor).frame(width: 6, height: 6)
                Text("あなた").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(score * 100))pt")
                    .font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("相手").font(.caption2).foregroundStyle(.secondary)
                Circle().fill(partnerColor).frame(width: 6, height: 6)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.9)) { appeared = true }
        }
    }
}
