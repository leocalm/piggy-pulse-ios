import Foundation
import SwiftUI

// MARK: - Watch Design Constants

enum WatchDesign {
    static let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255) // #8B7EC8
}

/// Simplified currency formatter for the watch.
/// Formats cent amounts (Int64) into display strings.
enum WatchCurrencyFormatter {

    /// Returns the user's configured currency code, defaulting to EUR.
    static var currencyCode: String {
        WatchKeychainHelper.read(.currencyCode) ?? "EUR"
    }

    /// Cached formatter — reconfigured only when currency code changes.
    private static var _cachedFormatter: NumberFormatter?
    private static var _cachedCode: String?

    private static var formatter: NumberFormatter {
        let code = currencyCode
        if let cached = _cachedFormatter, _cachedCode == code {
            return cached
        }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        _cachedFormatter = f
        _cachedCode = code
        return f
    }

    /// Formats a cent amount to a currency string.
    /// Example: 150034 with EUR -> "1,500.34" or "1.500,34" depending on locale.
    static func format(_ cents: Int64, compact: Bool = false) -> String {
        let value = Double(cents) / 100.0
        let f = formatter

        let savedFractionDigits = f.maximumFractionDigits
        if compact && abs(value) >= 1000 {
            f.maximumFractionDigits = 0
        }

        let result = f.string(from: NSNumber(value: value))
            ?? "\(currencyCode) \(String(format: "%.2f", value))"

        f.maximumFractionDigits = savedFractionDigits
        return result
    }

    /// Formats for complication display (shorter).
    static func formatCompact(_ cents: Int64) -> String {
        let value = Double(cents) / 100.0
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        let symbol = currencySymbol

        if absValue >= 1_000_000 {
            return "\(sign)\(symbol)\(String(format: "%.1fM", absValue / 1_000_000))"
        } else if absValue >= 1000 {
            return "\(sign)\(symbol)\(String(format: "%.1fK", absValue / 1000))"
        } else {
            return "\(sign)\(symbol)\(String(format: "%.0f", absValue))"
        }
    }

    /// Returns just the currency symbol.
    static var currencySymbol: String {
        formatter.currencySymbol ?? currencyCode
    }
}
