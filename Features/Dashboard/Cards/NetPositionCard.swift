import SwiftUI

struct NetPositionCard: View {
    let data: DashboardNetPosition
    let accounts: [AccountListItem]
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            // Header
            HStack {
                Text(String(localized: "widget.netPosition.name").uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                Text("\(data.numberOfAccounts) \(String(localized: "widget.netPosition.accountsLabel"))")
                    .font(.ppCaption)
                    .foregroundColor(theme.primary)
            }

            // Total
            Text(formatCurrency(data.total, code: currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary)
                .accessibilityIdentifier("dashboard-net-position-value")

            // Change this period
            let prefix = data.differenceThisPeriod >= 0 ? "+" : ""
            Text("\(prefix)\(formatCurrency(data.differenceThisPeriod, code: currencyCode)) \(String(localized: "widget.netPosition.thisPeriod"))")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Breakdown bar
            let total = abs(data.liquidAmount) + abs(data.protectedAmount) + abs(data.debtAmount)
            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if data.liquidAmount != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.tertiary)
                                .frame(width: max(4, geo.size.width * fraction(abs(data.liquidAmount), of: total)))
                        }
                        if data.protectedAmount != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.primary)
                                .frame(width: max(4, geo.size.width * fraction(abs(data.protectedAmount), of: total)))
                        }
                        if data.debtAmount != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.secondary)
                                .frame(width: max(4, geo.size.width * fraction(abs(data.debtAmount), of: total)))
                        }
                    }
                }
                .frame(height: 6)
            }

            // Liquid / Protected / Debt boxes
            HStack(spacing: PPSpacing.sm) {
                breakdownBox(color: theme.tertiary, label: String(localized: "widget.netPosition.liquid"), amount: data.liquidAmount)
                breakdownBox(color: theme.primary, label: String(localized: "widget.netPosition.protected"), amount: data.protectedAmount)
                breakdownBox(color: theme.secondary, label: String(localized: "widget.netPosition.debt"), amount: data.debtAmount)
            }

            // Individual account list
            if !accounts.isEmpty {
                VStack(spacing: PPSpacing.sm) {
                    ForEach(accounts.filter { $0.status == "active" }) { account in
                        HStack(spacing: PPSpacing.sm) {
                            Circle()
                                .fill(accountColor(account.type))
                                .frame(width: 8, height: 8)
                            Text(account.name)
                                .font(.ppCallout)
                                .fontWeight(.medium)
                                .foregroundColor(.ppTextPrimary)
                            Text(account.type)
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary)
                            Spacer()
                            Text(formatCurrency(account.currentBalance, code: currencyCode))
                                .font(.ppCallout)
                                .fontDesign(.monospaced)
                                .foregroundColor(.ppTextPrimary)
                        }
                    }
                }
            }
        }
        .dashboardCard()
    }

    private func breakdownBox(color: Color, label: String, amount: Int64) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            HStack(spacing: PPSpacing.xs) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.ppTextTertiary)
                    .tracking(0.5)
            }
            Text(formatCurrency(amount, code: currencyCode).replacingOccurrences(of: "\u{00a0}", with: " "))
                .font(.ppCallout)
                .fontDesign(.monospaced)
                .foregroundColor(.ppTextPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.sm)
        .background(Color.ppElevated)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
    }

    private func accountColor(_ type: String) -> Color {
        switch type {
        case "creditcard": return theme.secondary
        case "savings": return theme.primary
        case "allowance": return theme.secondary
        default: return theme.tertiary
        }
    }

    private func fraction(_ value: Int64, of total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
}
