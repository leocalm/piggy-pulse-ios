import SwiftUI

struct CurrentPeriodCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let burnIn: MonthlyBurnIn
    let progress: MonthProgress

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("CURRENT PERIOD")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            Text(formatCurrency(burnIn.spentBudget, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary(colorScheme))

            Text("of \(formatCurrency(burnIn.totalBudget, code: appState.currencyCode))")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary(colorScheme))

            Text("\(progress.remainingDays) days remaining. \(formatCurrency(burnIn.remainingBudget, code: appState.currencyCode)) remaining in this period.")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary(colorScheme))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppBorder(colorScheme))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ppPrimary)
                        .frame(width: geo.size.width * min(burnIn.spentPercentage, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            let projectedSpend = projectedSpendAmount(burnIn: burnIn, progress: progress)
            Text("Projected spend at current pace: \(formatCurrency(projectedSpend, code: appState.currencyCode))")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary(colorScheme))
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    private func projectedSpendAmount(burnIn: MonthlyBurnIn, progress: MonthProgress) -> Int64 {
        let daysPassed = progress.daysInPeriod - progress.remainingDays
        guard daysPassed > 0 else { return 0 }
        let dailyRate = Double(burnIn.spentBudget) / Double(daysPassed)
        return Int64(dailyRate * Double(progress.daysInPeriod))
    }
}
