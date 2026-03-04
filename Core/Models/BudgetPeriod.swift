import Foundation

struct BudgetPeriod: Codable, Identifiable {
    let id: UUID
    let name: String
    let startDate: String
    let endDate: String
    let budgetAmount: Decimal?

    enum CodingKeys: String, CodingKey {
        case id, name
        case startDate = "start_date"
        case endDate = "end_date"
        case budgetAmount = "budget_amount"
    }
}
