import SwiftUI

struct RecentTransactionsCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("RECENT TRANSACTIONS")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.ppBody)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            } else {
                ForEach(transactions.prefix(5)) { tx in
                    transactionRow(tx)
                    if tx.id != transactions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary(colorScheme))
                    .lineLimit(1)
                Text(tx.formattedDate)
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            }
            Spacer()
            Text(formatCurrency(tx.amount, code: appState.currencyCode))
                .font(.ppHeadline)
                .foregroundColor(tx.isIncoming ? .ppSuccess : .ppTextPrimary(colorScheme))
        }
    }
}
