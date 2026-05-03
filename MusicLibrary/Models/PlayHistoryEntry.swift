//
//  PlayHistoryEntry.swift
//  MusicLibrary
//

import Foundation
import CoreData

// MARK: - Core Data Entities

@objc(PlayHistoryEntity)
public class PlayHistoryEntity: NSManagedObject {
    @NSManaged public var trackID: String
    @NSManaged public var title: String
    @NSManaged public var artistName: String
    @NSManaged public var albumTitle: String
    @NSManaged public var playedAt: Date
    @NSManaged public var playCountSnapshot: Int32
    @NSManaged public var duration: Double
    @NSManaged public var isLocalAsset: Bool
}

@objc(CustomImageEntity)
public class CustomImageEntity: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var type: String
    @NSManaged public var imageData: Data
    @NSManaged public var updatedAt: Date
}

@objc(PlayCountSnapshotEntity)
public class PlayCountSnapshotEntity: NSManagedObject {
    @NSManaged public var trackID: String
    @NSManaged public var playCount: Int32
    @NSManaged public var recordedAt: Date
}

@objc(FavoriteEntity)
public class FavoriteEntity: NSManagedObject {
    @NSManaged public var trackID: String
    @NSManaged public var title: String
    @NSManaged public var artistName: String
    @NSManaged public var albumTitle: String
    @NSManaged public var favoritedAt: Date
}

@objc(SearchHistoryEntity)
public class SearchHistoryEntity: NSManagedObject {
    @NSManaged public var query: String
    @NSManaged public var searchedAt: Date
}

// MARK: - 表示用構造体

struct PlayHistoryEntry: Identifiable, Hashable {
    let id: NSManagedObjectID
    let trackID: String
    let title: String
    let artistName: String
    let albumTitle: String
    let playedAt: Date
    let duration: TimeInterval
    let isLocalAsset: Bool
}
