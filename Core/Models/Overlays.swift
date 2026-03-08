import Foundation

struct OverlayRules: Codable {
    let accountIds: [UUID]
    let categoryIds: [UUID]
    let vendorIds: [UUID]

    init(accountIds: [UUID] = [], categoryIds: [UUID] = [], vendorIds: [UUID] = []) {
        self.accountIds = accountIds
        self.categoryIds = categoryIds
        self.vendorIds = vendorIds
    }
}

struct OverlayCategoryCap: Codable {
    let categoryId: UUID
    let capAmount: Int64
}

struct OverlayItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String?
    let startDate: String
    let endDate: String
    let inclusionMode: String
    let totalCapAmount: Int64?
    let spentAmount: Int64
    let transactionCount: Int64
    let rules: OverlayRules?
    let categoryCaps: [OverlayCategoryCap]?

    var status: OverlayStatus {
        let today = Date()
        guard let start = DateFormatter.apiDate.date(from: startDate),
              let end = DateFormatter.apiDate.date(from: endDate) else { return .unknown }
        if today >= start && today <= end { return .active }
        if today < start { return .upcoming }
        return .ended
    }

    var remainingAmount: Int64? {
        guard let cap = totalCapAmount else { return nil }
        return cap - spentAmount
    }

    var spentPercentage: Double {
        guard let cap = totalCapAmount, cap > 0 else { return 0 }
        return Double(spentAmount) / Double(cap)
    }

    var daysRemaining: Int {
        guard let end = DateFormatter.apiDate.date(from: endDate) else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
    }
}

enum OverlayStatus {
    case active, upcoming, ended, unknown
}

// MARK: - Inclusion Mode

enum OverlayInclusionMode: String, Codable, CaseIterable {
    case manual = "manual"
    case rulesBased = "rules"
    case includeAll = "all"
}

// MARK: - Create/Update Request

struct OverlayRequest: Encodable {
    let name: String
    let icon: String?
    let startDate: String
    let endDate: String
    let inclusionMode: String
    let totalCapAmount: Int64?
    let rules: OverlayRules
    let categoryCaps: [OverlayCategoryCap]
}
