// DeveloperModeView.swift
// MusicLibrary — 内部確認用。本番ユーザー向けではありません。

import SwiftUI
import CoreData
import Combine

struct DeveloperModeView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var vm = DeveloperModeViewModel()
    @State private var selectedForInjection: Personality? = nil
    @State private var showInjectConfirm = false
    @State private var showResetConfirm = false
    @State private var showTestResetConfirm = false
    @State private var showAllDiffs = false
    @AppStorage("DEV.PreviewPersonality") private var previewPersonalityRaw: String = ""

    var body: some View {
        List {
            accuracySection
            syncSection
            syncLogSection
            coreDataSection
            incrementalDiffSection
            personalityPreviewSection
            personalityTestDataSection
            personalityDebugSection
            featureFlagSection
            dataOperationsSection
        }
        .navigationTitle("開発者モード")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load(tracks: libraryVM.tracks) }
        // テストデータ注入 確認
        .confirmationDialog(
            "テストデータ注入",
            isPresented: $showInjectConfirm,
            titleVisibility: .visible
        ) {
            if let p = selectedForInjection {
                Button("「\(p.rawValue)」データを注入") {
                    Task { await vm.injectTestData(for: p) }
                }
            }
            Button("キャンセル", role: .cancel) { selectedForInjection = nil }
        } message: {
            if let p = selectedForInjection {
                Text("「\(p.rawValue)」向けのテストデータ（過去6ヶ月分）を注入します。既存テストデータは削除されます。注入後に月別・年別レポートを開き直すと反映されます。")
            }
        }
        // テストデータリセット 確認
        .alert("テストデータをリセット", isPresented: $showTestResetConfirm) {
            Button("リセット", role: .destructive) { Task { await vm.resetTestData() } }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("注入したテストデータのみを削除します。実際の再生履歴は削除されません。")
        }
        // 全履歴リセット 確認
        .alert("全履歴をリセット", isPresented: $showResetConfirm) {
            Button("リセット", role: .destructive) { Task { await vm.resetHistory() } }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("PlayHistoryEntity と PlayCountSnapshotEntity が全削除され、差分カウントがゼロになります。")
        }
    }

    // MARK: - 1. 履歴精度レベル

    private var accuracySection: some View {
        Section("履歴精度レベル") {
            let level = vm.accuracyLevel
            HStack {
                Circle()
                    .fill(level.color)
                    .frame(width: 12, height: 12)
                Text(level.label)
                    .font(.headline)
                Spacer()
                Text("差分同期 \(vm.diffSyncCount) 回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(level.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 2. Sync 状態

    private var syncSection: some View {
        Section("Sync 状態") {
            DevRow(label: "初回スナップショット済み", value: vm.hasInitialSnapshot ? "✅ 済み" : "❌ 未")
            DevRow(label: "差分同期回数", value: "\(vm.diffSyncCount) 回")
            DevRow(label: "最終同期日時", value: vm.lastSyncDate)
            DevRow(label: "最終同期対象曲数", value: vm.lastSyncSongCount > 0 ? "\(vm.lastSyncSongCount) 曲" : "—")
            DevRow(label: "最終同期 新規履歴", value: vm.lastSyncNewHistory > 0 ? "+\(vm.lastSyncNewHistory) 件" : "—")
        }
    }

    // MARK: - 3. 同期ログ

    private var syncLogSection: some View {
        Section {
            if vm.syncLog.isEmpty {
                Text("同期ログなし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.syncLog) { entry in
                    SyncLogRow(entry: entry)
                }
                Button(role: .destructive) {
                    vm.clearSyncLog()
                } label: {
                    Label("ログをクリア", systemImage: "trash")
                        .font(.caption)
                }
            }
        } header: {
            HStack {
                Text("同期ログ（\(vm.syncLog.count) 件）")
                Spacer()
                Text("最大100件保持")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 4. Core Data 件数

    private var coreDataSection: some View {
        Section("Core Data 件数") {
            DevRow(label: "PlayHistoryEntity", value: "\(vm.historyCount) 件")
            DevRow(label: "PlayCountSnapshotEntity", value: "\(vm.snapshotCount) 件")
            DevRow(label: "DailyPlayAggregateEntity", value: "対象外")
            if vm.testDataCount > 0 {
                DevRow(label: "うちテストデータ", value: "\(vm.testDataCount) 件")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - 4. 増分検知された曲一覧（before / after / delta）

    private var incrementalDiffSection: some View {
        Section {
            if vm.allDiffs.isEmpty {
                Text("増分データなし（スナップショット取得前、または差分なし）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let displayed = showAllDiffs ? vm.allDiffs : Array(vm.allDiffs.prefix(10))
                ForEach(displayed) { diff in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(diff.title)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Spacer()
                            Text("+\(diff.delta)")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        HStack {
                            Text(diff.artist)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("前: \(diff.before) → 後: \(diff.after)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 2)
                }
                if vm.allDiffs.count > 10 {
                    Button {
                        showAllDiffs.toggle()
                    } label: {
                        Text(showAllDiffs ? "折りたたむ" : "全 \(vm.allDiffs.count) 件を表示")
                            .font(.caption)
                    }
                }
            }
        } header: {
            Text("増分検知された曲（\(vm.allDiffs.count) 件）")
        }
    }

    // MARK: - 5. Personality Preview

    private var personalityPreviewSection: some View {
        Section {
            if previewPersonalityRaw.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("バッジをタップしてパーソナリティ画面の演出をプレビュー")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("プレビュー中")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text("\(previewPersonalityRaw) の演出を表示中")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("クリア") {
                        previewPersonalityRaw = ""
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(Personality.allCases, id: \.rawValue) { p in
                    personalityPreviewCell(p)
                }
            }
            .padding(.vertical, 8)

        } header: {
            Text("Personality Preview")
        } footer: {
            Text("パーソナリティ画面でHero / カラー / アニメーション / キャッチコピーを即時確認できます。実データ・テストデータには影響しません。")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private func personalityPreviewCell(_ p: Personality) -> some View {
        let isActive = previewPersonalityRaw == p.rawValue
        Button {
            previewPersonalityRaw = isActive ? "" : p.rawValue
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    PersonalityIconSymbol(personality: p, size: 52)
                    if isActive {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 14))
                            .background(Circle().fill(Color(.systemBackground)).padding(-1))
                            .offset(x: 4, y: -4)
                    }
                }
                Text(p.rawValue)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isActive ? Color.blue : Color.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 6. パーソナリティ テストデータ

    private var personalityTestDataSection: some View {
        Section {
            // ステータス行
            if vm.isInjecting {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("テストデータ注入中…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if vm.testDataCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("テストデータ注入済み")
                            .font(.caption.bold())
                        Text("\(vm.testDataPersonalityLabel) · \(vm.testDataCount) 件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("月別・年別レポートを開き直すと反映されます")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    Spacer()
                    Button(role: .destructive) {
                        showTestResetConfirm = true
                    } label: {
                        Label("リセット", systemImage: "trash")
                            .font(.caption.bold())
                            .labelStyle(.iconOnly)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("バッジをタップしてそのパーソナリティ向けテストデータを注入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // パーソナリティ グリッド
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(Personality.allCases, id: \.rawValue) { p in
                    personalityCell(p)
                }
            }
            .padding(.vertical, 8)

        } header: {
            Text("パーソナリティ テストデータ")
        }
    }

    @ViewBuilder
    private func personalityCell(_ p: Personality) -> some View {
        let isActive = vm.testDataPersonalityLabel == p.rawValue
        Button {
            selectedForInjection = p
            showInjectConfirm = true
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    PersonalityIconSymbol(personality: p, size: 52)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 14))
                            .background(Circle().fill(Color(.systemBackground)).padding(-1))
                            .offset(x: 4, y: -4)
                    }
                }
                Text(p.rawValue)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isActive ? Color.green : Color.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(.plain)
        .opacity(vm.isInjecting ? 0.4 : 1.0)
        .disabled(vm.isInjecting)
    }

    // MARK: - 7. パーソナリティ条件デバッグ

    private var personalityDebugSection: some View {
        Section("パーソナリティ条件デバッグ") {
            if let metrics = vm.metrics {
                Group {
                    DevRow(label: "総再生数", value: "\(metrics.totalPlayCount)")
                    DevRow(label: "TOP1アーティスト集中度", value: percent(metrics.top1ArtistRatio))
                    DevRow(label: "TOP10アーティスト集中度", value: percent(metrics.top10ArtistRatio))
                    DevRow(label: "TOP1楽曲集中度", value: percent(metrics.top1TrackRatio))
                    DevRow(label: "TOP10楽曲集中度", value: percent(metrics.top10TrackRatio))
                }
                Group {
                    DevRow(label: "ユニークアーティスト", value: "\(metrics.uniqueArtistCount) 組")
                    DevRow(label: "ジャンル集中度", value: percent(metrics.topGenreRatio))
                    DevRow(label: "ローカル音源率", value: percent(metrics.localPlayRatio))
                    if let r = metrics.recentTrackRatio {
                        DevRow(label: "直近90日追加率（推定）", value: percent(r))
                    }
                    if let o = metrics.oldTrackRatio {
                        DevRow(label: "1年以上前追加率（推定）", value: percent(o))
                    }
                }
            } else {
                Text("楽曲データなし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !vm.personalityTags.isEmpty {
                ForEach(vm.personalityTags) { tag in
                    HStack(alignment: .top, spacing: 8) {
                        Text(tag.personality.icon)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(tag.personality.rawValue).font(.caption.bold())
                                Text(String(format: "%.2f", tag.score))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.blue)
                                if tag.precision == .estimated {
                                    Text("推定").font(.caption2).foregroundStyle(.orange)
                                }
                            }
                            Text(tag.reason).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 8. Feature Flag

    private var featureFlagSection: some View {
        Section("Feature Flag") {
            Toggle("初回スナップショット済み（強制上書き）", isOn: Binding(
                get: { vm.hasInitialSnapshot },
                set: { vm.setHasInitialSnapshot($0) }
            ))
            .font(.caption)
        }
    }

    // MARK: - 9. データ操作

    private var dataOperationsSection: some View {
        Section("データ操作") {
            if vm.testDataCount > 0 {
                Button(role: .destructive) {
                    showTestResetConfirm = true
                } label: {
                    Label("テストデータのみリセット", systemImage: "delete.backward")
                        .font(.subheadline)
                }
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("全履歴・スナップショットをリセット", systemImage: "trash")
                    .font(.subheadline)
            }
        }
    }

    private func percent(_ ratio: Double) -> String {
        "\(Int(ratio * 100))%"
    }
}

// MARK: - SyncLogRow

private struct SyncLogRow: View {
    let entry: SyncLogEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            Text(entry.trigger.icon)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.trigger.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(triggerColor)
                    Text(Self.timeFormatter.string(from: entry.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                HStack(spacing: 8) {
                    Label("\(entry.tracksScanned)曲スキャン", systemImage: "music.note.list")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if entry.newHistoryCount > 0 {
                        Label("+\(entry.newHistoryCount)件", systemImage: "plus.circle.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("差分なし")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.2fs", entry.durationSeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var triggerColor: Color {
        switch entry.trigger {
        case .initial:    return .purple
        case .foreground: return .blue
        case .background: return .orange
        case .widget:     return .teal
        case .manual:     return .gray
        }
    }
}

// MARK: - DevRow

private struct DevRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - PlayCountDiff モデル

struct PlayCountDiffEntry: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let before: Int32
    let after: Int32
    var delta: Int32 { after - before }
}

// MARK: - ViewModel

@MainActor
final class DeveloperModeViewModel: ObservableObject {
    @Published var historyCount: Int = 0
    @Published var snapshotCount: Int = 0
    @Published var testDataCount: Int = 0
    @Published var testDataPersonalityLabel: String = ""
    @Published var allDiffs: [PlayCountDiffEntry] = []
    @Published var metrics: ListeningMetrics? = nil
    @Published var personalityTags: [PersonalityTag] = []
    @Published var accuracyLevel: HistoryAccuracyLevel = .baseline
    @Published var diffSyncCount: Int = 0
    @Published var hasInitialSnapshot: Bool = false
    @Published var lastSyncDate: String = "—"
    @Published var lastSyncSongCount: Int = 0
    @Published var lastSyncNewHistory: Int = 0
    @Published var isInjecting: Bool = false
    @Published var syncLog: [SyncLogEntry] = []

    private let context = PersistenceController.shared.container.viewContext

    func load(tracks: [Track]) {
        diffSyncCount = UserDefaults.standard.integer(forKey: "MusicLibrary.DiffSyncCount")
        hasInitialSnapshot = UserDefaults.standard.bool(forKey: "MusicLibrary.HasInitialSnapshot")
        accuracyLevel = HistoryAccuracyLevel.level(for: diffSyncCount)

        let histReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
        historyCount = (try? context.count(for: histReq)) ?? 0

        let snapReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayCountSnapshotEntity")
        snapshotCount = (try? context.count(for: snapReq)) ?? 0

        loadTestDataInfo()
        loadAllDiffs(tracks: tracks)

        if !tracks.isEmpty {
            metrics = PersonalityAnalysisEngine.buildMetrics(from: tracks)
            if let m = metrics {
                personalityTags = PersonalityAnalysisEngine.evaluate(metrics: m)
            }
        }

        // 最終同期日時
        let ts = UserDefaults.standard.double(forKey: PlayHistoryTracker.lastSyncDateKey)
        if ts > 0 {
            let date = Date(timeIntervalSince1970: ts)
            let fmt = DateFormatter()
            fmt.dateStyle = .short
            fmt.timeStyle = .medium
            lastSyncDate = fmt.string(from: date)
        } else {
            lastSyncDate = "未記録"
        }
        lastSyncSongCount = UserDefaults.standard.integer(forKey: PlayHistoryTracker.lastSyncSongCountKey)
        lastSyncNewHistory = UserDefaults.standard.integer(forKey: PlayHistoryTracker.lastSyncNewHistoryKey)
        syncLog = SyncLogStore.load()
    }

    func clearSyncLog() {
        SyncLogStore.clear()
        syncLog = []
    }

    func setHasInitialSnapshot(_ value: Bool) {
        hasInitialSnapshot = value
        UserDefaults.standard.set(value, forKey: "MusicLibrary.HasInitialSnapshot")
    }

    // MARK: - テストデータ

    func injectTestData(for personality: Personality) async {
        isInjecting = true
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // 既存テストデータ削除
        await bgContext.perform {
            let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
            req.predicate = NSPredicate(format: "trackID BEGINSWITH %@", TestDataGenerator.prefix)
            try? bgContext.execute(NSBatchDeleteRequest(fetchRequest: req))
            try? bgContext.save()
        }

        // 新規レコード生成 & 保存
        let records = TestDataGenerator.generate(for: personality)
        let chunkSize = 200
        for start in stride(from: 0, to: records.count, by: chunkSize) {
            let end = min(start + chunkSize, records.count)
            let chunk = Array(records[start..<end])
            await bgContext.perform {
                for r in chunk {
                    let e = PlayHistoryEntity(context: bgContext)
                    e.trackID   = r.trackID
                    e.title     = r.title
                    e.artistName = r.artistName
                    e.albumTitle = r.albumTitle
                    e.playedAt  = r.playedAt
                    e.duration  = r.duration
                    e.isLocalAsset = r.isLocalAsset
                    e.playCountSnapshot = r.playCountSnapshot
                }
                try? bgContext.save()
                bgContext.reset()
            }
        }

        UserDefaults.standard.set(personality.rawValue, forKey: TestDataGenerator.personalityKey)
        context.refreshAllObjects()
        reloadCounts()
        loadTestDataInfo()
        isInjecting = false
    }

    func resetTestData() async {
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        await bgContext.perform {
            let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
            req.predicate = NSPredicate(format: "trackID BEGINSWITH %@", TestDataGenerator.prefix)
            try? bgContext.execute(NSBatchDeleteRequest(fetchRequest: req))
            try? bgContext.save()
        }
        UserDefaults.standard.removeObject(forKey: TestDataGenerator.personalityKey)
        context.refreshAllObjects()
        testDataCount = 0
        testDataPersonalityLabel = ""
        reloadCounts()
    }

    func resetHistory() async {
        let tracker = PlayHistoryTracker()
        await tracker.resetAndRebuildHistory()
        diffSyncCount = 0
        testDataCount = 0
        testDataPersonalityLabel = ""
        UserDefaults.standard.removeObject(forKey: TestDataGenerator.personalityKey)
        reloadCounts()
        accuracyLevel = .baseline
        hasInitialSnapshot = UserDefaults.standard.bool(forKey: "MusicLibrary.HasInitialSnapshot")
    }

    // MARK: - Private helpers

    private func loadTestDataInfo() {
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
        req.predicate = NSPredicate(format: "trackID BEGINSWITH %@", TestDataGenerator.prefix)
        testDataCount = (try? context.count(for: req)) ?? 0
        testDataPersonalityLabel = UserDefaults.standard.string(forKey: TestDataGenerator.personalityKey) ?? ""
    }

    private func reloadCounts() {
        let histReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayHistoryEntity")
        historyCount = (try? context.count(for: histReq)) ?? 0
    }

    private func loadAllDiffs(tracks: [Track]) {
        let snapReq = NSFetchRequest<PlayCountSnapshotEntity>(entityName: "PlayCountSnapshotEntity")
        guard let snapshots = try? context.fetch(snapReq) else { return }
        let snapshotMap = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.trackID, $0.playCount) })

        let diffs: [PlayCountDiffEntry] = tracks.compactMap { track in
            let current = Int32(track.playCount)
            let previous = snapshotMap[track.id] ?? current
            guard current > previous else { return nil }
            return PlayCountDiffEntry(title: track.title, artist: track.artistName, before: previous, after: current)
        }
        allDiffs = diffs.sorted { $0.delta > $1.delta }
    }
}

// MARK: - TestDataGenerator

struct TestDataGenerator {
    static let prefix = "DEV_TEST_"
    static let personalityKey = "DEV.TestDataPersonality"

    struct Record {
        let trackID: String
        let title: String
        let artistName: String
        let albumTitle: String
        let playedAt: Date
        let duration: Double
        let isLocalAsset: Bool
        let playCountSnapshot: Int32
    }

    private struct T {
        let id: String
        let title: String
        let artist: String
        let album: String
        let isLocal: Bool
        var weight: Double = 1.0
        var duration: Double = 240
    }

    static func generate(for personality: Personality, months: Int = 6) -> [Record] {
        let pool = pool(for: personality)
        let count = totalCount(for: personality)
        return build(pool: pool, count: count, months: months)
    }

    private static func totalCount(for p: Personality) -> Int {
        switch p {
        case .legend:    return 1200
        case .collector, .streamingFan, .heavyRotator, .balanced: return 600
        default:         return 450
        }
    }

    private static func build(pool: [T], count: Int, months: Int) -> [Record] {
        let totalW = pool.reduce(0) { $0 + $1.weight }
        var playMap: [String: Int32] = [:]
        let now = Date()
        let cal = Calendar.current
        var records: [Record] = []

        for _ in 0..<count {
            // 重み付きランダム選択
            var roll = Double.random(in: 0..<totalW)
            var picked = pool[0]
            for t in pool {
                roll -= t.weight
                if roll <= 0 { picked = t; break }
            }

            // 日時：過去 months × 30 日以内のランダム
            let dayOffset = Int.random(in: 0..<(months * 30))
            let hour = Int.random(in: 6..<24)
            let minute = Int.random(in: 0..<60)
            let base = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let date = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base

            let trackID = "\(prefix)\(picked.id)"
            playMap[trackID, default: 0] += 1

            records.append(Record(
                trackID: trackID,
                title: picked.title,
                artistName: picked.artist,
                albumTitle: picked.album,
                playedAt: date,
                duration: picked.duration,
                isLocalAsset: picked.isLocal,
                playCountSnapshot: playMap[trackID]!
            ))
        }
        return records
    }

    // MARK: - プール定義

    private static func pool(for p: Personality) -> [T] {
        switch p {
        case .collector:      return collectorPool()
        case .streamingFan:   return streamingPool()
        case .obsessedFan:    return obsessedPool()
        case .singleFocus:    return singleFocusPool()
        case .heavyRotator:   return heavyRotatorPool()
        case .legend:         return legendPool()
        case .explorer:       return explorerPool()
        case .loyalListener:  return loyalPool()
        case .growingListener: return growingPool()
        case .nostalgic:      return nostalgicPool()
        case .genreAddict:    return genreAddictPool()
        case .balanced:       return balancedPool()
        }
    }

    // コレクター(CD): ローカル音源 80%
    private static func collectorPool() -> [T] {
        let locals = [("山下達郎", "GET BACK IN LOVE", "FOR YOU"),
                      ("松任谷由実", "ルージュの伝言", "COBALT HOUR"),
                      ("Mr.Children", "Tomorrow never knows", "Atomic Heart"),
                      ("サザンオールスターズ", "TSUNAMI", "KILLER STREET"),
                      ("宇多田ヒカル", "First Love", "First Love")]
        var pool: [T] = []
        for (i, (artist, track, album)) in locals.enumerated() {
            for j in 1...5 {
                pool.append(T(id: "COL_\(i)_\(j)", title: j == 1 ? track : "\(artist) 収録曲\(j)",
                               artist: artist, album: album, isLocal: true, weight: 4.0))
            }
        }
        let streams = [("YOASOBI", "夜に駆ける"), ("Ado", "うっせぇわ"), ("藤井風", "死ぬのがいいわ")]
        for (i, (artist, track)) in streams.enumerated() {
            pool.append(T(id: "COL_S_\(i)", title: track, artist: artist, album: "\(artist) Album", isLocal: false, weight: 1.0))
        }
        return pool
    }

    // サブスク派: ストリーミング 90%
    private static func streamingPool() -> [T] {
        let streams = [("YOASOBI", "夜に駆ける", "THE BOOK"),
                       ("Ado", "うっせぇわ", "狂言"),
                       ("藤井風", "死ぬのがいいわ", "LOVE ALL SERVE ALL"),
                       ("Official髭男dism", "Pretender", "Traveler"),
                       ("米津玄師", "Lemon", "BOOTLEG"),
                       ("King Gnu", "白日", "Sympa")]
        var pool: [T] = []
        for (i, (artist, track, album)) in streams.enumerated() {
            for j in 1...4 {
                pool.append(T(id: "STR_\(i)_\(j)", title: j == 1 ? track : "\(artist) 曲\(j)",
                               artist: artist, album: album, isLocal: false, weight: 4.0))
            }
        }
        for i in 1...4 {
            pool.append(T(id: "STR_L_\(i)", title: "CD曲\(i)", artist: "CDアーティスト\(i)",
                           album: "CDアルバム\(i)", isLocal: true, weight: 1.0))
        }
        return pool
    }

    // 推しが本気: 1アーティストが 60% 以上
    private static func obsessedPool() -> [T] {
        var pool: [T] = []
        let oshi = "推しアーティスト"
        for i in 1...8 {
            pool.append(T(id: "OBS_M_\(i)", title: "推し曲\(i)", artist: oshi,
                           album: "\(oshi) COMPLETE BEST", isLocal: false, weight: 5.0))
        }
        for i in 1...12 {
            pool.append(T(id: "OBS_O_\(i)", title: "その他曲\(i)", artist: "アーティスト\(i % 5 + 1)",
                           album: "アルバム\(i)", isLocal: false, weight: 1.0))
        }
        return pool
    }

    // 一点集中型: 1曲が 15% 以上
    private static func singleFocusPool() -> [T] {
        var pool: [T] = [
            T(id: "SF_MAIN", title: "大好きな一曲", artist: "お気に入りアーティスト",
              album: "お気に入りアルバム", isLocal: false, weight: 8.0)
        ]
        for i in 1...40 {
            pool.append(T(id: "SF_O_\(i)", title: "その他曲\(i)", artist: "アーティスト\(i % 8 + 1)",
                           album: "アルバム\(i % 5 + 1)", isLocal: i % 3 == 0, weight: 0.5))
        }
        return pool
    }

    // ヘビロテ職人: 10曲が 70% 以上
    private static func heavyRotatorPool() -> [T] {
        var pool: [T] = []
        for i in 1...10 {
            pool.append(T(id: "HR_H_\(i)", title: "ヘビロテ曲\(i)", artist: "ヘビロテアーティスト\(i % 3 + 1)",
                           album: "ヘビロテアルバム", isLocal: false, weight: 5.0))
        }
        for i in 1...15 {
            pool.append(T(id: "HR_O_\(i)", title: "たまに聴く曲\(i)", artist: "サブアーティスト\(i % 5 + 1)",
                           album: "アルバム\(i)", isLocal: false, weight: 0.8))
        }
        return pool
    }

    // レジェンド: 総再生数が多く TOP曲が 20% 以上
    private static func legendPool() -> [T] {
        var pool: [T] = [
            T(id: "LEG_TOP", title: "伝説の一曲", artist: "レジェンドアーティスト",
              album: "LEGEND BEST", isLocal: true, weight: 3.0)
        ]
        for i in 1...40 {
            pool.append(T(id: "LEG_O_\(i)", title: "名曲\(i)", artist: "レジェンドアーティスト\(i % 8 + 1)",
                           album: "BEST Vol.\(i % 5 + 1)", isLocal: i % 2 == 0, weight: 1.0))
        }
        return pool
    }

    // 音楽探検家: 多様なアーティスト
    private static func explorerPool() -> [T] {
        (1...50).map { i in
            T(id: "EXP_\(i)", title: "発見曲\(i)", artist: "新発見アーティスト\(i)",
              album: "ディスカバリー Vol.\(i % 10 + 1)", isLocal: false, weight: 1.0)
        }
    }

    // 固定リスナー: 10アーティストが 80% 以上
    private static func loyalPool() -> [T] {
        var pool: [T] = []
        for ai in 1...10 {
            for ti in 1...3 {
                pool.append(T(id: "LOY_\(ai)_\(ti)", title: "定番曲\(ti)", artist: "定番アーティスト\(ai)",
                               album: "定番アルバム\(ai)", isLocal: ai % 2 == 0, weight: 4.0))
            }
        }
        for i in 1...15 {
            pool.append(T(id: "LOY_O_\(i)", title: "たまに聴く\(i)", artist: "その他\(i)",
                           album: "その他アルバム", isLocal: false, weight: 1.0))
        }
        return pool
    }

    // 成長型リスナー: 最新曲が多い
    private static func growingPool() -> [T] {
        (1...40).map { i in
            T(id: "GRW_\(i)", title: "最新曲\(i)", artist: "最新アーティスト\(i % 15 + 1)",
              album: "最新アルバム\(i % 8 + 1)", isLocal: false, weight: 1.0)
        }
    }

    // 懐古リスナー: 同じ定番曲を繰り返し
    private static func nostalgicPool() -> [T] {
        (1...15).map { i in
            T(id: "NOS_\(i)", title: "思い出の曲\(i)", artist: "懐かしいアーティスト\(i % 5 + 1)",
              album: "懐かしのアルバム\(i % 4 + 1)", isLocal: true, weight: 1.0)
        }
    }

    // ジャンル偏愛家: メインジャンルが 70% 以上
    private static func genreAddictPool() -> [T] {
        var pool: [T] = []
        for i in 1...12 {
            pool.append(T(id: "GA_M_\(i)", title: "J-Rock曲\(i)", artist: "J-Rockバンド\(i % 4 + 1)",
                           album: "J-Rockアルバム\(i % 3 + 1)", isLocal: i % 2 == 0, weight: 4.0))
        }
        for i in 1...10 {
            pool.append(T(id: "GA_O_\(i)", title: "その他ジャンル曲\(i)", artist: "その他アーティスト\(i)",
                           album: "その他アルバム", isLocal: false, weight: 1.0))
        }
        return pool
    }

    // バランス型: 20+ アーティスト・複数ジャンル・均等
    private static func balancedPool() -> [T] {
        (1...30).map { i in
            T(id: "BAL_\(i)", title: "バランス曲\(i)", artist: "アーティスト\(i)",
              album: "アルバム\(i % 8 + 1)", isLocal: i % 3 == 0, weight: 1.0)
        }
    }
}
