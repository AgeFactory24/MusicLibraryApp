//
//  ArtworkService.swift
//  MusicLibrary
//

import SwiftUI
import Foundation
import CoreData
import UIKit
import MediaPlayer
import Combine

enum ArtworkType: String {
    case artist
    case album
}

@MainActor
final class ArtworkService: ObservableObject {

    private let context: NSManagedObjectContext
    private let iTunesService = iTunesSearchService()
    private let deezerService = DeezerSearchService()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var inflightTasks: [String: Task<UIImage?, Never>] = [:]
    private var failedKeys: Set<String> = []

    private lazy var cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("ArtworkCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        memoryCache.countLimit = 200
    }

    // MARK: - 楽曲アートワーク（MPMediaItemから取得）

    func fetchTrackArtwork(persistentID: UInt64, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let predicate = MPMediaPropertyPredicate(
            value: persistentID,
            forProperty: MPMediaItemPropertyPersistentID
        )
        let query = MPMediaQuery()
        query.addFilterPredicate(predicate)
        return query.items?.first?.artwork?.image(at: size)
    }

    // MARK: - カスタム画像

    func saveCustomImage(_ image: UIImage, key: String, type: ArtworkType) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }

        let request = NSFetchRequest<CustomImageEntity>(entityName: "CustomImageEntity")
        request.predicate = NSPredicate(format: "key == %@ AND type == %@", key, type.rawValue)
        request.fetchLimit = 1

        let entity: CustomImageEntity
        if let existing = try? context.fetch(request).first {
            entity = existing
        } else {
            entity = CustomImageEntity(context: context)
            entity.key = key
            entity.type = type.rawValue
        }
        entity.imageData = data
        entity.updatedAt = Date()

        try? context.save()

        memoryCache.setObject(image, forKey: cacheKey(key: key, type: type) as NSString)
        failedKeys.remove(cacheKey(key: key, type: type))

        objectWillChange.send()
        print("💾 [ArtworkService] カスタム画像を保存: \(type.rawValue) - \(key)")
    }

    func loadCustomImage(key: String, type: ArtworkType) -> UIImage? {
        let request = NSFetchRequest<CustomImageEntity>(entityName: "CustomImageEntity")
        request.predicate = NSPredicate(format: "key == %@ AND type == %@", key, type.rawValue)
        request.fetchLimit = 1

        guard let entity = try? context.fetch(request).first else { return nil }
        return UIImage(data: entity.imageData)
    }

    func deleteCustomImage(key: String, type: ArtworkType) {
        let request = NSFetchRequest<CustomImageEntity>(entityName: "CustomImageEntity")
        request.predicate = NSPredicate(format: "key == %@ AND type == %@", key, type.rawValue)

        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
            try? context.save()
        }

        memoryCache.removeObject(forKey: cacheKey(key: key, type: type) as NSString)
        failedKeys.remove(cacheKey(key: key, type: type))

        objectWillChange.send()
    }

    // MARK: - アルバムアートワーク（カスタム or MPMediaItem）

    func resolveAlbumArtwork(album: Album) -> UIImage? {
        if let custom = loadCustomImage(key: album.id, type: .album) {
            return custom
        }
        if let firstTrack = album.tracks.first,
           let persistentID = UInt64(firstTrack.id) {
            return fetchTrackArtwork(persistentID: persistentID)
        }
        return nil
    }

    // MARK: - デバッグ用

    func resetFailedCache() {
        print("🔄 [ArtworkService] failedKeys をリセット (\(failedKeys.count)件)")
        failedKeys.removeAll()
    }

    // MARK: - アーティスト画像取得（Deezer優先 + iTunesフォールバック）

    func loadArtistImage(artistName: String) async -> UIImage? {
        let key = artistName
        let type = ArtworkType.artist
        let cKey = cacheKey(key: key, type: type)

        // ① カスタム画像（最優先）
        if let custom = loadCustomImage(key: key, type: type) {
            return custom
        }
        // ② メモリキャッシュ
        if let cached = memoryCache.object(forKey: cKey as NSString) {
            return cached
        }
        // ③ ディスクキャッシュ
        if let disk = loadFromDisk(cacheKey: cKey) {
            memoryCache.setObject(disk, forKey: cKey as NSString)
            return disk
        }
        // ④ 過去に失敗 → スキップ
        if failedKeys.contains(cKey) {
            return nil
        }
        // ⑤ 進行中タスク
        if let existing = inflightTasks[cKey] {
            return await existing.value
        }

        // ⑥ Deezer → iTunes(album経由) の順でフォールバック
        print("🚀 [ArtworkService] アーティスト画像を新規取得: \(artistName)")
        let task = Task<UIImage?, Never> { [weak self] in
            guard let self else { return nil }

            // Step1: Deezer（人物画像メイン）
            if let url = await self.deezerService.fetchArtistImageURL(artistName: artistName),
               let image = await self.deezerService.downloadImage(from: url) {
                self.memoryCache.setObject(image, forKey: cKey as NSString)
                self.saveToDisk(image: image, cacheKey: cKey)
                print("✅ [ArtworkService] Deezerから取得: \(artistName)")
                return image
            }

            // Step2: iTunesフォールバック（アルバムジャケット）
            print("⏭ [ArtworkService] Deezer失敗 → iTunesにフォールバック")
            if let url = await self.iTunesService.fetchArtistImageURL(artistName: artistName),
               let image = await self.iTunesService.downloadImage(from: url) {
                self.memoryCache.setObject(image, forKey: cKey as NSString)
                self.saveToDisk(image: image, cacheKey: cKey)
                print("✅ [ArtworkService] iTunesから取得: \(artistName)")
                return image
            }

            // 両方失敗
            self.failedKeys.insert(cKey)
            print("❌ [ArtworkService] 両APIで取得失敗: \(artistName)")
            return nil
        }

        inflightTasks[cKey] = task
        let result = await task.value
        inflightTasks[cKey] = nil
        return result
    }

    // MARK: - アルバム画像取得（iTunesのみ）

    func loadAlbumImage(album: Album) async -> UIImage? {
        if let local = resolveAlbumArtwork(album: album) {
            return local
        }

        let key = album.id
        let type = ArtworkType.album
        let cKey = cacheKey(key: key, type: type)

        if let cached = memoryCache.object(forKey: cKey as NSString) {
            return cached
        }
        if let disk = loadFromDisk(cacheKey: cKey) {
            memoryCache.setObject(disk, forKey: cKey as NSString)
            return disk
        }
        if failedKeys.contains(cKey) {
            return nil
        }
        if let existing = inflightTasks[cKey] {
            return await existing.value
        }

        let artistName = album.artistName
        let albumTitle = album.title

        print("🚀 [ArtworkService] アルバム画像を新規取得: \(albumTitle)")
        let task = Task<UIImage?, Never> { [weak self] in
            guard let self else { return nil }

            guard let url = await self.iTunesService.fetchAlbumImageURL(
                artistName: artistName, albumTitle: albumTitle
            ) else {
                self.failedKeys.insert(cKey)
                return nil
            }
            guard let image = await self.iTunesService.downloadImage(from: url) else {
                self.failedKeys.insert(cKey)
                return nil
            }

            self.memoryCache.setObject(image, forKey: cKey as NSString)
            self.saveToDisk(image: image, cacheKey: cKey)
            return image
        }

        inflightTasks[cKey] = task
        let result = await task.value
        inflightTasks[cKey] = nil
        return result
    }

    // MARK: - キャッシュヘルパー

    private func cacheKey(key: String, type: ArtworkType) -> String {
        "\(type.rawValue)_\(key.replacingOccurrences(of: "/", with: "_"))"
    }

    private func diskURL(for cacheKey: String) -> URL {
        let safeName = cacheKey
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return cacheDirectory.appendingPathComponent("\(safeName).jpg")
    }

    private func saveToDisk(image: UIImage, cacheKey: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: diskURL(for: cacheKey))
    }

    private func loadFromDisk(cacheKey: String) -> UIImage? {
        let url = diskURL(for: cacheKey)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
