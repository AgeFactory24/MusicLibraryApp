//
//  PersistenceController.swift
//  MusicLibrary
//
//

import CoreData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    static let appGroupID = "group.com.yourcompany.MusicLibrary"

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "MusicLibrary", managedObjectModel: model)

        let storeURL: URL
        if inMemory {
            storeURL = URL(fileURLWithPath: "/dev/null")
        } else {
            storeURL = URL.storeURL(for: Self.appGroupID, databaseName: "MusicLibrary")
        }

        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("⚠️ CoreData読込エラー: \(error)")
            } else {
                print("✅ CoreData読込成功")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - モデル定義

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ===== PlayHistoryEntity =====
        let history = NSEntityDescription()
        history.name = "PlayHistoryEntity"
        history.managedObjectClassName = NSStringFromClass(PlayHistoryEntity.self)

        history.properties = [
            attribute("trackID", .stringAttributeType, default: ""),
            attribute("title", .stringAttributeType, default: ""),
            attribute("artistName", .stringAttributeType, default: ""),
            attribute("albumTitle", .stringAttributeType, default: ""),
            attribute("playedAt", .dateAttributeType, default: Date()),
            attribute("playCountSnapshot", .integer32AttributeType, default: 0),
            attribute("duration", .doubleAttributeType, default: 0.0),
            attribute("isLocalAsset", .booleanAttributeType, default: false)
        ]

        // ===== CustomImageEntity =====
        let customImage = NSEntityDescription()
        customImage.name = "CustomImageEntity"
        customImage.managedObjectClassName = NSStringFromClass(CustomImageEntity.self)

        // imageData は Data 型でデフォルト値（空のData）を設定
        let imageData = NSAttributeDescription()
        imageData.name = "imageData"
        imageData.attributeType = .binaryDataAttributeType
        imageData.allowsExternalBinaryDataStorage = true
        imageData.isOptional = true  // ← これでCloudKit互換にもなる
        imageData.defaultValue = Data()

        customImage.properties = [
            attribute("key", .stringAttributeType, default: ""),
            attribute("type", .stringAttributeType, default: ""),
            imageData,
            attribute("updatedAt", .dateAttributeType, default: Date())
        ]

        // ===== PlayCountSnapshotEntity =====
        let snapshot = NSEntityDescription()
        snapshot.name = "PlayCountSnapshotEntity"
        snapshot.managedObjectClassName = NSStringFromClass(PlayCountSnapshotEntity.self)

        snapshot.properties = [
            attribute("trackID", .stringAttributeType, default: ""),
            attribute("playCount", .integer32AttributeType, default: 0),
            attribute("recordedAt", .dateAttributeType, default: Date())
        ]

        // ===== FavoriteEntity =====
        let favorite = NSEntityDescription()
        favorite.name = "FavoriteEntity"
        favorite.managedObjectClassName = NSStringFromClass(FavoriteEntity.self)

        favorite.properties = [
            attribute("trackID", .stringAttributeType, default: ""),
            attribute("title", .stringAttributeType, default: ""),
            attribute("artistName", .stringAttributeType, default: ""),
            attribute("albumTitle", .stringAttributeType, default: ""),
            attribute("favoritedAt", .dateAttributeType, default: Date())
        ]

        // ===== SearchHistoryEntity =====
        let searchHistory = NSEntityDescription()
        searchHistory.name = "SearchHistoryEntity"
        searchHistory.managedObjectClassName = NSStringFromClass(SearchHistoryEntity.self)

        searchHistory.properties = [
            attribute("query", .stringAttributeType, default: ""),
            attribute("searchedAt", .dateAttributeType, default: Date())
        ]

        model.entities = [history, customImage, snapshot, favorite, searchHistory]
        return model
    }

    /// 全属性を Optional + デフォルト値あり に設定
    /// （CloudKit対応も兼ねた設計、無料アカウント環境でも動作）
    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        default defaultValue: Any
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = true
        attr.defaultValue = defaultValue
        return attr
    }
}

extension URL {
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            return URL.documentsDirectory.appendingPathComponent("\(databaseName).sqlite")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
