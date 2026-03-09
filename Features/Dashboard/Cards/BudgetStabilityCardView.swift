import SwiftUI

struct BudgetStabilityCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let stability: BudgetStability

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("SPENDING CONSISTENCY")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            Text("\(stability.withinTolerancePercentage)%")
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary(colorScheme))

            Text("\(stability.periodsWithinTolerance) of \(stability.totalClosedPeriods) periods within range")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary(colorScheme))

            HStack(spacing: PPSpacing.sm) {
                ForEach(stability.recentClosedPeriods.indices, id: \.self) { index in
                    let period = stability.recentClosedPeriods[index]
                    Circle()
                        .fill(period.isOutsideTolerance ? Color.ppTextTertiary(colorScheme) : Color.ppPrimary)
                        .frame(width: 10, height: 10)
                }
            }

            let outsideCount = stability.recentClosedPeriods.filter { $0.isOutsideTolerance }.count
            let total = stability.recentClosedPeriods.count
            Text("\(outsideCount) of the last \(total) closed periods were outside tolerance.")
                .font(.ppCaption)
                .foregroundColor(.ppTextTertiary(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }
}
