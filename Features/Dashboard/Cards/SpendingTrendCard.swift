import SwiftUI

struct SpendingTrendCard: View {
    let data: DashboardSpendingTrend
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    // Show last 6 periods max
    private var displayPeriods: [SpendingTrendItem] {
        Array(data.periods.suffix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.spendingTrend.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            if displayPeriods.isEmpty {
                Text(String(localized: "widget.spendingTrend.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                // Simple bar chart
                let maxSpend = displayPeriods.map(\.totalSpent).max() ?? 1
                HStack(alignment: .bottom, spacing: PPSpacing.sm) {
                    ForEach(displayPeriods, id: \.periodId) { item in
                        VStack(spacing: PPSpacing.xs) {
                            let height = maxSpend > 0 ? CGFloat(item.totalSpent) / CGFloat(maxSpend) * 80 : 0
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.primary)
                                .frame(height: max(4, height))

                            Text(shortLabel(item.periodName))
                                .font(.system(size: 9))
                                .foregroundColor(.ppTextTertiary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(item.periodName): \(formatCurrency(item.totalSpent, code: currencyCode))")
                    }
                }

                Text(String(localized: "widget.spendingTrend.average \(formatCurrency(data.periodAverage, code: currencyCode))"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary)
            }
        }
        .dashboardCard()
    }

    /// Convert period name (e.g. "August 2025") to localized short month ("Ago")
    private func shortLabel(_ name: String) -> String {
        // Try parsing "Month Year" format with English month names
        let enFormatter = DateFormatter()
        enFormatter.locale = Locale(identifier: "en_US")
        enFormatter.dateFormat = "MMMM yyyy"
        if let date = enFormatter.date(from: name) {
            let shortFormatter = DateFormatter()
            shortFormatter.locale = Locale.current
            shortFormatter.dateFormat = "MMM"
            return shortFormatter.string(from: date)
        }
        // Fallback: first 3 chars
        return String(name.prefix(3))
    }
}
