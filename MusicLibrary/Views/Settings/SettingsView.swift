//
//  SettingsView.swift
//  MusicLibrary
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var profileService: UserProfileService
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @EnvironmentObject var historyTracker: PlayHistoryTracker

    @State private var photoItem: PhotosPickerItem?
    @State private var showProfileEditor = false
    @State private var showRebuildConfirm = false
    @State private var isRebuilding = false

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                cloudSyncSection
                notificationSection
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView()
                    .environmentObject(profileService)
            }
            .alert("履歴を再構築しますか？", isPresented: $showRebuildConfirm) {
                Button("再構築", role: .destructive) {
                    Task {
                        isRebuilding = true
                        await historyTracker.resetAndRebuildHistory()
                        isRebuilding = false
                        Haptics.play(.success)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("既存の再生履歴をクリアし、Apple Musicの再生回数から再構築します。\n楽曲数が多い場合、数十秒かかることがあります。")
            }
        }
    }

    // MARK: - プロフィール

    private var profileSection: some View {
        Section {
            Button {
                Haptics.play(.light)
                showProfileEditor = true
            } label: {
                HStack(spacing: 14) {
                    if let icon = profileService.iconImage {
                        Image(uiImage: icon)
                            .resizable().scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.pink)
                            }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profileService.userName.isEmpty ? "プロフィールを設定" : profileService.userName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(profileService.userName.isEmpty ? "名前とアイコンを設定できます" : "タップして編集")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("プロフィール")
        }
    }

    // MARK: - iCloud同期

    private var cloudSyncSection: some View {
        Section {
            Toggle(isOn: $cloudSyncService.isCloudSyncEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud同期")
                            .font(.subheadline)
                        Text("再生履歴・カスタム画像を同期")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if cloudSyncService.isCloudSyncEnabled {
                HStack {
                    Label("最終同期", systemImage: "clock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(cloudSyncService.lastSyncFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        Haptics.play(.light)
                        await cloudSyncService.manualSync()
                        if cloudSyncService.syncError == nil {
                            Haptics.play(.success)
                        } else {
                            Haptics.play(.error)
                        }
                    }
                } label: {
                    HStack {
                        if cloudSyncService.isSyncing {
                            ProgressView()
                                .controlSize(.small)
                            Text("同期中...")
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("今すぐ同期")
                        }
                    }
                }
                .disabled(cloudSyncService.isSyncing)

                if let error = cloudSyncService.syncError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("データ同期")
        } footer: {
            Text("複数のデバイスで同じiCloudアカウントを使用すると自動的に同期されます")
        }
    }

    // MARK: - 通知

    private var notificationSection: some View {
        Section {
            if notificationService.authorizationStatus == .notDetermined {
                Button {
                    Task {
                        Haptics.play(.light)
                        _ = await notificationService.requestAuthorization()
                    }
                } label: {
                    Label("通知を許可する", systemImage: "bell.badge")
                }
            } else if notificationService.authorizationStatus == .denied {
                HStack {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading) {
                        Text("通知が無効になっています")
                            .font(.subheadline)
                        Text("設定アプリから許可してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("設定") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            } else {
                ForEach(NotificationKind.allCases) { kind in
                    Toggle(isOn: Binding(
                        get: { notificationService.isEnabled(kind) },
                        set: { newValue in
                            Haptics.play(.light)
                            notificationService.toggle(kind, enabled: newValue)
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: kind.icon)
                                .foregroundStyle(.pink)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title)
                                    .font(.subheadline)
                                Text(kind.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("通知")
        }
    }

    // MARK: - データ管理（進捗表示付き）

    private var dataSection: some View {
        Section {
            // 同期中の進捗表示
            if let progress = historyTracker.syncProgress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("履歴を再構築中...")
                            .font(.subheadline)
                        Spacer()
                        Text("\(progress.processed) / \(progress.total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress.percentage)
                        .tint(.pink)
                }
                .padding(.vertical, 4)
            }

            Button {
                Haptics.play(.light)
                showRebuildConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.pink)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("履歴を再構築")
                            .font(.subheadline)
                        Text("Apple Musicの再生回数から履歴を作り直します")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isRebuilding || historyTracker.syncProgress != nil)
        } header: {
            Text("データ管理")
        } footer: {
            Text("レポートにデータが反映されない場合に試してください")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("アプリについて")
        }
    }

    private var appVersion: String {
        let dict = Bundle.main.infoDictionary
        return dict?["CFBundleShortVersionString"] as? String ?? "2.0"
    }
}

// MARK: - プロフィール編集画面

struct ProfileEditorView: View {
    @EnvironmentObject var profileService: UserProfileService
    @Environment(\.dismiss) var dismiss

    @State private var nameInput: String = ""
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                if let icon = profileService.iconImage {
                                    Image(uiImage: icon)
                                        .resizable().scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 100, height: 100)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 44))
                                                .foregroundStyle(.pink)
                                        }
                                }
                            }
                            .shadow(radius: 4)

                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label("写真を選ぶ", systemImage: "photo")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.pink)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("名前") {
                    TextField("ユーザー名", text: $nameInput)
                }

                if profileService.iconImage != nil {
                    Section {
                        Button(role: .destructive) {
                            Haptics.play(.light)
                            profileService.deleteIcon()
                        } label: {
                            Label("アイコンを削除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Haptics.play(.success)
                        profileService.userName = nameInput
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                nameInput = profileService.userName
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profileService.saveIcon(image)
                        Haptics.play(.success)
                    }
                    photoItem = nil
                }
            }
        }
    }
}
