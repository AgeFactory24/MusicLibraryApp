// SplashView.swift
// MusicLibrary

import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool
    @State private var iconScale: CGFloat = 0.55
    @State private var contentOpacity: Double = 0
    @State private var isFadingOut = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("AppLogoImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .pink.opacity(0.5), radius: 28, y: 10)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .scaleEffect(iconScale)

                Text("MusicLibrary")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .opacity(isFadingOut ? 0 : contentOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                iconScale = 1.0
                contentOpacity = 1.0
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_350_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    isFadingOut = true
                }
                try? await Task.sleep(nanoseconds: 360_000_000)
                isShowing = false
            }
        }
    }
}
