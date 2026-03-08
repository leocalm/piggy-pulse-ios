import SwiftUI

// MARK: - Colors

extension Color {
    // Backgrounds
    static let ppBackground = Color(red: 0.04, green: 0.05, blue: 0.07)       // #0a0e14
    static let ppSurface = Color(red: 0.06, green: 0.07, blue: 0.10)          // #0f1319
    static let ppCard = Color(red: 0.08, green: 0.11, blue: 0.15)             // #151b26

    // Brand
    static let ppPrimary = Color(red: 0.00, green: 0.48, blue: 1.00)          // #007AFF (Apple Blue)
    static let ppCyan = Color(red: 0.00, green: 0.83, blue: 1.00)             // #00d4ff
    static let ppAmber = Color(red: 1.00, green: 0.66, blue: 0.25)            // #ffa940
    static let ppTeal = Color(red: 0.00, green: 0.71, blue: 0.78)             // #00b4c8

    // Text
    static let ppTextPrimary = Color.white
    static let ppTextSecondary = Color(red: 0.51, green: 0.55, blue: 0.62)    // #828c9e
    static let ppTextTertiary = Color(red: 0.35, green: 0.38, blue: 0.45)     // #5a6272

    // Borders
    static let ppBorder = Color.white.opacity(0.06)
    static let ppBorderHover = Color.white.opacity(0.12)

    // System (HIG only — not for financial data)
    static let ppDestructive = Color(red: 0.97, green: 0.32, blue: 0.29)      // #f85149
}

// MARK: - Typography

extension Font {
    static let ppLargeTitle = Font.system(size: 28, weight: .bold)
    static let ppTitle = Font.system(size: 22, weight: .bold)
    static let ppTitle3 = Font.system(size: 18, weight: .semibold)
    static let ppHeadline = Font.system(size: 16, weight: .semibold)
    static let ppBody = Font.system(size: 16, weight: .regular)
    static let ppCallout = Font.system(size: 14, weight: .regular)
    static let ppCaption = Font.system(size: 12, weight: .medium)
    static let ppOverline = Font.system(size: 11, weight: .bold)

    // Monospaced for amounts
    static let ppAmount = Font.system(size: 32, weight: .bold, design: .rounded)
    static let ppAmountSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
}

// MARK: - Spacing

enum PPSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Radii

enum PPRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}
