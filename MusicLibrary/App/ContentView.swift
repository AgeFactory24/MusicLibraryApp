//
//  ContentView.swift
//  MusicLibrary
//

import SwiftUI

enum AppTab: Int, Hashable {
    case home, ranking, monthly, more
}

struct ContentView: View {
    @EnvironmentObject var authService: MusicAuthService
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var rankingVM = RankingViewModel()
    @StateObject private var statsVM = StatisticsViewModel()
    @StateObject private var monthlyVM = MonthlyReportViewModel()

    var body: some View {
        Group {
            if authService.isAuthorized {
                MainTabView()
                    .environmentObject(libraryVM)
                    .environmentObject(rankingVM)
                    .environmentObject(statsVM)
                    .environmentObject(monthlyVM)
                    .task {
                        await libraryVM.loadLibrary()
                        rankingVM.buildRanking(libraryTracks: libraryVM.tracks)
                        rankingVM.buildHomeRanking(libraryTracks: libraryVM.tracks)
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
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject var monthlyVM: MonthlyReportViewModel

    var body: some View {
        TabView(selection: tabBinding) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)

            RankingView()
                .tabItem { Label("ランキング", systemImage: "chart.bar.fill") }
                .tag(AppTab.ranking)

            MonthlyReportView()
                .tabItem { Label("月別", systemImage: "calendar") }
                .tag(AppTab.monthly)

            MoreView()
                .tabItem { Label("more", systemImage: "ellipsis.circle.fill") }
                .tag(AppTab.more)
        }
        .tint(.pink)
    }

    /// タブ選択を制御するBinding
    /// 「月別タブを選択した時」と「同じタブを再タップした時」両方で「今月」にリセット
    private var tabBinding: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // 月別タブを選択するたびに「今月」にリセット
                if newValue == .monthly {
                    monthlyVM.resetToCurrent()
                    if newValue == selectedTab {
                        Haptics.play(.light)
                    }
                }
                selectedTab = newValue
            }
        )
    }
}
