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
        // iOS 26+: ネイティブ TabView が自動で Liquid Glass タブバーになる
        if #available(iOS 26, *) {
            liquidGlassTabView
        } else {
            floatingPillTabView
        }
    }

    // MARK: iOS 26+ — Liquid Glass ネイティブタブバー

    @available(iOS 26, *)
    private var liquidGlassTabView: some View {
        TabView(selection: $selectedTab) {
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
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .monthly { monthlyVM.resetToCurrent() }
        }
    }

    // MARK: iOS 17-25 — カスタムフローティングピル型タブバー

    private var floatingPillTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.home)

            RankingView()
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.ranking)

            MonthlyReportView()
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.monthly)

            MoreView()
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.more)
        }
        .tint(.pink)
        // ScrollView/List のコンテンツ下端がタブバーに隠れないようにマージンを確保
        .contentMargins(.bottom, FloatingTabBar.reservedHeight, for: .scrollContent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(
                selectedTab: $selectedTab,
                onReselect: { tab in
                    if tab == .monthly { monthlyVM.resetToCurrent() }
                    Haptics.play(.light)
                }
            )
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .monthly { monthlyVM.resetToCurrent() }
        }
    }
}

// MARK: - フローティングピル型タブバー（iOS 17-25 / 2-A）

private struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    let onReselect: (AppTab) -> Void

    // safeAreaInset に渡す確保高さ（ピル高さ + 上下パディング）
    static let reservedHeight: CGFloat = 82

    private let items: [(AppTab, String, String)] = [
        (.home,    "house.fill",           "ホーム"),
        (.ranking, "chart.bar.fill",       "ランキング"),
        (.monthly, "calendar",             "月別"),
        (.more,    "ellipsis.circle.fill", "more"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.0) { tab, icon, label in
                let isSelected = selectedTab == tab
                Button {
                    if selectedTab == tab {
                        onReselect(tab)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            selectedTab = tab
                        }
                        Haptics.play(.light)
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                        Text(label)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            Capsule().fill(.white.opacity(0.18))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.black.opacity(0.72))
                .background(Capsule().fill(.ultraThinMaterial))
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }
}
