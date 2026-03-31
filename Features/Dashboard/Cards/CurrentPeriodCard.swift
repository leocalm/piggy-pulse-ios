import SwiftUI

struct CurrentPeriodCard: View {
    let data: DashboardCurrentPeriod
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.currentPeriod.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(data.spent, code: currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary)

            Text(String(localized: "widget.currentPeriod.ofTarget \(formatCurrency(data.target, code: currencyCode))"))
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            Text(String(localized: "widget.currentPeriod.remaining \(data.daysRemaining)"))
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)

            // Progress bar
            GeometryReader { geo in
                let pct = data.target > 0 ? min(Double(data.spent) / Double(data.target), 1.0) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.primary)
                        .frame(width: geo.size.width * pct, height: 6)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "accessibility.currentPeriod.progress \(Int(pct * 100))"))
            }
            .frame(height: 6)

            Text(String(localized: "widget.currentPeriod.projected \(formatCurrency(data.projectedSpend, code: currencyCode))"))
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary)
        }
        .dashboardCard(highlighted: true)
    }
}
