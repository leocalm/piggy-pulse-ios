import Foundation

private var currencyFormatterCache: [String: NumberFormatter] = [:]
private let currencyFormatterLock = NSLock()

func formatCurrency(_ cents: Int64, code: String = "EUR") -> String {
    let value = Double(cents) / 100.0
    let fmt: NumberFormatter = {
        currencyFormatterLock.lock()
        defer { currencyFormatterLock.unlock() }
        if let cached = currencyFormatterCache[code] {
            return cached
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        currencyFormatterCache[code] = formatter
        return formatter
    }()
    return fmt.string(from: NSNumber(value: value)) ?? "\(code) 0.00"
}
