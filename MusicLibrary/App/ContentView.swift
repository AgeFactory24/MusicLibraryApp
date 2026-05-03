//
//  ContentView.swift
//  MusicLibrary
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: MusicAuthService
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var rankingVM = RankingViewModel()
    @StateObject private var statsVM = StatisticsViewModel()

    var body: some View {
        Group {
            if authService.isAuthorized {
                MainTabView()
                    .environmentObject(libraryVM)
                    .environmentObject(rankingVM)
                    .environmentObject(statsVM)
                    .task {
                        await libraryVM.loadLibrary()
                        rankingVM.buildRanking(
                            from: libraryVM.tracks,
                            artists: libraryVM.artists,
                            albums: libraryVM.albums
                        )
                        statsVM.buildStats(
                            from: libraryVM.tracks,
                            artists: libraryVM.artists
                        )
                    }
            } else {
                AuthorizationView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            RankingView()
                .tabItem { Label("ランキング", systemImage: "chart.bar.fill") }

            MonthlyReportView()
                .tabItem { Label("月別", systemImage: "calendar") }

            TimeOfDayView()
                .tabItem { Label("時間帯", systemImage: "clock.fill") }

            MoreView()
                .tabItem { Label("more", systemImage: "ellipsis.circle.fill") }
        }
        .tint(.pink)
    }
}
