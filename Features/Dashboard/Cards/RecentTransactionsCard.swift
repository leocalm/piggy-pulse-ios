import SwiftUI

struct RecentTransactionsCard: View {
    let transactions: [RecentTransactionItem]
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
                ForEach(transactions, id: \.id) { txn in
                    HStack {
                        if let icon = txn.categoryIcon {
                            Text(icon).font(.system(size: 20))
                        } else {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 14))
                                .foregroundColor(.ppTextTertiary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description ?? txn.vendorName ?? txn.categoryName ?? "—")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextPrimary)
                                .lineLimit(1)
                            Text(txn.date)
                                .font(.ppCaption)
                                .foregroundColor(.ppTextTertiary)
                        }

                        Spacer()

                        let prefix = txn.transactionType == "income" ? "+" : ""
                        Text("\(prefix)\(formatCurrency(txn.amount, code: currencyCode))")
                            .font(.ppCallout)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                            .foregroundColor(.ppTextPrimary)
                    }

                    if txn.id != transactions.last?.id {
                        Divider().background(Color.ppBorder)
                    }
                }
            }
        }
        .dashboardCard()
    }
}
