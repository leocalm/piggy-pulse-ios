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

            HStack(spacing: PPSpacing.xl) {
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text(String(localized: "widget.cashFlow.inflows"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                    Text(formatCurrency(data.inflows, code: currencyCode))
                        .font(.ppAmountSmall)
                        .foregroundColor(.ppTextPrimary)
                }

                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text(String(localized: "widget.cashFlow.outflows"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                    Text(formatCurrency(data.outflows, code: currencyCode))
                        .font(.ppAmountSmall)
                        .foregroundColor(.ppTextPrimary)
                }

                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text(String(localized: "widget.cashFlow.net"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                    let prefix = data.net >= 0 ? "+" : ""
                    Text("\(prefix)\(formatCurrency(data.net, code: currencyCode))")
                        .font(.ppAmountSmall)
                        .foregroundColor(theme.primary)
                }
            }
        }
        .dashboardCard()
    }
}
