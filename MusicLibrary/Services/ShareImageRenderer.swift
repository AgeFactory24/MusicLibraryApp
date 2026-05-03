//
//  ShareImageRenderer.swift
//  MusicLibrary
//

import SwiftUI
import UIKit

@MainActor
final class ShareImageRenderer {

    /// SwiftUIビューをUIImageに変換
    func render<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
