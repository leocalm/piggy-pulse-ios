import SwiftUI

struct AccountSummaryCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let account: AccountListItem

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                Text(account.icon)
                    .font(.title2)
                Text(account.name.uppercased())
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary(colorScheme))
                    .tracking(1)
            }

            Text(formatCurrency(account.balance, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary(colorScheme))

            HStack(spacing: PPSpacing.sm) {
                Image(systemName: account.balanceChangeThisPeriod >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.ppCaption)
                    .foregroundColor(account.balanceChangeThisPeriod >= 0 ? .ppSuccess : .ppDestructive)
                Text("\(formatCurrency(abs(account.balanceChangeThisPeriod), code: appState.currencyCode)) this period")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary(colorScheme))
            }

            Text("\(account.transactionCount) transactions")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary(colorScheme))
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color(hex: account.color)?.opacity(0.4) ?? Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }
}
