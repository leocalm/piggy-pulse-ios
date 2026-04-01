import SwiftUI

struct CashFlowCard: View {
    let data: DashboardCashFlow
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.cashFlow.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            HStack(spacing: PPSpacing.sm) {
                cashFlowColumn(
                    label: String(localized: "widget.cashFlow.inflows"),
                    value: formatCurrency(data.inflows, code: currencyCode),
                    color: .ppTextPrimary
                )

                cashFlowColumn(
                    label: String(localized: "widget.cashFlow.outflows"),
                    value: formatCurrency(data.outflows, code: currencyCode),
                    color: .ppTextPrimary
                )

                cashFlowColumn(
                    label: String(localized: "widget.cashFlow.net"),
                    value: "\(data.net >= 0 ? "+" : "")\(formatCurrency(data.net, code: currencyCode))",
                    color: theme.primary
                )
            }
        }
        .dashboardCard()
    }

    private func cashFlowColumn(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label)
                .font(.ppCaption)
                .foregroundColor(.ppTextSecondary)
            Text(value)
                .font(.ppHeadline)
                .fontDesign(.monospaced)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
