import SwiftUI

struct FixedCategoriesCard: View {
    let data: DashboardFixedCategories
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                Text(String(localized: "widget.fixedCategories.name").uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                Text("\(formatCurrency(data.totalPaid, code: currencyCode)) / \(formatCurrency(data.totalBudgeted, code: currencyCode))")
                    .font(.ppCaption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextTertiary)
            }

            if data.categories.isEmpty {
                Text(String(localized: "widget.fixedCategories.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
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
