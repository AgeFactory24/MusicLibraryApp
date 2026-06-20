// AppTheme.swift
// MusicLibrary — デザイントークン統一

import SwiftUI

// MARK: - AppTheme

enum AppTheme {

    // MARK: Colors
    enum Colors {
        /// メインアクセント（ピンク）
        static let accent: Color       = .pink
        /// グラデーション終端（パープル）
        static let accentGrad: Color   = .purple
        /// カード背景
        static let card: Color         = Color(.secondarySystemBackground)
        /// サブカード背景
        static let cardAlt: Color      = Color(.tertiarySystemBackground)
        /// ページ背景
        static let background: Color   = Color(.systemBackground)
        /// アクセント再生回数
        static let plays: Color        = .pink
        /// 1位
        static let rankGold: Color     = .yellow
        /// 2位
        static let rankSilver: Color   = Color(.systemGray)
        /// 3位
        static let rankBronze: Color   = .orange
    }

    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat  =  4
        static let sm: CGFloat  =  8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        /// 画面左右の標準パディング
        static let screen: CGFloat = 16
    }

    // MARK: Corner Radius
    enum Radius {
        static let xs: CGFloat   =  6
        static let sm: CGFloat   =  8
        static let md: CGFloat   = 12
        static let card: CGFloat = 16
        static let lg: CGFloat   = 20
        static let xl: CGFloat   = 24
    }

    // MARK: Typography
    enum Typography {
        static let heroNumber: Font  = .system(size: 48, weight: .black, design: .rounded)
        static let bigNumber: Font   = .system(size: 32, weight: .black, design: .rounded)
        static let rankNumber: Font  = .system(.headline, design: .rounded).weight(.black)
        static let sectionTitle: Font = .title3.bold()
        static let cardLabel: Font   = .subheadline.bold()
        static let cardSub: Font     = .caption
        static let tag: Font         = .caption.bold()
    }

    // MARK: Shadow
    enum Shadow {
        static let cardRadius: CGFloat   = 4
        static let cardY: CGFloat        = 2
        static let cardOpacity: Double   = 0.08
        static let floatRadius: CGFloat  = 16
        static let floatY: CGFloat       = 6
        static let floatOpacity: Double  = 0.18
    }
}

// MARK: - View Extensions

extension View {

    /// アプリ標準カードスタイル（背景 + 角丸）
    func appCard(radius: CGFloat = AppTheme.Radius.card) -> some View {
        self
            .background(AppTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    /// アクセントカプセルラベル
    func appCapsuleLabel() -> some View {
        self
            .font(AppTheme.Typography.tag)
            .foregroundStyle(AppTheme.Colors.accent)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(AppTheme.Colors.accent.opacity(0.12))
            .clipShape(Capsule())
    }

    /// 標準画面横パディング
    func appHorizontalPadding() -> some View {
        self.padding(.horizontal, AppTheme.Spacing.screen)
    }
}
