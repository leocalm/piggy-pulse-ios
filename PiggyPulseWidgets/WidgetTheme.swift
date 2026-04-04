import SwiftUI

/// Lightweight theme colors for widget extension.
/// Mirrors the primary/secondary/gradient from ColorTheme.swift without UIKit dependency.
enum WidgetTheme {

    struct Accents {
        let primary: Color
        let secondary: Color
        let gradient: [Color]
    }

    static var current: Accents {
        let theme = WidgetTokenStore.read(.colorTheme) ?? "nebula"
        return accents(for: theme)
    }

    static func accents(for theme: String) -> Accents {
        switch theme {
        case "nebula":
            return Accents(
                primary: Color(red: 0x8B/255, green: 0x7E/255, blue: 0xC8/255),
                secondary: Color(red: 0xC4/255, green: 0x8B/255, blue: 0xA0/255),
                gradient: [Color(red: 0x8B/255, green: 0x7E/255, blue: 0xC8/255), Color(red: 0xC4/255, green: 0x8B/255, blue: 0xA0/255)]
            )
        case "sunrise":
            return Accents(
                primary: Color(red: 0x4A/255, green: 0x7C/255, blue: 0xFF/255),
                secondary: Color(red: 0xF0/255, green: 0xA2/255, blue: 0x5C/255),
                gradient: [Color(red: 0x4A/255, green: 0x7C/255, blue: 0xFF/255), Color(red: 0xF0/255, green: 0xA2/255, blue: 0x5C/255)]
            )
        case "neon":
            return Accents(
                primary: Color(red: 0x00/255, green: 0xF0/255, blue: 0xFF/255),
                secondary: Color(red: 0xFF/255, green: 0x00/255, blue: 0xE5/255),
                gradient: [Color(red: 0x00/255, green: 0xF0/255, blue: 0xFF/255), Color(red: 0xFF/255, green: 0x00/255, blue: 0xE5/255)]
            )
        case "tropical":
            return Accents(
                primary: Color(red: 0xFF/255, green: 0x6B/255, blue: 0x6B/255),
                secondary: Color(red: 0x00/255, green: 0xCC/255, blue: 0xB3/255),
                gradient: [Color(red: 0xFF/255, green: 0x6B/255, blue: 0x6B/255), Color(red: 0x00/255, green: 0xCC/255, blue: 0xB3/255)]
            )
        case "candy_pop":
            return Accents(
                primary: Color(red: 0xFF/255, green: 0x47/255, blue: 0x9C/255),
                secondary: Color(red: 0x00/255, green: 0xC2/255, blue: 0xFF/255),
                gradient: [Color(red: 0xFF/255, green: 0x47/255, blue: 0x9C/255), Color(red: 0x00/255, green: 0xC2/255, blue: 0xFF/255)]
            )
        case "moonlit":
            return Accents(
                primary: Color(red: 0x8B/255, green: 0x7E/255, blue: 0xC8/255),
                secondary: Color(red: 0xA8/255, green: 0xB4/255, blue: 0xC4/255),
                gradient: [Color(red: 0x8B/255, green: 0x7E/255, blue: 0xC8/255), Color(red: 0xA8/255, green: 0xB4/255, blue: 0xC4/255)]
            )
        default:
            return accents(for: "nebula")
        }
    }
}
