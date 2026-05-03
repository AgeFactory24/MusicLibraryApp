//
//  AuthorizationView.swift
//  MusicLibrary
//

import SwiftUI

struct AuthorizationView: View {
    @EnvironmentObject var authService: MusicAuthService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundStyle(.pink)

            VStack(spacing: 12) {
                Text("MusicLibrary")
                    .font(.largeTitle.bold())

                Text("あなたの音楽ライブラリを分析するために\nApple Musicへのアクセスが必要です")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await authService.requestAuthorization() }
            } label: {
                Text("Apple Music を連携する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}
