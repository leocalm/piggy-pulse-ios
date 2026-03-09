import SwiftUI

struct NetPositionCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let net: NetPosition

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("NET POSITION")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            Text(formatCurrency(net.totalNetPosition, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppCyan)

            HStack(spacing: PPSpacing.sm) {
                let changePrefix = net.changeThisPeriod >= 0 ? "+" : ""
                Text("\(changePrefix)\(formatCurrency(net.changeThisPeriod, code: appState.currencyCode)) this period")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary(colorScheme))

                Text("\u{00B7}")
                    .foregroundColor(.ppTextTertiary(colorScheme))

                Text("Across \(net.accountCount) accounts")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary(colorScheme))
            }

            if net.totalNetPosition != 0 {
                let total = abs(net.liquidBalance) + abs(net.protectedBalance) + abs(net.debtBalance)
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if net.liquidBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppCyan)
                                .frame(width: geo.size.width * barFraction(abs(net.liquidBalance), of: total))
                        }
                        if net.protectedBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppPrimary)
                                .frame(width: geo.size.width * barFraction(abs(net.protectedBalance), of: total))
                        }
                        if net.debtBalance != 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.ppAmber)
                                .frame(width: geo.size.width * barFraction(abs(net.debtBalance), of: total))
                        }
                    }
                }
                .frame(height: 6)
            }

            Text("Liquid \(formatCurrency(net.liquidBalance, code: appState.currencyCode)) \u{00B7} Protected \(formatCurrency(net.protectedBalance, code: appState.currencyCode)) \u{00B7} Debt \(formatCurrency(net.debtBalance, code: appState.currencyCode))")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary(colorScheme))
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }

    private func barFraction(_ value: Int64, of total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
}
