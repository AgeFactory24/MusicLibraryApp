//
//  DeezerSearchService.swift
//  MusicLibrary
//
//  Deezer APIから画像を取得（APIキー不要）
//  https://developers.deezer.com/api
//

import Foundation
import UIKit

actor DeezerSearchService {

    // MARK: - レスポンス

    private struct ArtistSearchResponse: Decodable {
        let data: [DeezerArtist]
        let total: Int?
    }

    private struct DeezerArtist: Decodable {
        let id: Int
        let name: String
        let picture: String?
        let pictureSmall: String?
        let pictureMedium: String?
        let pictureBig: String?
        let pictureXl: String?

        enum CodingKeys: String, CodingKey {
            case id, name, picture
            case pictureSmall = "picture_small"
            case pictureMedium = "picture_medium"
            case pictureBig = "picture_big"
            case pictureXl = "picture_xl"
        }
    }

    // MARK: - アーティスト画像URL取得

    /// アーティスト画像URLを取得（人物画像）
    func fetchArtistImageURL(artistName: String) async -> URL? {
        guard let encoded = artistName.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else {
            return nil
        }

        let urlString = "https://api.deezer.com/search/artist?q=\(encoded)&limit=5"

        print("🔍 [Deezer] アーティスト検索: \(artistName)")
        print("   URL: \(urlString)")

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("   ステータス: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else { return nil }
            }

            let decoded = try JSONDecoder().decode(ArtistSearchResponse.self, from: data)
            print("   ヒット数: \(decoded.data.count)")

            // 候補の中から最も名前一致度の高いものを選択
            let bestMatch = findBestMatch(candidates: decoded.data, target: artistName)
            guard let artist = bestMatch else {
                print("   一致するアーティストなし")
                return nil
            }

            print("   選択: \(artist.name) (id: \(artist.id))")

            // pictureXl > pictureBig > pictureMedium の順で取得
            // Deezerのデフォルト画像（"unknown"）は除外
            let imageURL = artist.pictureXl ?? artist.pictureBig ?? artist.pictureMedium

            guard let urlStr = imageURL,
                  !urlStr.contains("/artist//image"),
                  !urlStr.isEmpty else {
                print("   画像URLなし or デフォルト画像")
                return nil
            }

            print("✅ [Deezer] 画像URL: \(urlStr)")
            return URL(string: urlStr)

        } catch {
            print("❌ [Deezer] エラー: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 名前一致のスコアリング

    /// 検索結果から最も名前一致度の高いアーティストを選ぶ
    private func findBestMatch(candidates: [DeezerArtist], target: String) -> DeezerArtist? {
        guard !candidates.isEmpty else { return nil }

        let targetLower = target.lowercased().trimmingCharacters(in: .whitespaces)

        // 完全一致を優先
        if let exact = candidates.first(where: {
            $0.name.lowercased() == targetLower
        }) {
            return exact
        }

        // 大文字小文字無視で含まれているか
        if let partial = candidates.first(where: {
            $0.name.lowercased().contains(targetLower) ||
            targetLower.contains($0.name.lowercased())
        }) {
            return partial
        }

        // どれもヒットしなければ先頭を返す（信頼度低いが、無いよりマシ）
        return candidates.first
    }

    // MARK: - 画像ダウンロード

    func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                print("✅ [Deezer] 画像ダウンロード成功: \(data.count) bytes")
                return image
            } else {
                print("❌ [Deezer] 画像データ変換失敗")
                return nil
            }
        } catch {
            print("❌ [Deezer] ダウンロード失敗: \(error.localizedDescription)")
            return nil
        }
    }
}
