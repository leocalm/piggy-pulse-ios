import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    // Brand (unchanged — work on both backgrounds)
    static let ppPrimary = Color(red: 0.00, green: 0.48, blue: 1.00)      // #007AFF
    static let ppCyan = Color(red: 0.00, green: 0.83, blue: 1.00)         // #00d4ff
    static let ppAmber = Color(red: 1.00, green: 0.66, blue: 0.25)        // #ffa940
    static let ppTeal = Color(red: 0.00, green: 0.71, blue: 0.78)         // #00b4c8
    static let ppDestructive = Color(red: 0.97, green: 0.32, blue: 0.29)  // #f85149

    // Adaptive backgrounds
    static let ppBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)   // #0a0e14
            : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1)   // #F2F4F7
    })
    static let ppSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)   // #0f1319
            : UIColor.white
    })
    static let ppCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 1)   // #151b26
            : UIColor.white
    })
    static let ppTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
    })
    static let ppTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.51, green: 0.55, blue: 0.62, alpha: 1)   // #828c9e
            : UIColor(red: 0.35, green: 0.38, blue: 0.45, alpha: 1)   // #5a6272
    })
    static let ppTextTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.38, blue: 0.45, alpha: 1)   // #5a6272
            : UIColor(red: 0.51, green: 0.55, blue: 0.62, alpha: 1)   // #828c9e
    })
    static let ppBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let ppBorderHover = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.15)
    })
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
