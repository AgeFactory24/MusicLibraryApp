//
//  MoreView.swift
//  MusicLibrary
//

import SwiftUI

struct MoreView: View {
    @StateObject private var yearlyVM = YearlyReportViewModel()
    @EnvironmentObject var libraryVM: LibraryViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PersonalityAnalysisView()
                            .environmentObject(libraryVM)
                    } label: {
                        MoreItemRow(
                            icon: "person.crop.circle.badge.checkmark",
                            color: .pink,
                            title: "音楽パーソナリティ",
                            subtitle: "あなたのリスニングスタイルを分析"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        YearlyReportView()
                            .environmentObject(yearlyVM)
                            .onAppear {
                                yearlyVM.resetToCurrent()
                            }
                    } label: {
                        MoreItemRow(
                            icon: "calendar.badge.clock",
                            color: .pink,
                            title: "年間レポート",
                            subtitle: "1年間のリスニング履歴を振り返る"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        QRCompatibilityView()
                    } label: {
                        MoreItemRow(
                            icon: "qrcode.viewfinder",
                            color: .pink,
                            title: "音楽相性チェック",
                            subtitle: "友達のQRをスキャンして相性を診断"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        MoreItemRow(
                            icon: "gearshape.fill",
                            color: .gray,
                            title: "設定",
                            subtitle: "通知設定など"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        DeveloperModeView()
                            .environmentObject(libraryVM)
                    } label: {
                        MoreItemRow(
                            icon: "hammer.fill",
                            color: .indigo,
                            title: "開発者モード",
                            subtitle: "内部デバッグ・確認用"
                        )
                    }
                }
            }
            .navigationTitle("more")
        }
    }
}

private struct MoreItemRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
