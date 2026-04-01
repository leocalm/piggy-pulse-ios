import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let requiresAuth: Bool

    var url: URL {
        URL(string: APIClient.baseURL + path)!
    }
}

// MARK: - Auth

extension APIEndpoint {
    static let login = APIEndpoint(path: "/auth/login", method: .post, requiresAuth: false)
    static let login2FA = APIEndpoint(path: "/auth/2fa/verify", method: .post, requiresAuth: false)
    static let refreshToken = APIEndpoint(path: "/auth/refresh", method: .post, requiresAuth: false)
    static let revokeToken = APIEndpoint(path: "/auth/logout", method: .post, requiresAuth: true)
    static let register = APIEndpoint(path: "/auth/register", method: .post, requiresAuth: false)
    static let forgotPassword = APIEndpoint(path: "/auth/forgot-password", method: .post, requiresAuth: false)
}

// MARK: - User

extension APIEndpoint {
    static let me = APIEndpoint(path: "/auth/me", method: .get, requiresAuth: true)
    static let updateProfile = APIEndpoint(path: "/settings/profile", method: .put, requiresAuth: true)
    static let updatePreferences = APIEndpoint(path: "/settings/preferences", method: .put, requiresAuth: true)
    // updatePeriodModel removed — not in v2 API
}

// MARK - Currencies
extension APIEndpoint {
    static let currencies = APIEndpoint(path: "/currencies", method: .get, requiresAuth: true)
}

// MARK: - Transactions

extension APIEndpoint {
    static let transactions = APIEndpoint(path: "/transactions", method: .get, requiresAuth: true)
    static func transaction(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/transactions/\(id)", method: .get, requiresAuth: true)
    }
    static let createTransaction = APIEndpoint(path: "/transactions", method: .post, requiresAuth: true)
    static func updateTransaction(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/transactions/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteTransaction(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/transactions/\(id)", method: .delete, requiresAuth: true)
    }
}

// MARK: - Periods

extension APIEndpoint {
    static let periods = APIEndpoint(path: "/periods", method: .get, requiresAuth: true)
    static let createPeriod = APIEndpoint(path: "/periods", method: .post, requiresAuth: true)
    static func updatePeriod(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/periods/\(id)", method: .put, requiresAuth: true)
    }
    static func deletePeriod(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/periods/\(id)", method: .delete, requiresAuth: true)
    }
    static let schedule = APIEndpoint(path: "/periods/schedule", method: .get, requiresAuth: true)
    static let createSchedule = APIEndpoint(path: "/periods/schedule", method: .post, requiresAuth: true)
    static let updateSchedule = APIEndpoint(path: "/periods/schedule", method: .put, requiresAuth: true)
    static let deleteSchedule = APIEndpoint(path: "/periods/schedule", method: .delete, requiresAuth: true)
}

// MARK: - Accounts

extension APIEndpoint {
    static let accounts = APIEndpoint(path: "/accounts", method: .get, requiresAuth: true)
    static let createAccount = APIEndpoint(path: "/accounts", method: .post, requiresAuth: true)
    static func updateAccount(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/accounts/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteAccount(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/accounts/\(id)", method: .delete, requiresAuth: true)
    }
    static func archiveAccount(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/accounts/\(id)/archive", method: .post, requiresAuth: true)
    }
    static let accountOptions = APIEndpoint(path: "/accounts/options", method: .get, requiresAuth: true)
    static let accountsSummary = APIEndpoint(path: "/accounts/summary", method: .get, requiresAuth: true)
    // accountsManagement removed — use /accounts in v2

}

// MARK: - Categories

extension APIEndpoint {
    static let categories = APIEndpoint(path: "/categories", method: .get, requiresAuth: true)
    static let createCategory = APIEndpoint(path: "/categories", method: .post, requiresAuth: true)
    static func getCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)", method: .get, requiresAuth: true)
    }
    static func updateCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)", method: .delete, requiresAuth: true)
    }
    static func archiveCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)/archive", method: .post, requiresAuth: true)
    }
    static let categoryOptions = APIEndpoint(path: "/categories/options", method: .get, requiresAuth: true)
    // transferCategory removed — not in v2 API
    static let categoriesManagement = APIEndpoint(path: "/categories", method: .get, requiresAuth: true)
    static let categoriesOverview = APIEndpoint(path: "/categories/overview", method: .get, requiresAuth: true)

}

// MARK: - Vendors

extension APIEndpoint {
    static let vendors = APIEndpoint(path: "/vendors", method: .get, requiresAuth: true)
    static let createVendor = APIEndpoint(path: "/vendors", method: .post, requiresAuth: true)
    static func updateVendor(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/vendors/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteVendor(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/vendors/\(id)", method: .delete, requiresAuth: true)
    }
    static func archiveVendor(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/vendors/\(id)/archive", method: .post, requiresAuth: true)
    }
}

// MARK: - Overlays

extension APIEndpoint {
    static let overlays = APIEndpoint(path: "/overlays", method: .get, requiresAuth: true)
    static let createOverlay = APIEndpoint(path: "/overlays", method: .post, requiresAuth: true)
    static func updateOverlay(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/overlays/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteOverlay(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/overlays/\(id)", method: .delete, requiresAuth: true)
    }
}

// MARK: - Budget

extension APIEndpoint {
    // budgetPlan removed — use /targets in v2
    // updateBudgetTarget removed — use /targets in v2
}

// MARK: - Dashboard

extension APIEndpoint {
    static let dashboardCurrentPeriod = APIEndpoint(path: "/dashboard/current-period", method: .get, requiresAuth: true)
    static let dashboardNetPosition = APIEndpoint(path: "/dashboard/net-position", method: .get, requiresAuth: true)
    static let dashboardCashFlow = APIEndpoint(path: "/dashboard/cash-flow", method: .get, requiresAuth: true)
    static let dashboardSpendingTrend = APIEndpoint(path: "/dashboard/spending-trend", method: .get, requiresAuth: true)
    static let dashboardTopVendors = APIEndpoint(path: "/dashboard/top-vendors", method: .get, requiresAuth: true)
    static let dashboardFixedCategories = APIEndpoint(path: "/dashboard/fixed-categories", method: .get, requiresAuth: true)
    static let dashboardSubscriptions = APIEndpoint(path: "/dashboard/subscriptions", method: .get, requiresAuth: true)
    static let dashboardBudgetStability = APIEndpoint(path: "/dashboard/budget-stability", method: .get, requiresAuth: true)
    static let dashboardRecentTransactions = APIEndpoint(path: "/transactions", method: .get, requiresAuth: true)
}

// MARK: - Subscriptions

extension APIEndpoint {
    static let subscriptions = APIEndpoint(path: "/subscriptions", method: .get, requiresAuth: true)
    static let createSubscription = APIEndpoint(path: "/subscriptions", method: .post, requiresAuth: true)
    static func subscription(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/subscriptions/\(id)", method: .get, requiresAuth: true)
    }
    static func updateSubscription(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/subscriptions/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteSubscription(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/subscriptions/\(id)", method: .delete, requiresAuth: true)
    }
    static func cancelSubscription(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/subscriptions/\(id)/cancel", method: .post, requiresAuth: true)
    }
    static let upcomingCharges = APIEndpoint(path: "/subscriptions/upcoming", method: .get, requiresAuth: true)
}

// MARK: - Settings

extension APIEndpoint {
    static let profile = APIEndpoint(path: "/settings/profile", method: .get, requiresAuth: true)
    static let preferences = APIEndpoint(path: "/settings/preferences", method: .get, requiresAuth: true)
    static let changePassword = APIEndpoint(path: "/auth/password", method: .post, requiresAuth: true)
    static let deleteUserAccount = APIEndpoint(path: "/settings/account", method: .delete, requiresAuth: true)
}

// MARK: - Onboarding

extension APIEndpoint {
    static let onboardingStatus = APIEndpoint(path: "/onboarding/status", method: .get, requiresAuth: true)
    static let completeOnboarding = APIEndpoint(path: "/onboarding/complete", method: .post, requiresAuth: true)
}

// MARK: - Category Targets

extension APIEndpoint {
    static let categoryTargets = APIEndpoint(path: "/targets", method: .get, requiresAuth: true)
    static let upsertCategoryTargets = APIEndpoint(path: "/targets", method: .post, requiresAuth: true)
    static func excludeCategoryTarget(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/targets/\(id)/exclude", method: .post, requiresAuth: true)
    }
    static func includeCategoryTarget(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/targets/\(id)/exclude", method: .delete, requiresAuth: true)
    }
}
