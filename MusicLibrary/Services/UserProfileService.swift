//
//  UserProfileService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import UIKit
import Combine

@MainActor
final class UserProfileService: ObservableObject {

    @Published var userName: String = "" {
        didSet { saveUserName() }
    }

    @Published var iconImage: UIImage?

    private let userDefaults = UserDefaults.standard
    private let userNameKey = "MusicLibrary.UserName"
    private let iconFileName = "user_profile_icon.jpg"

    private var iconURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(iconFileName)
    }

    /// 表示用：ユーザー名（未設定時は「あなた」）
    var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "あなた" : trimmed
    }

    init() {
        load()
    }

    // MARK: - 永続化

    private func load() {
        userName = userDefaults.string(forKey: userNameKey) ?? ""

        if FileManager.default.fileExists(atPath: iconURL.path),
           let data = try? Data(contentsOf: iconURL),
           let image = UIImage(data: data) {
            iconImage = image
        }
    }

    private func saveUserName() {
        userDefaults.set(userName, forKey: userNameKey)
    }

    func saveIcon(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: iconURL)
        iconImage = image
        objectWillChange.send()
    }

    func deleteIcon() {
        try? FileManager.default.removeItem(at: iconURL)
        iconImage = nil
        objectWillChange.send()
    }
}
