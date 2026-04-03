import Foundation

// MARK: - API Response Models

struct WatchCurrentPeriod: Codable {
    let spent: Int64
    let target: Int64
    let daysRemaining: Int
    let daysInPeriod: Int
    let projectedSpend: Int64
}

struct WatchNetPosition: Codable {
    let total: Int64
    let differenceThisPeriod: Int64
    let numberOfAccounts: Int
    let liquidAmount: Int64
    let protectedAmount: Int64
    let debtAmount: Int64
}

struct WatchAccountSummary: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: String
    let currentBalance: Int64
    let status: String
}

// MARK: - User Info (from /auth/me)

struct WatchUserInfo: Codable {
    let currencyCode: String?
}

// MARK: - Loading State

enum WatchLoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
