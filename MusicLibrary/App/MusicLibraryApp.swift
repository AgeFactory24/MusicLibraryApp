//
//  MusicLibraryApp.swift
//  MusicLibrary
//

import SwiftUI
import CoreData

@main
struct MusicLibraryApp: App {
    @StateObject private var authService = MusicAuthService()
    @StateObject private var artworkService = ArtworkService()
    @StateObject private var historyTracker = PlayHistoryTracker()
    @StateObject private var favoriteService = FavoriteService()
    @StateObject private var searchHistoryService = SearchHistoryService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var profileService = UserProfileService()
    @StateObject private var cloudSyncService = CloudSyncService()

    @AppStorage("MusicLibrary.HasCompletedOnboarding")
    private var hasCompletedOnboarding: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundSyncManager.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(authService)
                .environmentObject(artworkService)
                .environmentObject(historyTracker)
                .environmentObject(favoriteService)
                .environmentObject(searchHistoryService)
                .environmentObject(notificationService)
                .environmentObject(profileService)
                .environmentObject(cloudSyncService)
                .environment(\.managedObjectContext,
                             PersistenceController.shared.container.viewContext)
                .task {
                    if authService.isAuthorized {
                        await historyTracker.syncPlayHistory()
                        // Live Activity は遅延起動（履歴同期完了後）
                        // クラッシュ回避のため try-catch相当の保護を内部で行う
                        NowPlayingActivityManager.shared.start()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhase(newPhase)
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            ContentView()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task {
                if authService.isAuthorized {
                    await historyTracker.syncPlayHistory()
                    NowPlayingActivityManager.shared.start()
                }
                await notificationService.checkAuthorization()
            }
        case .background:
            BackgroundSyncManager.shared.scheduleNextRefresh()
        default:
            break
        }
    }
}
