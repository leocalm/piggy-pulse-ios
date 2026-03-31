import SwiftUI

struct SubscriptionsCard: View {
    let data: DashboardSubscriptions
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                Text(String(localized: "widget.subscriptions.name").uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                Text(String(localized: "widget.subscriptions.monthly \(formatCurrency(data.monthlyCost, code: currencyCode))"))
                    .font(.ppCaption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextTertiary)
            }

            if data.items.isEmpty {
                Text(String(localized: "widget.subscriptions.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                ForEach(data.items, id: \.id) { sub in
                    HStack {
                        Circle()
                            .fill(statusColor(sub.displayStatus))
                            .frame(width: 8, height: 8)

                        Text(sub.name)
                            .font(.ppCallout)
                            .foregroundColor(.ppTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(formatCurrency(sub.billingAmount, code: currencyCode))
                            .font(.ppCaption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.ppTextSecondary)

                        if let date = sub.nextChargeDate {
                            Text(date)
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary)
                        }
                    }
                }
            }
        }
        .dashboardCard()
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "charged": return theme.primary
        case "today": return theme.secondary
        default: return .ppTextTertiary
        }
    }
}
