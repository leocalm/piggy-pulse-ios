import Foundation

struct PeriodSchedule: Codable, Identifiable {
    let id: UUID
    let scheduleType: String          // "manual" | "automatic"

    // Automatic schedule fields (optional — only present when scheduleType == "automatic")
    let recurrenceMethod: String?     // "dayOfMonth" | "businessDay" | "dayOfWeek"
    let startDayOfTheMonth: Int?
    let periodDuration: Int?
    let durationUnit: String?
    let saturdayPolicy: String?
    let sundayPolicy: String?
    let namePattern: String?
    let generateAhead: Int?

    // MARK: - Backward compatibility

    var startDay: Int { startDayOfTheMonth ?? 1 }
    var durationValue: Int { periodDuration ?? 1 }
    var saturdayAdjustment: String { saturdayPolicy ?? "keep" }
    var sundayAdjustment: String { sundayPolicy ?? "keep" }
}
