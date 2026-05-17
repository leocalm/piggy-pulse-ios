import Foundation
import SwiftUI

enum ScreenshotLocaleID: String, CaseIterable, Identifiable {
    case enUS = "en-US"
    case enGB = "en-GB"
    case ptBR = "pt-BR"
    case ptPT = "pt-PT"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case nlNL = "nl-NL"
    case deDE = "de-DE"

    var id: String { rawValue }
    var foundationIdentifier: String { rawValue.replacingOccurrences(of: "-", with: "_") }
}

enum ScreenshotStateID: String, CaseIterable, Identifiable {
    case dashboardNebula = "01-dashboard-nebula"
    case dashboardElectricNeon = "02-dashboard-electric-neon"
    case dashboardTropical = "03-dashboard-tropical"
    case transactions = "04-transactions"
    case periodConfiguration = "05-period-configuration"
    case categories = "06-categories"

    enum Destination {
        case dashboard
        case transactions
        case periodConfiguration
        case categories
    }

    var id: String { rawValue }

    var destination: Destination {
        switch self {
        case .dashboardNebula, .dashboardElectricNeon, .dashboardTropical:
            return .dashboard
        case .transactions:
            return .transactions
        case .periodConfiguration:
            return .periodConfiguration
        case .categories:
            return .categories
        }
    }

    var theme: ColorTheme {
        switch self {
        case .dashboardElectricNeon:
            return .neon
        case .dashboardTropical:
            return .tropical
        default:
            return .nebula
        }
    }

    var screenshotAccessibilityIdentifier: String {
        switch destination {
        case .dashboard:
            return "screenshot.dashboard"
        case .transactions:
            return "screenshot.transactions"
        case .periodConfiguration:
            return "screenshot.periodConfiguration"
        case .categories:
            return "screenshot.categories"
        }
    }
}

struct ScreenshotModeConfiguration {
    let localeID: ScreenshotLocaleID
    let stateID: ScreenshotStateID
    let profile: ScreenshotDemoProfile

    static var isRequested: Bool {
        let env = ProcessInfo.processInfo.environment
        let args = ProcessInfo.processInfo.arguments
        let envEnabled = env["SCREENSHOT_MODE"].map { ["1", "true", "yes"].contains($0.lowercased()) } ?? false
        return envEnabled || args.contains("--screenshot-mode")
    }

    enum LoadResult {
        case success(ScreenshotModeConfiguration)
        case failure(String)
    }

    static func current() -> LoadResult? {
        let env = ProcessInfo.processInfo.environment
        let args = ProcessInfo.processInfo.arguments

        guard isRequested else { return nil }

        guard let localeValue = env["SCREENSHOT_LOCALE"] ?? argumentValue(named: "--screenshot-locale", in: args),
              let localeID = ScreenshotLocaleID(rawValue: localeValue)
        else {
            return .failure("SCREENSHOT_LOCALE or --screenshot-locale must be one of: \(ScreenshotLocaleID.allCases.map(\.rawValue).joined(separator: ", "))")
        }

        guard let stateValue = env["SCREENSHOT_STATE"] ?? argumentValue(named: "--screenshot-state", in: args),
              let stateID = ScreenshotStateID(rawValue: stateValue)
        else {
            return .failure("SCREENSHOT_STATE or --screenshot-state must be one of: \(ScreenshotStateID.allCases.map(\.rawValue).joined(separator: ", "))")
        }

        let errors = ScreenshotDemoCatalog.validate()
        guard errors.isEmpty else {
            return .failure("Screenshot demo data validation failed:\n\(errors.joined(separator: "\n"))")
        }

        return .success(
            ScreenshotModeConfiguration(
                localeID: localeID,
                stateID: stateID,
                profile: ScreenshotDemoCatalog.profile(for: localeID)
            )
        )
    }

    private static func argumentValue(named name: String, in args: [String]) -> String? {
        if let inline = args.first(where: { $0.hasPrefix("\(name)=") }) {
            return String(inline.dropFirst(name.count + 1))
        }
        guard let index = args.firstIndex(of: name), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
}

struct ScreenshotLocaleContent {
    let currency: String
    let currencySymbol: String
    let currencyFormatExample: String
    let supermarket: String
    let employer: String
    let salaryLabel: String
    let salaryReceivedTitle: String
    let transferLabel: String
    let restaurantCategory: String
    let supermarketCategory: String
    let diningOutTitle: String
    let savingsTitle: String
    let groceriesTitle: String
    let toysTitle: String
    let allowanceTitle: String
    let allowanceCategory: String
    let housingCategory: String
    let transportCategory: String
    let utilitiesCategory: String
    let subscriptionsCategory: String
    let shoppingCategory: String
    let healthCategory: String
    let refundTitle: String
    let periodNameCurrent: String
    let periodScheduleName: String
    let automaticPeriodFrequency: String
}

struct ScreenshotFrameCopy {
    let title: String
    let subtitle: String
}

struct ScreenshotVendorContent {
    let coffee: String
    let transport: String
    let utilities: String
    let subscription1: String
    let subscription2: String
    let shopping: String
    let pharmacy: String
    let rent: String
    let refundVendor: String
}

struct ScreenshotAccountNames {
    let checking: String
    let savings: String
    let creditCard: String
    let allowance: String
}

struct ScreenshotMoneySet {
    let checking: Int64
    let savings: Int64
    let creditCard: Int64
    let allowance: Int64
}

struct ScreenshotBudgetTargets {
    let groceries: Int32
    let diningOut: Int32
    let transport: Int32
    let housing: Int32
    let utilities: Int32
    let subscriptions: Int32
    let shopping: Int32
    let toys: Int32
    let health: Int32
    let savings: Int32
}

struct ScreenshotDemoProfile {
    let localeID: ScreenshotLocaleID
    let content: ScreenshotLocaleContent
    let frameCopy: [ScreenshotStateID: ScreenshotFrameCopy]
    let vendors: ScreenshotVendorContent
    let accountNames: ScreenshotAccountNames
    let openingBalances: ScreenshotMoneySet
    let budgetTargets: ScreenshotBudgetTargets
    let periods: [BudgetPeriod]
    let activePeriod: BudgetPeriod
    let accounts: [AccountListItem]
    let categories: [CategoryListItem]
    let vendorItems: [VendorListItem]
    let targets: [CategoryTarget]
    let subscriptions: [Subscription]
    let allTransactions: [Transaction]
    let activeTransactions: [Transaction]
}

enum ScreenshotDemoCatalog {
    static let referenceDate = "2026-05-15"
    static let activePeriodStart = "2026-05-11"
    static let activePeriodEnd = "2026-05-24"

    static func profile(for localeID: ScreenshotLocaleID) -> ScreenshotDemoProfile {
        ScreenshotDemoBuilder(localeID: localeID).build()
    }

    static func validate() -> [String] {
        var errors: [String] = []

        for locale in ScreenshotLocaleID.allCases {
            let profile = profile(for: locale)
            if profile.content.currency.isEmpty {
                errors.append("\(locale.rawValue): missing currency code")
            }
            if profile.frameCopy.count != ScreenshotStateID.allCases.count {
                errors.append("\(locale.rawValue): missing screenshot frame copy")
            }
            for state in ScreenshotStateID.allCases {
                guard let copy = profile.frameCopy[state] else {
                    errors.append("\(locale.rawValue): missing frame copy for \(state.rawValue)")
                    continue
                }
                if copy.title.isEmpty || copy.subtitle.isEmpty {
                    errors.append("\(locale.rawValue): empty frame copy for \(state.rawValue)")
                }
            }
            if profile.accounts.count != 4 {
                errors.append("\(locale.rawValue): expected 4 accounts")
            }
            if profile.categories.filter({ $0.type == "expense" }).count < 10 {
                errors.append("\(locale.rawValue): expected at least 10 expense categories")
            }
            if profile.vendorItems.count < 10 {
                errors.append("\(locale.rawValue): expected required vendors")
            }
            if profile.targets.count < 10 {
                errors.append("\(locale.rawValue): expected required budget targets")
            }
            if profile.allTransactions.count < 120 {
                errors.append("\(locale.rawValue): generated \(profile.allTransactions.count) transactions, expected at least 120")
            }
            let transactionIDs = profile.allTransactions.map(\.id)
            if Set(transactionIDs).count != transactionIDs.count {
                errors.append("\(locale.rawValue): duplicate transaction IDs")
            }
            if profile.activeTransactions.isEmpty {
                errors.append("\(locale.rawValue): active period has no transactions")
            }
            if profile.activeTransactions.sorted(by: { $0.date > $1.date }).prefix(8).count < 8 {
                errors.append("\(locale.rawValue): transactions screen has fewer than 8 recent transactions")
            }
            let activeExpenseCategoryIDs = Set(profile.activeTransactions.filter { $0.category.type == "expense" }.map(\.category.id))
            let budgetedCategoryIDs = Set(profile.targets.filter { $0.type == "expense" && $0.budgetedValue > 0 }.map(\.categoryId))
            if activeExpenseCategoryIDs.intersection(budgetedCategoryIDs).isEmpty {
                errors.append("\(locale.rawValue): dashboard categories have zero progress")
            }
        }

        return errors
    }
}

private struct ScreenshotDemoBuilder {
    let localeID: ScreenshotLocaleID

    private var localeIndex: Int {
        ScreenshotLocaleID.allCases.firstIndex(of: localeID)! + 1
    }

    func build() -> ScreenshotDemoProfile {
        let content = Self.localeContent[localeID]!
        let accountNames = Self.accountNames[localeID]!
        let openingBalances = Self.openingBalances[localeID]!
        let targets = Self.budgetTargets[localeID]!
        let vendorContent = Self.vendors[localeID]!

        let accountModels = accounts(names: accountNames, balances: openingBalances, targets: targets)
        let categoryModels = categories(content: content)
        let vendorModels = vendors(content: content, vendors: vendorContent)
        let categoryTargets = categoryTargets(content: content, categories: categoryModels, targets: targets)
        let periodModels = periods(content: content, targetTotal: targetTotal(targets), spentTotal: activeSpentTotal(content: content, targets: targets))
        let active = periodModels.first { $0.status == "active" }!
        let subscriptionModels = subscriptions(categories: categoryModels, vendors: vendorModels, targets: targets)
        let generatedTransactions = transactions(
            content: content,
            vendors: vendorContent,
            accounts: accountModels,
            categories: categoryModels,
            vendorItems: vendorModels,
            targets: targets
        )
        let activeTransactions = generatedTransactions.filter { $0.date >= "2026-05-11" && $0.date <= "2026-05-24" }

        return ScreenshotDemoProfile(
            localeID: localeID,
            content: content,
            frameCopy: Self.frameCopy[localeID]!,
            vendors: vendorContent,
            accountNames: accountNames,
            openingBalances: openingBalances,
            budgetTargets: targets,
            periods: periodModels,
            activePeriod: active,
            accounts: accountModels,
            categories: categoryModels,
            vendorItems: vendorModels,
            targets: categoryTargets,
            subscriptions: subscriptionModels,
            allTransactions: generatedTransactions,
            activeTransactions: activeTransactions
        )
    }

    private func uuid(_ group: Int, _ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-%04X-%04X-%04X-%012X", group, localeIndex, group, index))!
    }

    private func cents(_ value: Double) -> Int64 {
        Int64((value * 100).rounded())
    }

    private func account(_ accounts: [AccountListItem], _ type: String) -> AccountListItem {
        accounts.first { $0.type == type }!
    }

    private func category(_ categories: [CategoryListItem], _ key: String) -> CategoryListItem {
        categories.first { $0.name == key }!
    }

    private func vendor(_ vendors: [VendorListItem], _ name: String) -> VendorListItem {
        vendors.first { $0.name == name }!
    }

    private func transactionCategory(_ category: CategoryListItem) -> TransactionCategory {
        TransactionCategory(id: category.id, name: category.name, color: category.color, icon: category.icon, type: category.type)
    }

    private func transactionAccount(_ account: AccountListItem) -> TransactionAccount {
        TransactionAccount(id: account.id, name: account.name, color: account.color)
    }

    private func transactionVendor(_ vendor: VendorListItem?) -> TransactionVendor? {
        guard let vendor else { return nil }
        return TransactionVendor(id: vendor.id, name: vendor.name)
    }

    private func accounts(names: ScreenshotAccountNames, balances: ScreenshotMoneySet, targets: ScreenshotBudgetTargets) -> [AccountListItem] {
        [
            AccountListItem(id: uuid(100, 1), name: names.checking, color: "#8B7EC8", icon: "💳", type: "checking", status: "active", currentBalance: balances.checking),
            AccountListItem(id: uuid(100, 2), name: names.savings, color: "#7CA8C4", icon: "🛟", type: "savings", status: "active", currentBalance: balances.savings),
            AccountListItem(id: uuid(100, 3), name: names.creditCard, color: "#C48BA0", icon: "💳", type: "creditcard", status: "active", currentBalance: abs(balances.creditCard)),
            AccountListItem(id: uuid(100, 4), name: names.allowance, color: "#F0A25C", icon: "🧸", type: "allowance", status: "active", currentBalance: balances.allowance, spendLimit: targets.toys)
        ]
    }

    private func categories(content: ScreenshotLocaleContent) -> [CategoryListItem] {
        [
            CategoryListItem(id: uuid(200, 1), name: content.salaryLabel, color: "#7CA8C4", icon: "💼", type: "income", status: "active", parentId: nil, behavior: nil),
            CategoryListItem(id: uuid(200, 2), name: content.transferLabel, color: "#8B7EC8", icon: "↔️", type: "transfer", status: "active", parentId: nil, behavior: nil),
            CategoryListItem(id: uuid(200, 3), name: content.supermarketCategory, color: "#5E63E6", icon: "🛒", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 4), name: content.restaurantCategory, color: "#C48BA0", icon: "🍽️", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 5), name: content.transportCategory, color: "#7CA8C4", icon: "🚆", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 6), name: content.housingCategory, color: "#8B7EC8", icon: "🏠", type: "expense", status: "active", parentId: nil, behavior: "fixed"),
            CategoryListItem(id: uuid(200, 7), name: content.utilitiesCategory, color: "#F0A25C", icon: "💡", type: "expense", status: "active", parentId: nil, behavior: "fixed"),
            CategoryListItem(id: uuid(200, 8), name: content.subscriptionsCategory, color: "#9B8AE0", icon: "🔁", type: "expense", status: "active", parentId: nil, behavior: "subscription"),
            CategoryListItem(id: uuid(200, 9), name: content.shoppingCategory, color: "#FF6B6B", icon: "🛍️", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 10), name: content.toysTitle, color: "#FFC800", icon: "🧸", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 11), name: content.healthCategory, color: "#00CCB3", icon: "💊", type: "expense", status: "active", parentId: nil, behavior: "variable"),
            CategoryListItem(id: uuid(200, 12), name: content.savingsTitle, color: "#B8FF00", icon: "🌱", type: "expense", status: "active", parentId: nil, behavior: "fixed"),
            CategoryListItem(id: uuid(200, 13), name: content.allowanceCategory, color: "#F0A25C", icon: "🪙", type: "transfer", status: "active", parentId: nil, behavior: "fixed")
        ]
    }

    private func vendors(content: ScreenshotLocaleContent, vendors: ScreenshotVendorContent) -> [VendorListItem] {
        [
            VendorListItem(id: uuid(300, 1), name: content.employer, status: "active"),
            VendorListItem(id: uuid(300, 2), name: vendors.rent, status: "active"),
            VendorListItem(id: uuid(300, 3), name: content.supermarket, status: "active"),
            VendorListItem(id: uuid(300, 4), name: "McDonald's", status: "active"),
            VendorListItem(id: uuid(300, 5), name: vendors.coffee, status: "active"),
            VendorListItem(id: uuid(300, 6), name: vendors.transport, status: "active"),
            VendorListItem(id: uuid(300, 7), name: vendors.utilities, status: "active"),
            VendorListItem(id: uuid(300, 8), name: vendors.subscription1, status: "active"),
            VendorListItem(id: uuid(300, 9), name: vendors.subscription2, status: "active"),
            VendorListItem(id: uuid(300, 10), name: vendors.shopping, status: "active"),
            VendorListItem(id: uuid(300, 11), name: vendors.pharmacy, status: "active"),
            VendorListItem(id: uuid(300, 12), name: vendors.refundVendor, status: "active")
        ]
    }

    private func categoryTargets(content: ScreenshotLocaleContent, categories: [CategoryListItem], targets: ScreenshotBudgetTargets) -> [CategoryTarget] {
        func make(_ index: Int, _ name: String, _ amount: Int32) -> CategoryTarget {
            let cat = category(categories, name)
            return CategoryTarget(id: uuid(400, index), categoryId: cat.id, name: cat.name, type: cat.type, parentId: nil, budgetedValue: amount, isExcluded: false)
        }
        return [
            make(1, content.supermarketCategory, targets.groceries),
            make(2, content.restaurantCategory, targets.diningOut),
            make(3, content.transportCategory, targets.transport),
            make(4, content.housingCategory, targets.housing),
            make(5, content.utilitiesCategory, targets.utilities),
            make(6, content.subscriptionsCategory, targets.subscriptions),
            make(7, content.shoppingCategory, targets.shopping),
            make(8, content.toysTitle, targets.toys),
            make(9, content.healthCategory, targets.health),
            make(10, content.savingsTitle, targets.savings),
            CategoryTarget(id: uuid(400, 11), categoryId: category(categories, content.salaryLabel).id, name: content.salaryLabel, type: "income", parentId: nil, budgetedValue: 0, isExcluded: false)
        ]
    }

    private func periods(content: ScreenshotLocaleContent, targetTotal: Int64, spentTotal: Int64) -> [BudgetPeriod] {
        let specs: [(String, String, Int?, String, Double)] = [
            ("2026-03-02", "past", nil, "Mar 2 - Mar 15", 0.74),
            ("2026-03-16", "past", nil, "Mar 16 - Mar 29", 0.81),
            ("2026-03-30", "past", nil, "Mar 30 - Apr 12", 0.69),
            ("2026-04-13", "past", nil, "Apr 13 - Apr 26", 0.88),
            ("2026-04-27", "past", nil, "Apr 27 - May 10", 0.76),
            ("2026-05-11", "active", 9, content.periodNameCurrent, Double(spentTotal) / Double(max(targetTotal, 1))),
            ("2026-05-25", "upcoming", 23, "May 25 - Jun 7", 0.0)
        ]
        return specs.enumerated().map { offset, spec in
            let spent = spec.1 == "active" ? spentTotal : Int64(Double(targetTotal) * spec.4)
            return BudgetPeriod(
                id: uuid(500, offset + 1),
                name: spec.3,
                startDate: spec.0,
                periodType: "duration",
                length: 13,
                remainingDays: spec.2,
                numberOfTransactions: spec.1 == "active" ? 18 : 20,
                percentageOfTargetUsed: spec.4,
                status: spec.1,
                totalSpent: spent,
                totalBudgeted: targetTotal
            )
        }
    }

    private func subscriptions(categories: [CategoryListItem], vendors: [VendorListItem], targets: ScreenshotBudgetTargets) -> [Subscription] {
        let subscriptionsCategory = categories.first { $0.behavior == "subscription" }!
        let netflix = vendor(vendors, "Netflix")
        let spotify = vendor(vendors, "Spotify")
        return [
            Subscription(id: uuid(600, 1), name: "Netflix", categoryId: subscriptionsCategory.id, vendorId: netflix.id, billingAmount: Int64(Double(targets.subscriptions) * 0.45), billingCycle: .monthly, billingDay: 14, nextChargeDate: "2026-06-14", status: .active, cancelledAt: nil, createdAt: "2026-03-02", updatedAt: "2026-05-15"),
            Subscription(id: uuid(600, 2), name: "Spotify", categoryId: subscriptionsCategory.id, vendorId: spotify.id, billingAmount: Int64(Double(targets.subscriptions) * 0.35), billingCycle: .monthly, billingDay: 12, nextChargeDate: "2026-06-12", status: .active, cancelledAt: nil, createdAt: "2026-03-02", updatedAt: "2026-05-15")
        ]
    }

    private func targetTotal(_ targets: ScreenshotBudgetTargets) -> Int64 {
        Int64(targets.groceries + targets.diningOut + targets.transport + targets.housing + targets.utilities + targets.subscriptions + targets.shopping + targets.toys + targets.health + targets.savings)
    }

    private func activeSpentTotal(content: ScreenshotLocaleContent, targets: ScreenshotBudgetTargets) -> Int64 {
        Int64(Double(targets.groceries) * 0.72)
            + Int64(Double(targets.diningOut) * 0.62)
            + Int64(Double(targets.transport) * 0.42)
            + Int64(Double(targets.utilities) * 0.72)
            + Int64(Double(targets.subscriptions) * 0.92)
            + Int64(Double(targets.shopping) * 0.52)
            + Int64(Double(targets.toys) * 0.45)
            + Int64(Double(targets.health) * 0.22)
            + Int64(targets.savings)
    }

    private func transactions(
        content: ScreenshotLocaleContent,
        vendors vendorContent: ScreenshotVendorContent,
        accounts: [AccountListItem],
        categories: [CategoryListItem],
        vendorItems: [VendorListItem],
        targets: ScreenshotBudgetTargets
    ) -> [Transaction] {
        let checking = account(accounts, "checking")
        let savings = account(accounts, "savings")
        let allowance = account(accounts, "allowance")
        let creditCard = account(accounts, "creditcard")

        let salary = category(categories, content.salaryLabel)
        let transfer = category(categories, content.transferLabel)
        let groceries = category(categories, content.supermarketCategory)
        let dining = category(categories, content.restaurantCategory)
        let transport = category(categories, content.transportCategory)
        let housing = category(categories, content.housingCategory)
        let utilities = category(categories, content.utilitiesCategory)
        let subscriptions = category(categories, content.subscriptionsCategory)
        let shopping = category(categories, content.shoppingCategory)
        let toys = category(categories, content.toysTitle)
        let health = category(categories, content.healthCategory)
        let savingsCategory = category(categories, content.savingsTitle)
        let allowanceCategory = category(categories, content.allowanceCategory)

        let employerVendor = vendor(vendorItems, content.employer)
        let rentVendor = vendor(vendorItems, vendorContent.rent)
        let supermarketVendor = vendor(vendorItems, content.supermarket)
        let mcdonaldsVendor = vendor(vendorItems, "McDonald's")
        let coffeeVendor = vendor(vendorItems, vendorContent.coffee)
        let transportVendor = vendor(vendorItems, vendorContent.transport)
        let utilitiesVendor = vendor(vendorItems, vendorContent.utilities)
        let netflixVendor = vendor(vendorItems, "Netflix")
        let spotifyVendor = vendor(vendorItems, "Spotify")
        let shoppingVendor = vendor(vendorItems, vendorContent.shopping)
        let pharmacyVendor = vendor(vendorItems, vendorContent.pharmacy)
        let refundVendor = vendor(vendorItems, vendorContent.refundVendor)

        var items: [Transaction] = []
        var index = 1

        func add(_ date: String, _ amount: Int64, _ description: String, _ category: CategoryListItem, _ from: AccountListItem, _ to: AccountListItem? = nil, _ vendor: VendorListItem? = nil) {
            items.append(Transaction(
                id: uuid(700, index),
                amount: category.type == "income" ? amount : abs(amount),
                description: description,
                date: date,
                transactionType: to == nil ? "regular" : "transfer",
                category: transactionCategory(category),
                fromAccount: transactionAccount(from),
                toAccount: to.map(transactionAccount),
                vendor: transactionVendor(vendor)
            ))
            index += 1
        }

        let salaryAmount = Self.salaryAmounts[localeID]!
        for date in ["2026-03-25", "2026-04-25", "2026-05-15"] {
            add(date, salaryAmount, content.salaryReceivedTitle, salary, checking, nil, employerVendor)
        }

        let rentAmount = Self.rentAmounts[localeID]!
        for date in ["2026-03-03", "2026-04-03", "2026-05-03"] {
            add(date, rentAmount, vendorContent.rent, housing, checking, nil, rentVendor)
        }

        var day = Self.date("2026-03-02")
        let end = Self.date("2026-05-10")
        var dayOffset = 0
        while day <= end {
            let date = Self.format(day)
            if dayOffset % 4 == 0 {
                add(date, -cents(Double(targets.groceries) / 100.0 * (0.13 + Double(dayOffset % 5) * 0.01)), content.groceriesTitle, groceries, checking, nil, supermarketVendor)
            }
            if dayOffset % 6 == 2 {
                add(date, -cents(Double(targets.groceries) / 100.0 * 0.08), content.groceriesTitle, groceries, checking, nil, supermarketVendor)
            }
            if dayOffset % 5 == 1 {
                add(date, -cents(Double(targets.diningOut) / 100.0 * (0.16 + Double(dayOffset % 3) * 0.02)), content.diningOutTitle, dining, creditCard, nil, dayOffset % 10 == 1 ? mcdonaldsVendor : coffeeVendor)
            }
            if dayOffset % 3 == 0 {
                add(date, -cents(Double(targets.diningOut) / 100.0 * 0.06), content.diningOutTitle, dining, creditCard, nil, coffeeVendor)
            }
            if dayOffset % 7 == 3 {
                add(date, -cents(Double(targets.transport) / 100.0 * 0.12), content.transportCategory, transport, checking, nil, transportVendor)
            }
            if dayOffset % 9 == 4 {
                add(date, -cents(Double(targets.shopping) / 100.0 * 0.16), content.shoppingCategory, shopping, creditCard, nil, shoppingVendor)
            }
            if dayOffset % 13 == 5 {
                add(date, -cents(Double(targets.health) / 100.0 * 0.18), content.healthCategory, health, checking, nil, pharmacyVendor)
            }
            if dayOffset % 16 == 6 {
                add(date, -cents(Double(targets.toys) / 100.0 * 0.24), content.toysTitle, toys, checking, nil, shoppingVendor)
            }

            day = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: day)!
            dayOffset += 1
        }

        for date in ["2026-03-14", "2026-04-14", "2026-05-14"] {
            add(date, -Int64(Double(targets.subscriptions) * 0.45), "Netflix", subscriptions, creditCard, nil, netflixVendor)
        }
        for date in ["2026-03-12", "2026-04-12", "2026-05-12"] {
            add(date, -Int64(Double(targets.subscriptions) * 0.35), "Spotify", subscriptions, creditCard, nil, spotifyVendor)
        }
        for date in ["2026-03-08", "2026-04-08", "2026-05-08"] {
            add(date, -Int64(Double(targets.utilities) * 0.78), content.utilitiesCategory, utilities, checking, nil, utilitiesVendor)
        }

        for date in ["2026-03-15", "2026-03-29", "2026-04-12", "2026-04-26", "2026-05-10"] {
            add(date, Self.allowanceAmounts[localeID]!, content.allowanceTitle, allowanceCategory, checking, allowance, nil)
        }
        for date in ["2026-03-26", "2026-04-26"] {
            add(date, Self.savingsAmounts[localeID]!, content.savingsTitle, savingsCategory, checking, savings, nil)
        }

        add("2026-05-11", -Int64(Double(targets.groceries) * 0.23), content.groceriesTitle, groceries, checking, nil, supermarketVendor)
        add("2026-05-11", -Int64(Double(targets.diningOut) * 0.18), content.diningOutTitle, dining, creditCard, nil, coffeeVendor)
        add("2026-05-11", Int64(Double(targets.shopping) * 0.12), content.refundTitle, shopping, checking, nil, refundVendor)
        add("2026-05-12", -Int64(Double(targets.shopping) * 0.33), content.shoppingCategory, shopping, creditCard, nil, shoppingVendor)
        add("2026-05-12", -Int64(Double(targets.subscriptions) * 0.35), "Spotify", subscriptions, creditCard, nil, spotifyVendor)
        add("2026-05-12", -Int64(Double(targets.utilities) * 0.40), content.utilitiesCategory, utilities, checking, nil, utilitiesVendor)
        add("2026-05-13", -Int64(Double(targets.groceries) * 0.20), content.groceriesTitle, groceries, checking, nil, supermarketVendor)
        add("2026-05-13", -Int64(Double(targets.diningOut) * 0.15), content.diningOutTitle, dining, creditCard, nil, mcdonaldsVendor)
        add("2026-05-13", -Int64(Double(targets.health) * 0.15), content.healthCategory, health, checking, nil, pharmacyVendor)
        add("2026-05-14", -Int64(Double(targets.subscriptions) * 0.45), "Netflix", subscriptions, creditCard, nil, netflixVendor)
        add("2026-05-14", -Int64(Double(targets.transport) * 0.22), content.transportCategory, transport, checking, nil, transportVendor)
        add("2026-05-15", -Int64(Double(targets.groceries) * 0.29), content.groceriesTitle, groceries, checking, nil, supermarketVendor)
        add("2026-05-15", -Int64(Double(targets.diningOut) * 0.29), content.diningOutTitle, dining, creditCard, nil, coffeeVendor)
        add("2026-05-15", Self.savingsAmounts[localeID]!, content.savingsTitle, savingsCategory, checking, savings, nil)
        add("2026-05-15", Self.allowanceAmounts[localeID]!, content.allowanceTitle, allowanceCategory, checking, allowance, nil)
        add("2026-05-15", -Int64(Double(targets.toys) * 0.45), content.toysTitle, toys, checking, nil, shoppingVendor)
        add("2026-05-15", -Int64(Double(targets.transport) * 0.20), content.transportCategory, transport, checking, nil, transportVendor)

        return items.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.id.uuidString > rhs.id.uuidString }
            return lhs.date > rhs.date
        }
    }

    private static func date(_ value: String) -> Date {
        DateFormatter.apiDate.date(from: value)!
    }

    private static func format(_ date: Date) -> String {
        DateFormatter.apiDate.string(from: date)
    }
}

private extension ScreenshotDemoBuilder {
    static let localeContent: [ScreenshotLocaleID: ScreenshotLocaleContent] = [
        .enUS: ScreenshotLocaleContent(currency: "USD", currencySymbol: "$", currencyFormatExample: "$1,234.56", supermarket: "Walmart", employer: "Employer Inc.", salaryLabel: "Salary", salaryReceivedTitle: "Salary received", transferLabel: "Transfer", restaurantCategory: "Restaurant", supermarketCategory: "Supermarket", diningOutTitle: "Dining out", savingsTitle: "Savings", groceriesTitle: "Weekly groceries", toysTitle: "Toys", allowanceTitle: "Allowance payment", allowanceCategory: "Allowance", housingCategory: "Housing", transportCategory: "Transport", utilitiesCategory: "Utilities", subscriptionsCategory: "Subscriptions", shoppingCategory: "Shopping", healthCategory: "Health", refundTitle: "Refund", periodNameCurrent: "Current period", periodScheduleName: "Bi-weekly budget", automaticPeriodFrequency: "Bi-weekly"),
        .enGB: ScreenshotLocaleContent(currency: "GBP", currencySymbol: "£", currencyFormatExample: "£1,234.56", supermarket: "Tesco", employer: "Employer Ltd", salaryLabel: "Salary", salaryReceivedTitle: "Salary received", transferLabel: "Transfer", restaurantCategory: "Restaurant", supermarketCategory: "Supermarket", diningOutTitle: "Eating out", savingsTitle: "Savings", groceriesTitle: "Weekly shop", toysTitle: "Toys", allowanceTitle: "Pocket money payment", allowanceCategory: "Pocket money", housingCategory: "Housing", transportCategory: "Transport", utilitiesCategory: "Utilities", subscriptionsCategory: "Subscriptions", shoppingCategory: "Shopping", healthCategory: "Health", refundTitle: "Refund", periodNameCurrent: "Current period", periodScheduleName: "Fortnightly budget", automaticPeriodFrequency: "Fortnightly"),
        .ptBR: ScreenshotLocaleContent(currency: "BRL", currencySymbol: "R$", currencyFormatExample: "R$ 1.234,56", supermarket: "Pão de Açúcar", employer: "Empresa", salaryLabel: "Salário", salaryReceivedTitle: "Salário recebido", transferLabel: "Transferência", restaurantCategory: "Restaurante", supermarketCategory: "Supermercado", diningOutTitle: "Jantar fora", savingsTitle: "Poupança", groceriesTitle: "Compras da semana", toysTitle: "Brinquedos", allowanceTitle: "Pagamento da mesada", allowanceCategory: "Mesada", housingCategory: "Moradia", transportCategory: "Transporte", utilitiesCategory: "Contas", subscriptionsCategory: "Assinaturas", shoppingCategory: "Compras", healthCategory: "Saúde", refundTitle: "Reembolso", periodNameCurrent: "Período atual", periodScheduleName: "Orçamento quinzenal", automaticPeriodFrequency: "Quinzenal"),
        .ptPT: ScreenshotLocaleContent(currency: "EUR", currencySymbol: "€", currencyFormatExample: "1 234,56 €", supermarket: "Continente", employer: "Empresa", salaryLabel: "Salário", salaryReceivedTitle: "Salário recebido", transferLabel: "Transferência", restaurantCategory: "Restaurante", supermarketCategory: "Supermercado", diningOutTitle: "Jantar fora", savingsTitle: "Poupança", groceriesTitle: "Compras da semana", toysTitle: "Brinquedos", allowanceTitle: "Pagamento da mesada", allowanceCategory: "Mesada", housingCategory: "Habitação", transportCategory: "Transporte", utilitiesCategory: "Contas", subscriptionsCategory: "Subscrições", shoppingCategory: "Compras", healthCategory: "Saúde", refundTitle: "Reembolso", periodNameCurrent: "Período atual", periodScheduleName: "Orçamento quinzenal", automaticPeriodFrequency: "Quinzenal"),
        .esES: ScreenshotLocaleContent(currency: "EUR", currencySymbol: "€", currencyFormatExample: "1234,56 €", supermarket: "Mercadona", employer: "Empresa", salaryLabel: "Salario", salaryReceivedTitle: "Salario recibido", transferLabel: "Transferencia", restaurantCategory: "Restaurante", supermarketCategory: "Supermercado", diningOutTitle: "Cenar fuera", savingsTitle: "Ahorro", groceriesTitle: "Compra semanal", toysTitle: "Juguetes", allowanceTitle: "Pago de la paga", allowanceCategory: "Paga", housingCategory: "Vivienda", transportCategory: "Transporte", utilitiesCategory: "Facturas", subscriptionsCategory: "Suscripciones", shoppingCategory: "Compras", healthCategory: "Salud", refundTitle: "Reembolso", periodNameCurrent: "Periodo actual", periodScheduleName: "Presupuesto quincenal", automaticPeriodFrequency: "Quincenal"),
        .frFR: ScreenshotLocaleContent(currency: "EUR", currencySymbol: "€", currencyFormatExample: "1 234,56 €", supermarket: "Carrefour", employer: "Entreprise", salaryLabel: "Salaire", salaryReceivedTitle: "Salaire reçu", transferLabel: "Virement", restaurantCategory: "Restaurant", supermarketCategory: "Supermarché", diningOutTitle: "Dîner dehors", savingsTitle: "Épargne", groceriesTitle: "Courses de la semaine", toysTitle: "Jouets", allowanceTitle: "Versement de l’argent de poche", allowanceCategory: "Argent de poche", housingCategory: "Logement", transportCategory: "Transport", utilitiesCategory: "Factures", subscriptionsCategory: "Abonnements", shoppingCategory: "Achats", healthCategory: "Santé", refundTitle: "Remboursement", periodNameCurrent: "Période actuelle", periodScheduleName: "Budget bimensuel", automaticPeriodFrequency: "Bimensuel"),
        .nlNL: ScreenshotLocaleContent(currency: "EUR", currencySymbol: "€", currencyFormatExample: "€ 1.234,56", supermarket: "Albert Heijn", employer: "Werkgever", salaryLabel: "Salaris", salaryReceivedTitle: "Salaris ontvangen", transferLabel: "Overschrijving", restaurantCategory: "Restaurant", supermarketCategory: "Supermarkt", diningOutTitle: "Uit eten", savingsTitle: "Sparen", groceriesTitle: "Weekboodschappen", toysTitle: "Speelgoed", allowanceTitle: "Zakgeld betaald", allowanceCategory: "Zakgeld", housingCategory: "Wonen", transportCategory: "Vervoer", utilitiesCategory: "Rekeningen", subscriptionsCategory: "Abonnementen", shoppingCategory: "Winkelen", healthCategory: "Gezondheid", refundTitle: "Terugbetaling", periodNameCurrent: "Huidige periode", periodScheduleName: "Tweewekelijks budget", automaticPeriodFrequency: "Tweewekelijks"),
        .deDE: ScreenshotLocaleContent(currency: "EUR", currencySymbol: "€", currencyFormatExample: "1.234,56 €", supermarket: "EDEKA", employer: "Arbeitgeber", salaryLabel: "Gehalt", salaryReceivedTitle: "Gehalt erhalten", transferLabel: "Überweisung", restaurantCategory: "Restaurant", supermarketCategory: "Supermarkt", diningOutTitle: "Auswärts essen", savingsTitle: "Sparen", groceriesTitle: "Wocheneinkauf", toysTitle: "Spielzeug", allowanceTitle: "Taschengeld gezahlt", allowanceCategory: "Taschengeld", housingCategory: "Wohnen", transportCategory: "Transport", utilitiesCategory: "Rechnungen", subscriptionsCategory: "Abos", shoppingCategory: "Einkäufe", healthCategory: "Gesundheit", refundTitle: "Rückerstattung", periodNameCurrent: "Aktueller Zeitraum", periodScheduleName: "Zweiwöchiges Budget", automaticPeriodFrequency: "Zweiwöchig")
    ]

    static let frameCopy: [ScreenshotLocaleID: [ScreenshotStateID: ScreenshotFrameCopy]] = [
        .enUS: [.dashboardNebula: .init(title: "Stay on track", subtitle: "Category targets with real-time progress"), .dashboardElectricNeon: .init(title: "Make it yours", subtitle: "6 themes to match your style"), .dashboardTropical: .init(title: "Budget on your schedule", subtitle: "Weekly, bi-weekly, or custom periods"), .transactions: .init(title: "Track every transaction", subtitle: "Filter, search, and swipe to edit"), .periodConfiguration: .init(title: "Budget on your schedule", subtitle: "Weekly, bi-weekly, or custom periods"), .categories: .init(title: "Your finances at a glance", subtitle: "Spending, consistency, and net position")],
        .enGB: [.dashboardNebula: .init(title: "Stay on track", subtitle: "Category targets with real-time progress"), .dashboardElectricNeon: .init(title: "Make it yours", subtitle: "6 themes to match your style"), .dashboardTropical: .init(title: "Budget on your schedule", subtitle: "Weekly, fortnightly, or custom periods"), .transactions: .init(title: "Track every transaction", subtitle: "Filter, search, and swipe to edit"), .periodConfiguration: .init(title: "Budget on your schedule", subtitle: "Weekly, fortnightly, or custom periods"), .categories: .init(title: "Your finances at a glance", subtitle: "Spending, consistency, and net position")],
        .ptBR: [.dashboardNebula: .init(title: "Mantenha o controle", subtitle: "Metas por categoria com progresso em tempo real"), .dashboardElectricNeon: .init(title: "Deixe com a sua cara", subtitle: "6 temas para combinar com seu estilo"), .dashboardTropical: .init(title: "Orçamento no seu ritmo", subtitle: "Períodos semanais, quinzenais ou personalizados"), .transactions: .init(title: "Acompanhe cada transação", subtitle: "Filtre, pesquise e deslize para editar"), .periodConfiguration: .init(title: "Orçamento no seu ritmo", subtitle: "Períodos semanais, quinzenais ou personalizados"), .categories: .init(title: "Suas finanças em um olhar", subtitle: "Gastos, consistência e posição líquida")],
        .ptPT: [.dashboardNebula: .init(title: "Mantenha o controlo", subtitle: "Metas por categoria com progresso em tempo real"), .dashboardElectricNeon: .init(title: "Torne-a sua", subtitle: "6 temas para combinar com o seu estilo"), .dashboardTropical: .init(title: "Orçamento ao seu ritmo", subtitle: "Períodos semanais, quinzenais ou personalizados"), .transactions: .init(title: "Acompanhe cada transação", subtitle: "Filtre, pesquise e deslize para editar"), .periodConfiguration: .init(title: "Orçamento ao seu ritmo", subtitle: "Períodos semanais, quinzenais ou personalizados"), .categories: .init(title: "As suas finanças num relance", subtitle: "Despesas, consistência e posição líquida")],
        .esES: [.dashboardNebula: .init(title: "Mantén el control", subtitle: "Objetivos por categoría con progreso en tiempo real"), .dashboardElectricNeon: .init(title: "Hazla tuya", subtitle: "6 temas para adaptarse a tu estilo"), .dashboardTropical: .init(title: "Presupuesta a tu ritmo", subtitle: "Periodos semanales, quincenales o personalizados"), .transactions: .init(title: "Registra cada transacción", subtitle: "Filtra, busca y desliza para editar"), .periodConfiguration: .init(title: "Presupuesta a tu ritmo", subtitle: "Periodos semanales, quincenales o personalizados"), .categories: .init(title: "Tus finanzas de un vistazo", subtitle: "Gastos, consistencia y posición neta")],
        .frFR: [.dashboardNebula: .init(title: "Gardez le cap", subtitle: "Objectifs par catégorie avec progression en temps réel"), .dashboardElectricNeon: .init(title: "Personnalisez-la", subtitle: "6 thèmes pour s’adapter à votre style"), .dashboardTropical: .init(title: "Gérez votre budget à votre rythme", subtitle: "Périodes hebdomadaires, bimensuelles ou personnalisées"), .transactions: .init(title: "Suivez chaque transaction", subtitle: "Filtrez, recherchez et balayez pour modifier"), .periodConfiguration: .init(title: "Gérez votre budget à votre rythme", subtitle: "Périodes hebdomadaires, bimensuelles ou personnalisées"), .categories: .init(title: "Vos finances en un coup d’œil", subtitle: "Dépenses, régularité et position nette")],
        .nlNL: [.dashboardNebula: .init(title: "Houd grip", subtitle: "Categoriedoelen met realtime voortgang"), .dashboardElectricNeon: .init(title: "Maak het van jou", subtitle: "6 thema’s die passen bij je stijl"), .dashboardTropical: .init(title: "Budgetteren op jouw ritme", subtitle: "Wekelijkse, tweewekelijkse of aangepaste periodes"), .transactions: .init(title: "Houd elke transactie bij", subtitle: "Filter, zoek en veeg om te bewerken"), .periodConfiguration: .init(title: "Budgetteren op jouw ritme", subtitle: "Wekelijkse, tweewekelijkse of aangepaste periodes"), .categories: .init(title: "Je financiën in één oogopslag", subtitle: "Uitgaven, consistentie en netto positie")],
        .deDE: [.dashboardNebula: .init(title: "Behalte den Überblick", subtitle: "Kategorieziele mit Fortschritt in Echtzeit"), .dashboardElectricNeon: .init(title: "Mach es zu deinem", subtitle: "6 Designs passend zu deinem Stil"), .dashboardTropical: .init(title: "Budgetieren nach deinem Rhythmus", subtitle: "Wöchentliche, zweiwöchentliche oder individuelle Zeiträume"), .transactions: .init(title: "Erfasse jede Transaktion", subtitle: "Filtern, suchen und per Wisch bearbeiten"), .periodConfiguration: .init(title: "Budgetieren nach deinem Rhythmus", subtitle: "Wöchentliche, zweiwöchentliche oder individuelle Zeiträume"), .categories: .init(title: "Deine Finanzen auf einen Blick", subtitle: "Ausgaben, Konsistenz und Nettoposition")]
    ]

    static let accountNames: [ScreenshotLocaleID: ScreenshotAccountNames] = [
        .enUS: .init(checking: "Everyday Checking", savings: "Emergency Savings", creditCard: "Credit Card", allowance: "Kids Allowance"),
        .enGB: .init(checking: "Current Account", savings: "Emergency Savings", creditCard: "Credit Card", allowance: "Pocket Money"),
        .ptBR: .init(checking: "Conta corrente", savings: "Reserva de emergência", creditCard: "Cartão de crédito", allowance: "Mesada"),
        .ptPT: .init(checking: "Conta à ordem", savings: "Fundo de emergência", creditCard: "Cartão de crédito", allowance: "Mesada"),
        .esES: .init(checking: "Cuenta corriente", savings: "Fondo de emergencia", creditCard: "Tarjeta de crédito", allowance: "Paga"),
        .frFR: .init(checking: "Compte courant", savings: "Épargne de précaution", creditCard: "Carte de crédit", allowance: "Argent de poche"),
        .nlNL: .init(checking: "Betaalrekening", savings: "Noodbuffer", creditCard: "Creditcard", allowance: "Zakgeld"),
        .deDE: .init(checking: "Girokonto", savings: "Notgroschen", creditCard: "Kreditkarte", allowance: "Taschengeld")
    ]

    static let openingBalances: [ScreenshotLocaleID: ScreenshotMoneySet] = [
        .enUS: .init(checking: 284075, savings: 875000, creditCard: -64235, allowance: 4200),
        .enGB: .init(checking: 216040, savings: 640000, creditCard: -38820, allowance: 3500),
        .ptBR: .init(checking: 438065, savings: 1250000, creditCard: -118040, allowance: 6500),
        .ptPT: .init(checking: 126080, savings: 420000, creditCard: -26570, allowance: 2800),
        .esES: .init(checking: 132050, savings: 460000, creditCard: -31025, allowance: 3000),
        .frFR: .init(checking: 174090, savings: 580000, creditCard: -35560, allowance: 3400),
        .nlNL: .init(checking: 238025, savings: 720000, creditCard: -42015, allowance: 3800),
        .deDE: .init(checking: 226035, savings: 690000, creditCard: -40580, allowance: 3600)
    ]

    static let budgetTargets: [ScreenshotLocaleID: ScreenshotBudgetTargets] = [
        .enUS: .init(groceries: 32000, diningOut: 14000, transport: 11000, housing: 110000, utilities: 18000, subscriptions: 6500, shopping: 18000, toys: 6000, health: 9000, savings: 25000),
        .enGB: .init(groceries: 23000, diningOut: 10000, transport: 9500, housing: 85000, utilities: 15000, subscriptions: 5500, shopping: 13000, toys: 4500, health: 7000, savings: 20000),
        .ptBR: .init(groceries: 85000, diningOut: 26000, transport: 32000, housing: 220000, utilities: 42000, subscriptions: 9500, shopping: 35000, toys: 12000, health: 18000, savings: 40000),
        .ptPT: .init(groceries: 21000, diningOut: 8500, transport: 7500, housing: 70000, utilities: 12000, subscriptions: 4500, shopping: 11000, toys: 4000, health: 5500, savings: 15000),
        .esES: .init(groceries: 22000, diningOut: 9000, transport: 8000, housing: 72000, utilities: 12500, subscriptions: 4500, shopping: 11500, toys: 4000, health: 6000, savings: 15000),
        .frFR: .init(groceries: 25000, diningOut: 11000, transport: 9500, housing: 85000, utilities: 15000, subscriptions: 5500, shopping: 13000, toys: 4500, health: 7000, savings: 18000),
        .nlNL: .init(groceries: 28000, diningOut: 12000, transport: 11000, housing: 105000, utilities: 18000, subscriptions: 6000, shopping: 15000, toys: 5000, health: 8000, savings: 20000),
        .deDE: .init(groceries: 26000, diningOut: 11000, transport: 9500, housing: 95000, utilities: 17000, subscriptions: 5500, shopping: 14000, toys: 4500, health: 7500, savings: 20000)
    ]

    static let vendors: [ScreenshotLocaleID: ScreenshotVendorContent] = [
        .enUS: .init(coffee: "Starbucks", transport: "Uber", utilities: "Con Edison", subscription1: "Netflix", subscription2: "Spotify", shopping: "Target", pharmacy: "CVS", rent: "Rent", refundVendor: "Target"),
        .enGB: .init(coffee: "Costa Coffee", transport: "Transport for London", utilities: "British Gas", subscription1: "Netflix", subscription2: "Spotify", shopping: "Boots", pharmacy: "Boots", rent: "Rent", refundVendor: "Tesco"),
        .ptBR: .init(coffee: "Starbucks", transport: "Uber", utilities: "Enel", subscription1: "Netflix", subscription2: "Spotify", shopping: "Lojas Renner", pharmacy: "Drogasil", rent: "Aluguel", refundVendor: "Pão de Açúcar"),
        .ptPT: .init(coffee: "Starbucks", transport: "CP", utilities: "EDP", subscription1: "Netflix", subscription2: "Spotify", shopping: "Worten", pharmacy: "Farmácia", rent: "Renda", refundVendor: "Continente"),
        .esES: .init(coffee: "Starbucks", transport: "Renfe", utilities: "Iberdrola", subscription1: "Netflix", subscription2: "Spotify", shopping: "El Corte Inglés", pharmacy: "Farmacia", rent: "Alquiler", refundVendor: "Mercadona"),
        .frFR: .init(coffee: "Starbucks", transport: "SNCF", utilities: "EDF", subscription1: "Netflix", subscription2: "Spotify", shopping: "Fnac", pharmacy: "Pharmacie", rent: "Loyer", refundVendor: "Carrefour"),
        .nlNL: .init(coffee: "Starbucks", transport: "NS", utilities: "Eneco", subscription1: "Netflix", subscription2: "Spotify", shopping: "HEMA", pharmacy: "Etos", rent: "Huur", refundVendor: "Albert Heijn"),
        .deDE: .init(coffee: "Starbucks", transport: "Deutsche Bahn", utilities: "Vattenfall", subscription1: "Netflix", subscription2: "Spotify", shopping: "dm", pharmacy: "Apotheke", rent: "Miete", refundVendor: "EDEKA")
    ]

    static let salaryAmounts: [ScreenshotLocaleID: Int64] = [.enUS: 420000, .enGB: 320000, .ptBR: 680000, .ptPT: 185000, .esES: 190000, .frFR: 240000, .nlNL: 310000, .deDE: 300000]
    static let rentAmounts: [ScreenshotLocaleID: Int64] = [.enUS: -110000, .enGB: -85000, .ptBR: -220000, .ptPT: -70000, .esES: -72000, .frFR: -85000, .nlNL: -105000, .deDE: -95000]
    static let allowanceAmounts: [ScreenshotLocaleID: Int64] = [.enUS: -3000, .enGB: -2500, .ptBR: -5000, .ptPT: -2000, .esES: -2000, .frFR: -2500, .nlNL: -2500, .deDE: -2500]
    static let savingsAmounts: [ScreenshotLocaleID: Int64] = [.enUS: -25000, .enGB: -20000, .ptBR: -40000, .ptPT: -15000, .esES: -15000, .frFR: -18000, .nlNL: -20000, .deDE: -20000]
}

extension EncryptedDataStore {
    func applyScreenshotProfile(_ profile: ScreenshotDemoProfile) {
        accounts = profile.accounts
        categories = profile.categories
        vendors = profile.vendorItems
        subscriptions = profile.subscriptions
        targets = profile.targets
        periodTransactions = profile.activeTransactions
        isLoaded = true
        isScreenshotDemoData = true
    }
}

struct ScreenshotStateView: View {
    @EnvironmentObject var appState: AppState
    let configuration: ScreenshotModeConfiguration

    var body: some View {
        Group {
            switch configuration.stateID.destination {
            case .dashboard:
                DashboardView()
            case .transactions:
                TransactionsView()
            case .periodConfiguration:
                ScreenshotPeriodConfigurationView()
            case .categories:
                NavigationStack {
                    CategoriesView()
                }
            }
        }
        .environmentObject(appState)
        .accessibilityIdentifier(configuration.stateID.screenshotAccessibilityIdentifier)
        .overlay(alignment: .topLeading) {
            Text("screenshot.ready")
                .font(.system(size: 1))
                .foregroundColor(.clear)
                .accessibilityIdentifier("screenshot.ready")
                .accessibilityLabel("screenshot.ready")
                .allowsHitTesting(false)
        }
    }
}

struct ScreenshotPeriodConfigurationView: View {
    enum Route: Hashable {
        case autoCreation
    }

    @State private var path: [Route] = [.autoCreation]

    var body: some View {
        NavigationStack(path: $path) {
            Color.ppBackground
                .ignoresSafeArea()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .autoCreation:
                        AutoCreationView(screenshotSchedule: Self.schedule)
                    }
                }
        }
    }

    private static let schedule = PeriodSchedule(
        id: UUID(uuidString: "00000000-0500-0000-0500-000000000001")!,
        scheduleType: "automatic",
        recurrenceMethod: "dayOfMonth",
        startDayOfTheMonth: 25,
        periodDuration: 1,
        durationUnit: "months",
        saturdayPolicy: "keep",
        sundayPolicy: "keep",
        namePattern: "{MONTH} {YEAR}",
        generateAhead: 3
    )
}
