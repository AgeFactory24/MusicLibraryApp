//
//  CloudSyncService.swift
//  MusicLibrary
//
//  CloudKit同期の管理
//

import SwiftUI
import Foundation
import CoreData
import Combine
import CloudKit

@MainActor
final class CloudSyncService: ObservableObject {

    @Published var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: enabledKey)
        }
    }

    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false
    @Published var syncError: String?

    private let enabledKey = "MusicLibrary.CloudSyncEnabled"
    private let lastSyncKey = "MusicLibrary.LastSyncDate"

    init() {
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        if let timestamp = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            self.lastSyncDate = timestamp
        }

        // CloudKitの同期通知を購読
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.lastSyncDate = Date()
                UserDefaults.standard.set(Date(), forKey: self?.lastSyncKey ?? "")
            }
        }
    }

    /// 手動同期：CKContainer の accountStatus 確認 + コンテキスト保存
    func manualSync() async {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        // iCloudアカウント確認
        do {
            let status = try await CKContainer.default().accountStatus()
            guard status == .available else {
                syncError = "iCloudにサインインしてください"
                return
            }
        } catch {
            syncError = "iCloud状態の確認に失敗しました"
            return
        }

        // 保留中の変更を保存（同期トリガー）
        let context = PersistenceController.shared.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                syncError = "保存に失敗しました: \(error.localizedDescription)"
                return
            }
        }

        // 少し待ってから完了扱い
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        lastSyncDate = Date()
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
    }

    var lastSyncFormatted: String {
        guard let date = lastSyncDate else { return "未同期" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
