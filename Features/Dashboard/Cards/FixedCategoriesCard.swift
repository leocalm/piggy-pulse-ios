import SwiftUI

struct FixedCategoriesCard: View {
    let data: DashboardFixedCategories
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                Text(String(localized: "widget.fixedSpending.name").uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                let totalBudgeted = data.totalBudgeted + data.allowanceTotalBudgeted
                let totalPaid = data.totalPaid + data.allowanceTotalPaid
                Text("\(formatCurrency(totalPaid, code: currencyCode)) / \(formatCurrency(totalBudgeted, code: currencyCode))")
                    .font(.ppCaption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextTertiary)
            }

            if data.categories.isEmpty && data.allowances.isEmpty {
                Text(String(localized: "widget.fixedSpending.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                // Fixed category items
                ForEach(data.categories, id: \.id) { cat in
                    HStack {
                        Image(systemName: statusIcon(cat.status))
                            .font(.system(size: 14))
                            .foregroundColor(statusColor(cat.status))

                        Text(cat.name)
                            .font(.ppCallout)
                            .foregroundColor(.ppTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(formatCurrency(cat.paid, code: currencyCode))
                            .font(.ppCaption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.ppTextSecondary)
                    }
                }

                // Allowance envelope items
                if !data.allowances.isEmpty {
                    if !data.categories.isEmpty {
                        Divider()
                            .overlay(Color.ppBorder)
                    }

                    ForEach(data.allowances, id: \.id) { allowance in
                        HStack {
                            Image(systemName: statusIcon(allowance.status))
                                .font(.system(size: 14))
                                .foregroundColor(statusColor(allowance.status))

                            Text(allowance.name)
                                .font(.ppCallout)
                                .foregroundColor(.ppTextPrimary)
                                .lineLimit(1)

                            Text(String(localized: "widget.fixedSpending.allowance"))
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary)

                            Spacer()

                            Text(formatCurrency(allowance.paid, code: currencyCode))
                                .font(.ppCaption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.ppTextSecondary)
                        }
                    }
                }
            }
        }
        .dashboardCard()
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "paid": return "checkmark.circle.fill"
        case "partial": return "circle.bottomhalf.filled"
        default: return "circle"
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "paid": return theme.primary
        case "partial": return theme.secondary
        default: return .ppTextTertiary
        }
    }
}
