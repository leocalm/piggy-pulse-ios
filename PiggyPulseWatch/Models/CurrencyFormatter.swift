import Foundation

/// Simplified currency formatter for the watch.
/// Formats cent amounts (Int64) into display strings.
enum WatchCurrencyFormatter {

    /// Returns the user's configured currency code, defaulting to EUR.
    static var currencyCode: String {
        WatchKeychainHelper.read(.currencyCode) ?? "EUR"
    }

    /// Formats a cent amount to a currency string.
    /// Example: 150034 with EUR -> "1,500.34" or "1.500,34" depending on locale.
    static func format(_ cents: Int64, compact: Bool = false) -> String {
        let value = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        if compact && abs(value) >= 1000 {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: value))
            ?? "\(currencyCode) \(String(format: "%.2f", value))"
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? currencyCode
    }
}
