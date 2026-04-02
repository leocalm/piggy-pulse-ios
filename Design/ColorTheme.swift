import SwiftUI

// MARK: - Theme Identifiers

enum ColorTheme: String, CaseIterable, Codable, Identifiable {
    case nebula
    case sunrise
    case sageStone = "sage_stone"
    case deepOcean = "deep_ocean"
    case warmRose = "warm_rose"
    case moonlit

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nebula:     return String(localized: "theme.nebula")
        case .sunrise:    return String(localized: "theme.sunrise")
        case .sageStone:  return String(localized: "theme.sageStone")
        case .deepOcean:  return String(localized: "theme.deepOcean")
        case .warmRose:   return String(localized: "theme.warmRose")
        case .moonlit:    return String(localized: "theme.moonlit")
        }
    }

    /// Asset name for the per-theme coin logo
    var coinLogoName: String { "piggy-coin-\(rawValue)" }

    /// Alternate app icon name (nil = default/nebula)
    var alternateAppIconName: String? {
        self == .nebula ? nil : "AppIcon-\(rawValue)"
    }

    var description: String {
        switch self {
        case .nebula:     return String(localized: "theme.nebula.desc")
        case .sunrise:    return String(localized: "theme.sunrise.desc")
        case .sageStone:  return String(localized: "theme.sageStone.desc")
        case .deepOcean:  return String(localized: "theme.deepOcean.desc")
        case .warmRose:   return String(localized: "theme.warmRose.desc")
        case .moonlit:    return String(localized: "theme.moonlit.desc")
        }
    }
}

// MARK: - Theme Accent Colors

struct ThemeAccents {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let destructive: Color
    let gradient: [Color]
    let data: [Color]
}

// MARK: - Accent Definitions

extension ColorTheme {
    var accents: ThemeAccents {
        switch self {
        case .nebula:
            return ThemeAccents(
                primary: Color(rgb: 0x8B7EC8),
                secondary: Color(rgb: 0xC48BA0),
                tertiary: Color(rgb: 0x7CA8C4),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0x8B7EC8), Color(rgb: 0xC48BA0)],
                data: buildDataPalette([0x8B7EC8, 0xC48BA0, 0x7CA8C4])
            )
        case .sunrise:
            return ThemeAccents(
                primary: Color(rgb: 0x4A7CFF),
                secondary: Color(rgb: 0xF0A25C),
                tertiary: Color(rgb: 0x9B8AE0),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0x4A7CFF), Color(rgb: 0xF0A25C)],
                data: buildDataPalette([0x4A7CFF, 0xF0A25C, 0x9B8AE0])
            )
        case .sageStone:
            return ThemeAccents(
                primary: Color(rgb: 0x6B8F71),
                secondary: Color(rgb: 0xB89F7E),
                tertiary: Color(rgb: 0x7A9EBA),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0x6B8F71), Color(rgb: 0xB89F7E)],
                data: buildDataPalette([0x6B8F71, 0xB89F7E, 0x7A9EBA])
            )
        case .deepOcean:
            return ThemeAccents(
                primary: Color(rgb: 0x3D8B9E),
                secondary: Color(rgb: 0xD4A574),
                tertiary: Color(rgb: 0x8E7EBD),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0x3D8B9E), Color(rgb: 0xD4A574)],
                data: buildDataPalette([0x3D8B9E, 0xD4A574, 0x8E7EBD])
            )
        case .warmRose:
            return ThemeAccents(
                primary: Color(rgb: 0xB07592),
                secondary: Color(rgb: 0xC4A882),
                tertiary: Color(rgb: 0x7C9EB8),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0xB07592), Color(rgb: 0xC4A882)],
                data: buildDataPalette([0xB07592, 0xC4A882, 0x7C9EB8])
            )
        case .moonlit:
            return ThemeAccents(
                primary: Color(rgb: 0x8B7EC8),
                secondary: Color(rgb: 0xA8B4C4),
                tertiary: Color(rgb: 0x7AADCF),
                destructive: .sharedDestructive,
                gradient: [Color(rgb: 0x8B7EC8), Color(rgb: 0xA8B4C4)],
                data: buildDataPalette([0x8B7EC8, 0xA8B4C4, 0x7AADCF])
            )
        }
    }
}

// MARK: - Shared Surface Colors (all themes)

extension Color {
    // Surfaces — shared across all themes
    static let ppBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x0D0C14)
            : UIColor(rgb: 0xF5F4FA)
    })
    static let ppSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x161520)
            : UIColor(rgb: 0xEDEBF4)
    })
    static let ppCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x161520)
            : UIColor(rgb: 0xE4E1EE)
    })
    static let ppElevated = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x1E1D2B)
            : UIColor(rgb: 0xEDEBF4)
    })
    static let ppBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x28263A)
            : UIColor(rgb: 0xDBD8E6)
    })

    // Text
    static let ppTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : UIColor(rgb: 0x1A1A2E)
    })
    static let ppTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x8B89A0)
            : UIColor(rgb: 0x6B697E)
    })
    static let ppTextTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x5A5870)
            : UIColor(rgb: 0x9896AA)
    })

    // Shared destructive
    static let sharedDestructive = Color(rgb: 0xC4786A)
}

// MARK: - Hex Color Initializers

extension Color {
    init(rgb: UInt32) {
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Data Palette Builder

private func buildDataPalette(_ hexValues: [UInt32]) -> [Color] {
    let base = hexValues.map { Color(rgb: $0) }
    var palette = base
    var idx = 0
    while palette.count < 8 {
        // Generate lighter tints by increasing HSL lightness (matches web tokens.ts)
        let sourceHex = hexValues[idx % hexValues.count]
        let offset = 15 + idx * 5
        palette.append(tintColor(sourceHex, lightnessOffset: offset))
        idx += 1
    }
    return palette
}

/// Shift HSL lightness of a hex color by the given percentage points.
/// Uses proper HSL→RGB conversion (not HSB) to match the web tokens.ts implementation.
private func tintColor(_ hex: UInt32, lightnessOffset: Int) -> Color {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255

    // RGB → HSL
    let maxC = max(r, g, b)
    let minC = min(r, g, b)
    var h = 0.0, s = 0.0
    let l = (maxC + minC) / 2

    if maxC != minC {
        let d = maxC - minC
        s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
        if maxC == r {
            h = ((g - b) / d + (g < b ? 6 : 0)) / 6
        } else if maxC == g {
            h = ((b - r) / d + 2) / 6
        } else {
            h = ((r - g) / d + 4) / 6
        }
    }

    let newL = min(0.9, max(0.0, l + Double(lightnessOffset) / 100.0))

    // HSL → RGB (proper conversion, not HSB)
    let sN = s
    let a = sN * min(newL, 1 - newL)
    func f(_ n: Double) -> Double {
        let k = (n + h * 12).truncatingRemainder(dividingBy: 12)
        return newL - a * max(min(k - 3, min(9 - k, 1)), -1)
    }
    return Color(red: f(0), green: f(8), blue: f(4))
}
