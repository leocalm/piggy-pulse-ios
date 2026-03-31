import SwiftUI
import UIKit

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

// MARK: - Legacy Color Aliases (backward compatibility)
// These map old static color names to v2 equivalents so existing screens
// continue to compile while we migrate them.

extension Color {
    static let ppPrimary = Color(rgb: UInt32(0x8B7EC8))
    static let ppCyan = Color(rgb: UInt32(0x7CA8C4))
    static let ppAmber = Color(rgb: UInt32(0xF0A25C))
    static let ppTeal = Color(rgb: UInt32(0x3D8B9E))
    static let ppDestructive = Color(rgb: UInt32(0xC4786A))
    static let ppBorderHover = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: UInt32(0x3A3850))
            : UIColor(rgb: UInt32(0xCBC8DA))
    })
}
