import SwiftUI

struct SpendingTrendCard: View {
    let data: DashboardSpendingTrend
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.spendingTrend.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            if data.periods.isEmpty {
                Text(String(localized: "widget.spendingTrend.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                // Simple bar chart
                let maxSpend = data.periods.map(\.totalSpent).max() ?? 1
                HStack(alignment: .bottom, spacing: PPSpacing.sm) {
                    ForEach(data.periods, id: \.periodId) { item in
                        VStack(spacing: PPSpacing.xs) {
                            let height = maxSpend > 0 ? CGFloat(item.totalSpent) / CGFloat(maxSpend) * 80 : 0
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.primary)
                                .frame(width: 24, height: max(4, height))

                            Text(item.periodName)
                                .font(.system(size: 9))
                                .foregroundColor(.ppTextTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Text(String(localized: "widget.spendingTrend.average \(formatCurrency(data.periodAverage, code: currencyCode))"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary)
            }
        }
        .dashboardCard()
    }
}
