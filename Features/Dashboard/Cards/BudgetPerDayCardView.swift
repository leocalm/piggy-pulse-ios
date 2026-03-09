import SwiftUI

struct BudgetPerDayCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let burnIn: MonthlyBurnIn
    let progress: MonthProgress

    private var dailyBudget: Int64 {
        guard progress.daysInPeriod > 0 else { return 0 }
        return burnIn.totalBudget / Int64(progress.daysInPeriod)
    }

    private var dailySpend: Int64 {
        let daysPassed = progress.daysInPeriod - progress.remainingDays
        guard daysPassed > 0 else { return 0 }
        return burnIn.spentBudget / Int64(daysPassed)
    }

    private var isOverBudget: Bool {
        dailySpend > dailyBudget
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("BUDGET PER DAY")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: PPSpacing.sm) {
                Text(formatCurrency(dailyBudget, code: appState.currencyCode))
                    .font(.ppAmount)
                    .foregroundColor(.ppTextPrimary(colorScheme))
                Text("/ day")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary(colorScheme))
            }

            HStack(spacing: PPSpacing.sm) {
                Circle()
                    .fill(isOverBudget ? Color.ppDestructive : Color.ppSuccess)
                    .frame(width: 8, height: 8)
                Text("Avg. spending: \(formatCurrency(dailySpend, code: appState.currencyCode)) / day")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary(colorScheme))
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
}
