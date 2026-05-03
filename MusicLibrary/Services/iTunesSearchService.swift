//
//  iTunesSearchService.swift
//  MusicLibrary
//
//  iTunes Search APIから画像を取得（APIキー不要）
//

import Foundation
import UIKit

actor iTunesSearchService {

    // MARK: - レスポンス

    private struct SearchResponse: Decodable {
        let resultCount: Int
        let results: [SearchResult]
    }

    private struct SearchResult: Decodable {
        let artistName: String?
        let collectionName: String?
        let artworkUrl100: String?
        let artworkUrl60: String?
    }

    // MARK: - アーティスト画像URL取得

    func fetchArtistImageURL(artistName: String) async -> URL? {
        // 戦略：複数の検索方法を試してフォールバック
        // ① musicArtistエンティティで検索
        if let url = await searchArtist(term: artistName) {
            return url
        }

        // ② albumエンティティでアーティスト検索（アーティスト画像が無い場合の代替）
        if let url = await searchAlbumByArtist(term: artistName) {
            return url
        }

        print("❌ [iTunes] アーティスト画像取得失敗: \(artistName)")
        return nil
    }

    /// musicArtistエンティティで検索
    private func searchArtist(term: String) async -> URL? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "https://itunes.apple.com/search"
            + "?term=\(encoded)"
            + "&entity=musicArtist"
            + "&limit=1"
            + "&country=JP"

        print("🔍 [iTunes] アーティスト検索: \(term)")
        print("   URL: \(urlString)")

        return await fetchAndExtractURL(from: urlString)
    }

    /// albumエンティティで検索（アーティスト画像のフォールバック）
    /// アルバムジャケットだが、アーティスト画像が取れないケースの代替として使用
    private func searchAlbumByArtist(term: String) async -> URL? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "https://itunes.apple.com/search"
            + "?term=\(encoded)"
            + "&entity=album"
            + "&attribute=artistTerm"
            + "&limit=1"
            + "&country=JP"

        print("🔍 [iTunes] アルバム経由でアーティスト検索: \(term)")
        return await fetchAndExtractURL(from: urlString)
    }

    // MARK: - アルバム画像URL取得

    func fetchAlbumImageURL(artistName: String, albumTitle: String) async -> URL? {
        let term = "\(artistName) \(albumTitle)"
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "https://itunes.apple.com/search"
            + "?term=\(encoded)"
            + "&entity=album"
            + "&limit=1"
            + "&country=JP"

        print("🔍 [iTunes] アルバム検索: \(term)")
        return await fetchAndExtractURL(from: urlString)
    }

    // MARK: - 共通: API呼び出し → URL抽出

    private func fetchAndExtractURL(from urlString: String) async -> URL? {
        guard let url = URL(string: urlString) else {
            print("❌ [iTunes] 無効なURL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // HTTPステータス確認
            if let httpResponse = response as? HTTPURLResponse {
                print("   ステータス: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    return nil
                }
            }

            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            print("   ヒット数: \(decoded.resultCount)")

            guard let firstResult = decoded.results.first else {
                print("   結果なし")
                return nil
            }

            // artworkUrl100 を最優先、なければ artworkUrl60
            let raw = firstResult.artworkUrl100 ?? firstResult.artworkUrl60
            guard let raw else {
                print("   artworkUrlなし")
                return nil
            }

            // 100x100 → 600x600 に拡大（高解像度版URL）
            let highRes = raw
                .replacingOccurrences(of: "100x100bb", with: "600x600bb")
                .replacingOccurrences(of: "60x60bb", with: "600x600bb")

            print("✅ [iTunes] 画像URL: \(highRes)")
            return URL(string: highRes)

        } catch {
            print("❌ [iTunes] エラー: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 画像ダウンロード

    func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                print("✅ [iTunes] 画像ダウンロード成功: \(data.count) bytes")
                return image
            } else {
                print("❌ [iTunes] 画像データ変換失敗")
                return nil
            }
        } catch {
            print("❌ [iTunes] ダウンロード失敗: \(error.localizedDescription)")
            return nil
        }
    }
}
