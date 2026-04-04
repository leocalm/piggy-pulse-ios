import Foundation

enum WidgetCurrencyFormatter {

    static var currencyCode: String {
        WidgetTokenStore.read(.currencyCode) ?? "EUR"
    }

    private static func makeFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f
    }

    static func format(_ cents: Int64, compact: Bool = false) -> String {
        let value = Double(cents) / 100.0
        let f = makeFormatter()

        if compact && abs(value) >= 1000 {
            f.maximumFractionDigits = 0
        }

        return f.string(from: NSNumber(value: value))
            ?? "\(currencyCode) \(String(format: "%.2f", value))"
    }

    static func formatCompact(_ cents: Int64) -> String {
        let value = Double(cents) / 100.0
        let absValue = abs(value)
        let f = makeFormatter()
        f.maximumFractionDigits = 0

        if absValue >= 1_000_000 {
            f.maximumFractionDigits = 1
            f.multiplier = NSNumber(value: 0.000001)
            f.positiveSuffix = "M"
            f.negativeSuffix = "M"
        } else if absValue >= 1000 {
            f.maximumFractionDigits = 1
            f.multiplier = NSNumber(value: 0.001)
            f.positiveSuffix = "K"
            f.negativeSuffix = "K"
        }

        return f.string(from: NSNumber(value: value))
            ?? "\(currencyCode) \(String(format: "%.0f", value))"
    }

    static var currencySymbol: String {
        makeFormatter().currencySymbol ?? currencyCode
    }
}
