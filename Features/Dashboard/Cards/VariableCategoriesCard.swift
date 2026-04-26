import SwiftUI

struct VariableCategoriesCard: View {
    let data: DashboardVariableCategories
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                Text(String(localized: "widget.variableSpending.name").uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                Text("\(formatCurrency(data.totalSpent, code: currencyCode)) / \(formatCurrency(data.totalBudgeted, code: currencyCode))")
                    .font(.ppCaption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextTertiary)
            }

            if data.categories.isEmpty {
                Text(String(localized: "widget.variableSpending.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                ForEach(data.categories, id: \.id) { cat in
                    HStack {
                        Text(cat.icon).font(.system(size: 16))
                        Text(cat.name)
                            .font(.ppCallout)
                            .foregroundColor(.ppTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(formatCurrency(cat.spent, code: currencyCode))")
                            .font(.ppCaption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.ppTextSecondary)
                        if cat.budgeted > 0 {
                            let pct = min(Double(cat.spent) / Double(cat.budgeted), 1.0)
                            ProgressView(value: pct)
                                .tint(theme.primary)
                                .frame(width: 40)
                        }
                    }
                }
            }
        }
        .dashboardCard()
    }
}
