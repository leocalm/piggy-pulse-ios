import Foundation

// MARK: - API response

struct OnboardingStatusResponse: Codable {
    let status: String           // "not_started" | "in_progress" | "completed"
    let currentStep: String?     // "currency" | "period" | "accounts" | "categories" | "summary" | nil
}

// MARK: - Wizard step enum

enum OnboardingStep: String, CaseIterable {
    case welcome
    case currency
    case period
    case accounts
    case categories
    case summary

    /// Steps shown in the step indicator (exclude welcome and summary)
    static var indicatorSteps: [OnboardingStep] {
        [.currency, .period, .accounts, .categories]
    }

    var indicatorTitle: String {
        switch self {
        case .currency:   return String(localized: "Currency")
        case .period:     return String(localized: "Periods")
        case .accounts:   return String(localized: "Accounts")
        case .categories: return String(localized: "Categories")
        default:          return ""
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
        case .keep:        return String(localized: "Keep on weekend")
        case .shiftFriday: return String(localized: "Shift to Friday")
        case .shiftMonday: return String(localized: "Shift to Monday")
        }
    }
}

// MARK: - Draft models (local, pre-submission)

struct DraftAccount: Identifiable {
    let id = UUID()
    var name: String = ""
    var accountType: String = "checking"
    var balanceText: String = ""
    var spendLimitText: String = ""

    var balanceInCents: Int64 {
        let cleaned = balanceText.replacingOccurrences(of: ",", with: ".")
        return Int64((Double(cleaned) ?? 0) * 100)
    }

    var spendLimitInCents: Int32? {
        guard accountType == "creditcard" || accountType == "allowance",
              !spendLimitText.isEmpty else { return nil }
        let cleaned = spendLimitText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned) else { return nil }
        return Int32(v * 100)
    }

    var showSpendLimit: Bool {
        accountType == "creditcard" || accountType == "allowance"
    }

    var defaultIcon: String {
        switch accountType {
        case "checking":   return "🏦"
        case "savings":    return "💰"
        case "creditcard": return "💳"
        case "wallet":     return "👛"
        case "allowance":  return "🎯"
        default:           return "🏦"
        }
    }

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 3
    }
}

struct DraftCategory: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var categoryType: String   // "Incoming" | "Outgoing"
    var behavior: String?
}

// MARK: - Category template (legacy, kept for backward compat)

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

// MARK: - Currency (for currency step)

struct Currency: Codable, Identifiable, Hashable {
    let id: UUID
    let code: String       // ISO code e.g. "EUR"
    let name: String
    let symbol: String
    let decimalPlaces: Int?
    let symbolPosition: String?

    // MARK: - Backward compatibility
    var currency: String { code }
}

// MARK: - Onboarding templates API

struct OnboardingTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let categories: [OnboardingTemplateCategory]
}

struct OnboardingTemplateCategory: Codable, Identifiable {
    var id: String { "\(name)_\(type)" }
    let name: String
    let icon: String
    let type: String       // "income" | "expense"
    let behavior: String?  // "fixed" | "variable" | "subscription" | nil

    var displayType: String {
        switch type.lowercased() {
        case "income": return "Incoming"
        case "expense": return "Outgoing"
        default: return type
        }
    }
}
