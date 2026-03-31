import SwiftUI

struct NetPositionCard: View {
    let data: DashboardNetPosition
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.netPosition.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(data.total, code: currencyCode))
                .font(.ppAmount)
                .foregroundColor(theme.tertiary)

            HStack(spacing: PPSpacing.sm) {
                let prefix = data.differenceThisPeriod >= 0 ? "+" : ""
                Text("\(prefix)\(formatCurrency(data.differenceThisPeriod, code: currencyCode))")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)

                Text("·").foregroundColor(.ppTextTertiary)

                Text(String(localized: "widget.netPosition.accounts \(data.numberOfAccounts)"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
            }

            // Breakdown bar
            if data.total != 0 {
                let total = abs(data.liquidAmount) + abs(data.protectedAmount) + abs(data.debtAmount)
                if total > 0 {
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            if data.liquidAmount != 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.tertiary)
                                    .frame(width: geo.size.width * fraction(abs(data.liquidAmount), of: total))
                            }
                            if data.protectedAmount != 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.primary)
                                    .frame(width: geo.size.width * fraction(abs(data.protectedAmount), of: total))
                            }
                            if data.debtAmount != 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.secondary)
                                    .frame(width: geo.size.width * fraction(abs(data.debtAmount), of: total))
                            }
                        }
                    }
                    .frame(height: 6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "accessibility.netPosition.breakdown \(formatCurrency(data.liquidAmount, code: currencyCode)) \(formatCurrency(data.protectedAmount, code: currencyCode)) \(formatCurrency(data.debtAmount, code: currencyCode))"))
                }
            }

            HStack(spacing: 0) {
                Text(String(localized: "widget.netPosition.liquid"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text(" \(formatCurrency(data.liquidAmount, code: currencyCode))")
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text(" · ").foregroundColor(.ppTextTertiary).font(.ppCaption)
                Text(String(localized: "widget.netPosition.protected"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text(" \(formatCurrency(data.protectedAmount, code: currencyCode))")
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text(" · ").foregroundColor(.ppTextTertiary).font(.ppCaption)
                Text(String(localized: "widget.netPosition.debt"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text(" \(formatCurrency(data.debtAmount, code: currencyCode))")
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
            }
        }
        .dashboardCard()
    }

    private func fraction(_ value: Int64, of total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
}
