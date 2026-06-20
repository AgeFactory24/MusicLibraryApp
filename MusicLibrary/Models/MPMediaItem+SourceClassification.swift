import MediaPlayer

extension MPMediaItem {
    /// CDリップ（DRMなしローカル音源）かどうかを判定する。
    ///
    /// 判定の優先順位:
    /// 1. DRM あり → Apple Music サブスク → false
    /// 2. ローカルファイルあり、DRM なし → CDリップ → true
    /// 3. ローカルファイルなし、DRM なし:
    ///    - playbackStoreID あり → iTunes Match マッチ済み or サブスク追加 → false
    ///    - playbackStoreID なし → カタログ未登録のアップロード曲 → true
    var isLocalAsset: Bool {
        if hasProtectedAsset { return false }
        if assetURL != nil   { return true  }
        let storeID = value(forProperty: MPMediaItemPropertyPlaybackStoreID) as? String ?? ""
        return storeID.isEmpty
    }
}
