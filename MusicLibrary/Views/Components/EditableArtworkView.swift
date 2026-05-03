//
//  EditableArtworkView.swift
//  MusicLibrary
//
//  互換性のため残しているが、新しい *ArtworkView を使ってください
//

import SwiftUI

/// 互換: TrackDetailView 等から使われていたシンプル版
/// 内部は TrackArtworkView で代用
struct EditableArtworkSimpleView: View {
    let key: String
    let type: ArtworkType
    let fallbackImage: UIImage?
    var size: CGFloat = 200

    @EnvironmentObject var artworkService: ArtworkService
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                if type == .artist {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                placeholder
            }
        }
        .task(id: key) {
            // カスタム → fallback
            if let custom = artworkService.loadCustomImage(key: key, type: type) {
                image = custom
            } else {
                image = fallbackImage
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if type == .artist {
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "music.mic")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.pink)
                }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.pink)
                }
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// 互換用
struct EditableArtworkView: View {
    let key: String
    let type: ArtworkType
    let fallbackImage: UIImage?
    var size: CGFloat = 200
    var allowEdit: Bool = true

    var body: some View {
        EditableArtworkSimpleView(
            key: key,
            type: type,
            fallbackImage: fallbackImage,
            size: size
        )
    }
}

/// 互換用：旧コードからの参照向け
struct ArtworkDisplayView: View {
    let key: String
    let type: ArtworkType
    let fallbackImage: UIImage?
    var size: CGFloat = 44

    var body: some View {
        EditableArtworkSimpleView(
            key: key,
            type: type,
            fallbackImage: fallbackImage,
            size: size
        )
    }
}
