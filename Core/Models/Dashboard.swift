import Foundation

// MARK: - Monthly Burn-In (Current Period card)

struct MonthlyBurnIn: Codable {
    let totalBudget: Int64
    let spentBudget: Int64
    let currentDay: Int
    let daysInPeriod: Int

    var remainingBudget: Int64 { totalBudget - spentBudget }

    var spentPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(spentBudget) / Double(totalBudget)
    }
}

// MARK: - Month Progress

struct MonthProgress: Codable {
    let daysInPeriod: Int
    let remainingDays: Int
    let daysPassedPercentage: Int
}

// MARK: - Net Position

struct NetPosition: Codable {
    let totalNetPosition: Int64
    let changeThisPeriod: Int64
    let liquidBalance: Int64
    let protectedBalance: Int64
    let debtBalance: Int64
    let accountCount: Int64
}

// MARK: - Budget Stability (Spending Consistency card)

struct BudgetStability: Codable {
    let withinTolerancePercentage: Int
    let periodsWithinTolerance: Int
    let totalClosedPeriods: Int
    let recentClosedPeriods: [BudgetStabilityPeriod]
}

struct BudgetStabilityPeriod: Codable {
    let periodId: String
    let isOutsideTolerance: Bool
}
