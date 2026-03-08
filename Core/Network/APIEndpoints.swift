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
    static let login = APIEndpoint(path: "/auth/token", method: .post, requiresAuth: false)
    static let login2FA = APIEndpoint(path: "/auth/token/2fa", method: .post, requiresAuth: false)
    static let refreshToken = APIEndpoint(path: "/auth/token/refresh", method: .post, requiresAuth: false)
    static let revokeToken = APIEndpoint(path: "/auth/token/revoke", method: .post, requiresAuth: true)
    static let register = APIEndpoint(path: "/users/", method: .post, requiresAuth: false)
    static let forgotPassword = APIEndpoint(path: "/password-reset/request", method: .post, requiresAuth: false)
}

// MARK: - User

extension APIEndpoint {
    static let me = APIEndpoint(path: "/users/me", method: .get, requiresAuth: true)
    static let updateProfile = APIEndpoint(path: "/settings/profile", method: .put, requiresAuth: true)
    static let updatePreferences = APIEndpoint(path: "/settings/preferences", method: .put, requiresAuth: true)
    static let updatePeriodModel = APIEndpoint(path: "/settings/period-model", method: .put, requiresAuth: true)
}

// MARK - Currencies
extension APIEndpoint {
    static let currencies = APIEndpoint(path: "/currency/", method: .get, requiresAuth: true)
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
    static let periods = APIEndpoint(path: "/budget_period", method: .get, requiresAuth: true)
    static let createPeriod = APIEndpoint(path: "/budget_period", method: .post, requiresAuth: true)
    static func updatePeriod(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/budget_period/\(id)", method: .put, requiresAuth: true)
    }
    static func deletePeriod(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/budget_period/\(id)", method: .delete, requiresAuth: true)
    }
    static let schedule = APIEndpoint(path: "/budget_period/schedule", method: .get, requiresAuth: true)
    static let createSchedule = APIEndpoint(path: "/budget_period/schedule", method: .post, requiresAuth: true)
    static let updateSchedule = APIEndpoint(path: "/budget_period/schedule", method: .put, requiresAuth: true)
    static let deleteSchedule = APIEndpoint(path: "/budget_period/schedule", method: .delete, requiresAuth: true)
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

}

// MARK: - Categories

extension APIEndpoint {
    static let categories = APIEndpoint(path: "/categories", method: .get, requiresAuth: true)
    static let createCategory = APIEndpoint(path: "/categories", method: .post, requiresAuth: true)
    static func updateCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)", method: .put, requiresAuth: true)
    }
    static func deleteCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)", method: .delete, requiresAuth: true)
    }
    static func archiveCategory(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/\(id)/archive", method: .post, requiresAuth: true)
    }
    // Add to Categories section - we'll reuse the list with period_id
    static func categoriesForPeriod(periodId: UUID) -> APIEndpoint {
        APIEndpoint(path: "/categories/", method: .get, requiresAuth: true)
    }
    static let categoryOptions = APIEndpoint(path: "/categories/options", method: .get, requiresAuth: true)
    static let transferCategory = APIEndpoint(path: "/categories/transfer", method: .get, requiresAuth: true)
    static let categoriesManagement = APIEndpoint(path: "/categories/management", method: .get, requiresAuth: true)

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
    // Add to Vendors section
    static func vendorsForPeriod(periodId: UUID) -> APIEndpoint {
        APIEndpoint(path: "/vendors/", method: .get, requiresAuth: true)
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
    static let budgetPlan = APIEndpoint(path: "/budget/plan", method: .get, requiresAuth: true)
    static let updateBudgetTarget = APIEndpoint(path: "/budget/targets", method: .put, requiresAuth: true)
}

// MARK: - Dashboard

extension APIEndpoint {
    static let monthlyBurnIn = APIEndpoint(path: "/dashboard/monthly-burn-in", method: .get, requiresAuth: true)
    static let monthProgress = APIEndpoint(path: "/dashboard/month-progress", method: .get, requiresAuth: true)
    static let netPosition = APIEndpoint(path: "/dashboard/net-position", method: .get, requiresAuth: true)
    static let budgetStability = APIEndpoint(path: "/dashboard/budget-stability", method: .get, requiresAuth: true)
}

// MARK: - Budget Categories

extension APIEndpoint {
    static let budgetCategories = APIEndpoint(path: "/budget-categories/", method: .get, requiresAuth: true)
}

// MARK: - Settings

extension APIEndpoint {
    static let profile = APIEndpoint(path: "/settings/profile", method: .get, requiresAuth: true)
    static let preferences = APIEndpoint(path: "/settings/preferences", method: .get, requiresAuth: true)
    static let changePassword = APIEndpoint(path: "/settings/security/password", method: .post, requiresAuth: true)
}

// MARK: - Onboarding

extension APIEndpoint {
    static let onboardingStatus = APIEndpoint(path: "/onboarding/status", method: .get, requiresAuth: true)
    static let completeOnboarding = APIEndpoint(path: "/onboarding/complete", method: .post, requiresAuth: true)
}
