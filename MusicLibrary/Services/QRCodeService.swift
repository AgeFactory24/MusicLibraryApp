//
//  QRCodeService.swift
//  MusicLibrary
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum QRCodeService {

    // MARK: - エンコード（JSON → zlib圧縮 → Base64URL → QR）

    static func encode(_ profile: ListeningProfile) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let json = try? encoder.encode(profile) else { return nil }
        guard let compressed = try? (json as NSData).compressed(using: .zlib) as Data else { return nil }
        return toBase64URL(compressed)
    }

    static func decode(_ base64url: String) -> ListeningProfile? {
        guard let compressed = fromBase64URL(base64url) else { return nil }
        guard let json = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(ListeningProfile.self, from: json)
    }

    // MARK: - QRコード画像生成

    static func generateQRImage(from string: String, size: CGFloat = 200) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - 共有画像へQRを右下合成

    static func compositeQR(onto image: UIImage, qrImage: UIImage, marginRatio: CGFloat = 0.04) -> UIImage {
        let qrSide = image.size.width * 0.18
        let margin = image.size.width * marginRatio
        let origin = CGPoint(
            x: image.size.width - qrSide - margin,
            y: image.size.height - qrSide - margin
        )
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            // 白背景パディング
            let padding: CGFloat = 6
            let bgRect = CGRect(x: origin.x - padding, y: origin.y - padding,
                                width: qrSide + padding * 2, height: qrSide + padding * 2)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: 4).fill()
            qrImage.draw(in: CGRect(origin: origin, size: CGSize(width: qrSide, height: qrSide)))
        }
    }

    // MARK: - Helpers

    private static func toBase64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func fromBase64URL(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let rem = base64.count % 4
        if rem > 0 { base64 += String(repeating: "=", count: 4 - rem) }
        return Data(base64Encoded: base64)
    }
}
