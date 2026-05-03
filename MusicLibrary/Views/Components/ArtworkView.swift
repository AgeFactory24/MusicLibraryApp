//
//  ArtworkView.swift
//  MusicLibrary
//

import SwiftUI
import PhotosUI

/// 共通のセクションヘッダー
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal)
    }
}

/// 楽曲・アルバム用のアートワーク プレースホルダー
struct ArtworkPlaceholder: View {
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(
                LinearGradient(
                    colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(.pink)
            }
    }
}

// MARK: - アーティスト画像（自動取得 + 長押し変更）

struct ArtistArtworkView: View {
    let artist: Artist
    var size: CGFloat = 44
    var allowEdit: Bool = false

    @EnvironmentObject var artworkService: ArtworkService
    @State private var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showActions = false
    @State private var showPicker = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(gradient)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "music.mic")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.pink)
                    }
            }
        }
        .contentShape(Circle())
        .modifier(LongPressActionModifier(
            enabled: allowEdit,
            action: { showActions = true }
        ))
        .task(id: artist.id) {
            image = await artworkService.loadArtistImage(artistName: artist.name)
        }
        .confirmationDialog("アーティスト画像", isPresented: $showActions, titleVisibility: .visible) {
            Button("写真ライブラリから選択") {
                showPicker = true
            }
            if hasCustomImage {
                Button("カスタム画像を削除", role: .destructive) {
                    artworkService.deleteCustomImage(key: artist.id, type: .artist)
                    Task {
                        image = await artworkService.loadArtistImage(artistName: artist.name)
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    artworkService.saveCustomImage(img, key: artist.id, type: .artist)
                    image = img
                }
                photoItem = nil
            }
        }
    }

    private var hasCustomImage: Bool {
        artworkService.loadCustomImage(key: artist.id, type: .artist) != nil
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - アルバム画像（自動取得 + 長押し変更）

struct AlbumArtworkView: View {
    let album: Album
    var size: CGFloat = 44
    var allowEdit: Bool = false

    @EnvironmentObject var artworkService: ArtworkService
    @State private var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showActions = false
    @State private var showPicker = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
            } else {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(gradient)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.pink)
                    }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: size * 0.15))
        .modifier(LongPressActionModifier(
            enabled: allowEdit,
            action: { showActions = true }
        ))
        .task(id: album.id) {
            image = await artworkService.loadAlbumImage(album: album)
        }
        .confirmationDialog("アルバム画像", isPresented: $showActions, titleVisibility: .visible) {
            Button("写真ライブラリから選択") {
                showPicker = true
            }
            if hasCustomImage {
                Button("カスタム画像を削除", role: .destructive) {
                    artworkService.deleteCustomImage(key: album.id, type: .album)
                    Task {
                        image = await artworkService.loadAlbumImage(album: album)
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    artworkService.saveCustomImage(img, key: album.id, type: .album)
                    image = img
                }
                photoItem = nil
            }
        }
    }

    private var hasCustomImage: Bool {
        artworkService.loadCustomImage(key: album.id, type: .album) != nil
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 楽曲アートワーク（楽曲のアートワーク or アルバム自動取得 + 長押し変更）

struct TrackArtworkView: View {
    let track: Track
    var size: CGFloat = 44
    var allowEdit: Bool = false

    @EnvironmentObject var artworkService: ArtworkService
    @State private var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showActions = false
    @State private var showPicker = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
            } else {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(gradient)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.pink)
                    }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: size * 0.15))
        .modifier(LongPressActionModifier(
            enabled: allowEdit,
            action: { showActions = true }
        ))
        .task(id: track.id) {
            await loadImage()
        }
        .confirmationDialog("アートワーク", isPresented: $showActions, titleVisibility: .visible) {
            Button("写真ライブラリから選択") {
                showPicker = true
            }
            if hasCustomImage {
                Button("カスタム画像を削除", role: .destructive) {
                    artworkService.deleteCustomImage(key: track.albumTitle, type: .album)
                    Task { await loadImage() }
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    // 楽曲のアートワークはアルバム単位で保存
                    artworkService.saveCustomImage(img, key: track.albumTitle, type: .album)
                    image = img
                }
                photoItem = nil
            }
        }
    }

    private func loadImage() async {
        // ① アルバムのカスタム画像
        if let custom = artworkService.loadCustomImage(key: track.albumTitle, type: .album) {
            image = custom
            return
        }
        // ② MPMediaItemから取得
        if let pid = UInt64(track.id),
           let mp = artworkService.fetchTrackArtwork(persistentID: pid) {
            image = mp
            return
        }
        // ③ iTunes Search APIから取得（アルバム単位）
        let dummyAlbum = Album(
            id: track.albumTitle,
            title: track.albumTitle,
            artistName: track.artistName,
            artworkURL: nil,
            tracks: []
        )
        image = await artworkService.loadAlbumImage(album: dummyAlbum)
    }

    private var hasCustomImage: Bool {
        artworkService.loadCustomImage(key: track.albumTitle, type: .album) != nil
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 共通: 長押しジェスチャー Modifier

/// 条件付きで長押しジェスチャーを付与する
struct LongPressActionModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.onLongPressGesture(minimumDuration: 0.5) {
                action()
            }
        } else {
            content
        }
    }
}
