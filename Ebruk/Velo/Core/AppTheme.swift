//
//  AppTheme.swift
//  Velo
//
//  Velo 品牌色：深海军底、电青主色、活力橙辅色（与 Rahmi 霓虹粉紫区分）。
//

import SwiftUI

enum AppTheme {
    /// 深海军蓝底 `#0A1628`
    static let background = Color(red: 10 / 255, green: 22 / 255, blue: 40 / 255)
    static let surfaceDim = Color(red: 10 / 255, green: 22 / 255, blue: 40 / 255)
    static let surfaceContainer = Color(red: 16 / 255, green: 32 / 255, blue: 56 / 255)
    static let surfaceContainerLow = Color(red: 13 / 255, green: 27 / 255, blue: 48 / 255)
    static let surfaceContainerHigh = Color(red: 22 / 255, green: 42 / 255, blue: 68 / 255)
    static let surfaceContainerHighest = Color(red: 28 / 255, green: 52 / 255, blue: 82 / 255)
    static let surfaceVariant = Color(red: 28 / 255, green: 52 / 255, blue: 82 / 255)

    /// 主品牌：电青 `#00D4FF`
    static let primary = Color(red: 0 / 255, green: 212 / 255, blue: 255 / 255)
    /// 深青，渐变收束
    static let primaryDim = Color(red: 8 / 255, green: 145 / 255, blue: 178 / 255)
    /// 金币 / 金额高亮：活力橙 `#FF6B35`
    static let secondary = Color(red: 255 / 255, green: 107 / 255, blue: 53 / 255)
    static let onSurface = Color(red: 236 / 255, green: 244 / 255, blue: 252 / 255)
    static let onSurfaceVariant = Color(red: 148 / 255, green: 180 / 255, blue: 210 / 255)
    static let outlineVariant = Color(red: 56 / 255, green: 88 / 255, blue: 120 / 255)

    static let neonPink = Color(red: 255 / 255, green: 107 / 255, blue: 120 / 255)
    static let accentCyan = Color(red: 45 / 255, green: 212 / 255, blue: 191 / 255)

    static let tabBarBackground = Color(red: 12 / 255, green: 26 / 255, blue: 46 / 255).opacity(0.94)

    static let primaryGradient = LinearGradient(
        colors: [accentCyan.opacity(0.92), primary, primaryDim],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumButtonGradient = LinearGradient(
        colors: [accentCyan, primary, primaryDim],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
