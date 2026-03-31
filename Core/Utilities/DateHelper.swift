import Foundation

/// Formats an ISO date string (e.g. "2026-03-15" or "2026-03-15T10:30:00Z") into a
/// user-friendly localized date string (e.g. "Mar 15, 2026").
func formatDateString(_ isoString: String) -> String {
    let trimmed = isoString.trimmingCharacters(in: .whitespaces)
    if let date = DateHelper.iso8601Full.date(from: trimmed) {
        return DateHelper.display.string(from: date)
    }
    if let date = DateHelper.iso8601Date.date(from: trimmed) {
        return DateHelper.display.string(from: date)
    }
    // Return original string if parsing fails
    return isoString
}

private enum DateHelper {
    static let iso8601Full: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }()

    static let iso8601Date: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()

    static let display: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt
    }()
}
