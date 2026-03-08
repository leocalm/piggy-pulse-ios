import Foundation

// MARK: - API response

struct OnboardingStatusResponse: Codable {
    let status: String           // "not_started" | "in_progress" | "completed"
    let currentStep: String?     // "period" | "accounts" | "categories" | "summary" | nil
}

// MARK: - Wizard step enum

enum OnboardingStep: String, CaseIterable {
    case period
    case accounts
    case categories
    case summary

    var title: String {
        switch self {
        case .period:     return "Periods"
        case .accounts:   return "Accounts"
        case .categories: return "Categories"
        case .summary:    return "Review"
        }
    }

    var index: Int {
        OnboardingStep.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Weekend behavior

enum WeekendBehavior: String, CaseIterable {
    case keep = "keep"
    case shiftFriday = "friday"
    case shiftMonday = "monday"

    var label: String {
        switch self {
        case .keep:        return "Keep on weekend"
        case .shiftFriday: return "Shift to Friday"
        case .shiftMonday: return "Shift to Monday"
        }
    }
}

// MARK: - Draft models (local, pre-submission)

struct DraftAccount: Identifiable {
    let id = UUID()
    var name: String = ""
    var accountType: String = "Checking"
    var balanceText: String = ""
    var spendLimitText: String = ""

    var balanceInCents: Int64 {
        let cleaned = balanceText.replacingOccurrences(of: ",", with: ".")
        return Int64((Double(cleaned) ?? 0) * 100)
    }

    var spendLimitInCents: Int32? {
        guard accountType == "CreditCard" || accountType == "Allowance",
              !spendLimitText.isEmpty else { return nil }
        let cleaned = spendLimitText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned) else { return nil }
        return Int32(v * 100)
    }

    var showSpendLimit: Bool {
        accountType == "CreditCard" || accountType == "Allowance"
    }

    var defaultIcon: String {
        switch accountType {
        case "Checking":   return "🏦"
        case "Savings":    return "💰"
        case "CreditCard": return "💳"
        case "Wallet":     return "👛"
        case "Allowance":  return "🎯"
        default:           return "🏦"
        }
    }

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
    }
}

struct DraftCategory: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var categoryType: String   // "Incoming" | "Outgoing"
}

// MARK: - Category template

enum CategoryTemplate: Equatable {
    case none, essential, detailed, custom

    var categories: [DraftCategory] {
        switch self {
        case .none, .custom:
            return []
        case .essential:
            return [
                DraftCategory(name: "Income",    icon: "💵", categoryType: "Incoming"),
                DraftCategory(name: "Housing",   icon: "🏠", categoryType: "Outgoing"),
                DraftCategory(name: "Food",      icon: "🍔", categoryType: "Outgoing"),
                DraftCategory(name: "Transport", icon: "🚗", categoryType: "Outgoing"),
                DraftCategory(name: "Other",     icon: "📦", categoryType: "Outgoing"),
            ]
        case .detailed:
            return [
                DraftCategory(name: "Salary",            icon: "💼", categoryType: "Incoming"),
                DraftCategory(name: "Freelance",         icon: "💻", categoryType: "Incoming"),
                DraftCategory(name: "Investment Income", icon: "📈", categoryType: "Incoming"),
                DraftCategory(name: "Rent / Mortgage",   icon: "🏠", categoryType: "Outgoing"),
                DraftCategory(name: "Utilities",         icon: "💡", categoryType: "Outgoing"),
                DraftCategory(name: "Groceries",         icon: "🛒", categoryType: "Outgoing"),
                DraftCategory(name: "Dining",            icon: "🍽️", categoryType: "Outgoing"),
                DraftCategory(name: "Transport",         icon: "🚗", categoryType: "Outgoing"),
                DraftCategory(name: "Health",            icon: "🏥", categoryType: "Outgoing"),
                DraftCategory(name: "Entertainment",     icon: "🎬", categoryType: "Outgoing"),
                DraftCategory(name: "Clothing",          icon: "👗", categoryType: "Outgoing"),
                DraftCategory(name: "Other",             icon: "📦", categoryType: "Outgoing"),
            ]
        }
    }
}

// MARK: - Currency (for accounts step)

struct Currency: Codable, Identifiable, Hashable {
    let id: UUID
    let currency: String   // ISO code e.g. "EUR"
    let name: String
    let symbol: String
}
