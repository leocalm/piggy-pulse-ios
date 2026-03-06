import Foundation

func formatCurrency(_ cents: Int64, code: String = "EUR") -> String {
    let value = Double(cents) / 100.0
    let fmt = NumberFormatter()
    fmt.numberStyle = .currency
    fmt.currencyCode = code
    fmt.maximumFractionDigits = 2
    fmt.minimumFractionDigits = 2
    return fmt.string(from: NSNumber(value: value)) ?? "\(code) 0.00"
}
