import Foundation

// MARK: - Card Type Registry

enum DashboardCardType: String, Codable, CaseIterable, Identifiable {
    // Global cards (original 3 — enabled by default)
    case currentPeriod = "current_period"
    case budgetStability = "budget_stability"
    case netPosition = "net_position"

    // Global cards (new — disabled by default)
    case recentTransactions = "recent_transactions"
    case topCategories = "top_categories"
    case budgetPerDay = "budget_per_day"
    case remainingBudget = "remaining_budget"
    case balanceOverTime = "balance_over_time"

    // Entity cards (require entityId)
    case accountSummary = "account_summary"
    case categoryBreakdown = "category_breakdown"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentPeriod: return "Current Period"
        case .budgetStability: return "Spending Consistency"
        case .netPosition: return "Net Position"
        case .recentTransactions: return "Recent Transactions"
        case .topCategories: return "Top Categories"
        case .budgetPerDay: return "Budget Per Day"
        case .remainingBudget: return "Remaining Budget"
        case .balanceOverTime: return "Balance Over Time"
        case .accountSummary: return "Account Summary"
        case .categoryBreakdown: return "Category Breakdown"
        }
    }

    var iconName: String {
        switch self {
        case .currentPeriod: return "flame.fill"
        case .budgetStability: return "chart.bar.fill"
        case .netPosition: return "banknote.fill"
        case .recentTransactions: return "list.bullet.rectangle"
        case .topCategories: return "chart.pie.fill"
        case .budgetPerDay: return "calendar.badge.clock"
        case .remainingBudget: return "hourglass"
        case .balanceOverTime: return "chart.xyaxis.line"
        case .accountSummary: return "building.columns.fill"
        case .categoryBreakdown: return "folder.fill"
        }
    }

    var isEntityCard: Bool {
        switch self {
        case .accountSummary, .categoryBreakdown:
            return true
        default:
            return false
        }
    }

    var requiresPeriod: Bool {
        switch self {
        case .budgetStability, .balanceOverTime:
            return false
        default:
            return true
        }
    }
}

// MARK: - Card Config (matches GET /api/v1/dashboard-layout response)

struct DashboardCardConfig: Codable, Identifiable, Equatable {
    let id: UUID
    let cardType: DashboardCardType
    var entityId: UUID?
    let size: String       // "half" | "full" — read-only, auto-assigned by server
    var position: Int
    var enabled: Bool
}

extension Array where Element == DashboardCardConfig {
    var visibleCards: [DashboardCardConfig] {
        filter(\.enabled).sorted { $0.position < $1.position }
    }
}

// MARK: - API Request Models

struct CreateDashboardCardRequest: Encodable {
    let cardType: String
    let entityId: UUID?
    let position: Int
    let enabled: Bool
}

struct UpdateDashboardCardRequest: Encodable {
    let position: Int?
    let enabled: Bool?
}

struct ReorderRequest: Encodable {
    let order: [ReorderItem]
}

struct ReorderItem: Encodable {
    let id: UUID
    let position: Int
}

// MARK: - Available Cards Response (GET /api/v1/dashboard-layout/available-cards)

struct AvailableCardsResponse: Decodable {
    let globalCards: [AvailableGlobalCard]
    let entityCards: [AvailableEntityCardGroup]
}

struct AvailableGlobalCard: Decodable, Identifiable {
    let cardType: String
    let defaultSize: String
    let alreadyAdded: Bool
    var id: String { cardType }
}

struct AvailableEntityCardGroup: Decodable, Identifiable {
    let cardType: String
    let defaultSize: String
    let availableEntities: [AvailableEntity]
    var id: String { cardType }
}

struct AvailableEntity: Decodable, Identifiable {
    let id: UUID
    let name: String
    let alreadyAdded: Bool
}
