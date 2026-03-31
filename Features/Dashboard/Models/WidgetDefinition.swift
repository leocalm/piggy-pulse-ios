import Foundation

/// Defines a dashboard widget's metadata.
struct WidgetDefinition: Identifiable {
    let id: String
    let sfSymbol: String
    let nameKey: String
    let descriptionKey: String
    let defaultVisible: Bool
    let isHero: Bool

    var name: String { String(localized: String.LocalizationValue(nameKey)) }
    var description: String { String(localized: String.LocalizationValue(descriptionKey)) }
}

/// All available dashboard widgets.
let widgetDefinitions: [WidgetDefinition] = [
    WidgetDefinition(
        id: "getting_started",
        sfSymbol: "rocket.fill",
        nameKey: "widget.gettingStarted.name",
        descriptionKey: "widget.gettingStarted.desc",
        defaultVisible: true,
        isHero: true
    ),
    WidgetDefinition(
        id: "current_period",
        sfSymbol: "chart.bar.fill",
        nameKey: "widget.currentPeriod.name",
        descriptionKey: "widget.currentPeriod.desc",
        defaultVisible: true,
        isHero: true
    ),
    WidgetDefinition(
        id: "net_position",
        sfSymbol: "banknote.fill",
        nameKey: "widget.netPosition.name",
        descriptionKey: "widget.netPosition.desc",
        defaultVisible: true,
        isHero: true
    ),
    WidgetDefinition(
        id: "cash_flow",
        sfSymbol: "arrow.left.arrow.right",
        nameKey: "widget.cashFlow.name",
        descriptionKey: "widget.cashFlow.desc",
        defaultVisible: true,
        isHero: false
    ),
    WidgetDefinition(
        id: "recent_transactions",
        sfSymbol: "list.bullet.rectangle",
        nameKey: "widget.recentTransactions.name",
        descriptionKey: "widget.recentTransactions.desc",
        defaultVisible: true,
        isHero: false
    ),
    WidgetDefinition(
        id: "spending_trend",
        sfSymbol: "chart.line.uptrend.xyaxis",
        nameKey: "widget.spendingTrend.name",
        descriptionKey: "widget.spendingTrend.desc",
        defaultVisible: false,
        isHero: false
    ),
    WidgetDefinition(
        id: "top_vendors",
        sfSymbol: "storefront.fill",
        nameKey: "widget.topVendors.name",
        descriptionKey: "widget.topVendors.desc",
        defaultVisible: false,
        isHero: false
    ),
    WidgetDefinition(
        id: "variable_categories",
        sfSymbol: "slider.horizontal.3",
        nameKey: "widget.variableCategories.name",
        descriptionKey: "widget.variableCategories.desc",
        defaultVisible: true,
        isHero: false
    ),
    WidgetDefinition(
        id: "fixed_categories",
        sfSymbol: "checkmark.rectangle.fill",
        nameKey: "widget.fixedCategories.name",
        descriptionKey: "widget.fixedCategories.desc",
        defaultVisible: false,
        isHero: false
    ),
    WidgetDefinition(
        id: "subscriptions",
        sfSymbol: "repeat",
        nameKey: "widget.subscriptions.name",
        descriptionKey: "widget.subscriptions.desc",
        defaultVisible: false,
        isHero: false
    ),
]

let defaultWidgetOrder: [String] = widgetDefinitions.map(\.id)
let defaultHiddenWidgets: Set<String> = Set(widgetDefinitions.filter { !$0.defaultVisible }.map(\.id))
