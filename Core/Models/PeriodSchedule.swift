import Foundation

struct PeriodSchedule: Codable, Identifiable {
    let id: UUID
    let startDay: Int
    let durationValue: Int
    let durationUnit: String
    let saturdayAdjustment: String
    let sundayAdjustment: String
    let namePattern: String
    let generateAhead: Int
}
