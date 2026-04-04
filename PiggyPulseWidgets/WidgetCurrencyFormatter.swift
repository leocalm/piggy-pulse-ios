import Foundation

enum WidgetCurrencyFormatter {

    static var currencyCode: String {
        WidgetTokenStore.read(.currencyCode) ?? "EUR"
    }

    nonisolated(unsafe) private static var _cachedFormatter: NumberFormatter?
    nonisolated(unsafe) private static var _cachedCode: String?

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

    static func format(_ cents: Int64, compact: Bool = false) -> String {
        let value = Double(cents) / 100.0
        let f = formatter

        let saved = f.maximumFractionDigits
        if compact && abs(value) >= 1000 {
            f.maximumFractionDigits = 0
        }

        let result = f.string(from: NSNumber(value: value))
            ?? "\(currencyCode) \(String(format: "%.2f", value))"

        f.maximumFractionDigits = saved
        return result
    }

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

    static var currencySymbol: String {
        formatter.currencySymbol ?? currencyCode
    }
}
