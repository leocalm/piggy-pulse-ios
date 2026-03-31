import SwiftUI

struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.recentTransactions.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            if transactions.isEmpty {
                Text(String(localized: "widget.recentTransactions.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, txn in
                    HStack {
                        Text(txn.category.icon)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description.isEmpty ? (txn.vendor?.name ?? txn.category.name) : txn.description)
                                .font(.ppCallout)
                                .foregroundColor(.ppTextPrimary)
                                .lineLimit(1)
                            Text(formatDateString(txn.date))
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary)
                        }

                        Spacer()

                        let prefix = txn.category.type == "income" ? "+" : ""
                        Text("\(prefix)\(formatCurrency(txn.amount, code: currencyCode))")
                            .font(.ppCallout)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                            .foregroundColor(.ppTextPrimary)
                    }

                    if index < transactions.count - 1 {
                        Divider().background(Color.ppBorder)
                    }
                }
            }
        }
        .dashboardCard()
    }
}
