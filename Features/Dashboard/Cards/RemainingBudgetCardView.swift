import SwiftUI

struct RemainingBudgetCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let burnIn: MonthlyBurnIn
    let progress: MonthProgress

    private var remainingPerDay: Int64 {
        guard progress.remainingDays > 0 else { return 0 }
        return burnIn.remainingBudget / Int64(progress.remainingDays)
    }

    private var isNegative: Bool {
        burnIn.remainingBudget < 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("REMAINING BUDGET")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            Text(formatCurrency(burnIn.remainingBudget, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(isNegative ? .ppDestructive : .ppTextPrimary(colorScheme))

            Text("\(formatCurrency(remainingPerDay, code: appState.currencyCode)) per day for \(progress.remainingDays) remaining days")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary(colorScheme))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder(colorScheme))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isNegative ? Color.ppDestructive : Color.ppPrimary)
                        .frame(width: geo.size.width * min(max(1.0 - burnIn.spentPercentage, 0), 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }
}
