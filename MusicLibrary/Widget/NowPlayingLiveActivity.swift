//
//  NowPlayingLiveActivity.swift
//  MusicLibraryWidget
//
//  Live Activity の UI（ロック画面・ダイナミックアイランド）
//

import WidgetKit
import SwiftUI
import ActivityKit

struct NowPlayingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingActivityAttributes.self) { context in
            // ロック画面表示
            LockScreenLiveActivityView(context: context)
                .widgetURL(URL(string: "musiclibrary://track/\(context.attributes.trackID)"))
                .activityBackgroundTint(.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // ===== 拡張表示（長押し時）=====
                // ↓ 仕様変更: 左上の音符アイコンと右上の通算回数は削除（下部に重複しているため）
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(context.attributes.artistName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: context.state.isPlaying ? "play.fill" : "pause.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                        Text("通算\(context.state.totalPlayCount)回 ・ 今月\(context.state.monthlyPlayCount)回")
                            .font(.caption.bold())
                            .foregroundStyle(.pink)
                        Spacer()
                    }
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                // ===== コンパクト表示（小さい時）=====
                // ↓ 仕様変更: 音符アイコンの位置に「通算再生回数」を表示
                Text("\(context.state.totalPlayCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.pink)
            } compactTrailing: {
                // 右側は再生/停止状態を簡素に表示
                Image(systemName: context.state.isPlaying ? "play.fill" : "pause.fill")
                    .foregroundStyle(.pink)
                    .font(.caption)
            } minimal: {
                // 複数Live Activity時の最小表示
                Text("\(context.state.totalPlayCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.pink)
            }
            .widgetURL(URL(string: "musiclibrary://track/\(context.attributes.trackID)"))
        }
    }
}

// MARK: - ロック画面用ビュー

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<NowPlayingActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [.pink.opacity(0.4), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)

                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.attributes.artistName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Text("通算 \(context.state.totalPlayCount)回 ・ 今月 \(context.state.monthlyPlayCount)回")
                    .font(.caption2.bold())
                    .foregroundStyle(.pink)
            }

            Spacer()
        }
        .padding(12)
    }
}
