//
//  MusicAuthService.swift
//  MusicLibrary
//

import Foundation
import MusicKit
import Combine

@MainActor
final class MusicAuthService: ObservableObject {
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isAuthorized: Bool = false

    init() {
        Task {
            await checkCurrentStatus()
        }
    }

    func checkCurrentStatus() async {
        authorizationStatus = MusicAuthorization.currentStatus
        isAuthorized = authorizationStatus == .authorized
    }

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
    }
}
