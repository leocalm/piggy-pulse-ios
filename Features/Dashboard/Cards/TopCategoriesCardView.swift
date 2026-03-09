import SwiftUI

struct TopCategoriesCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let categories: [CategorySpending]

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("TOP CATEGORIES")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            if categories.isEmpty {
                Text("No spending data yet")
                    .font(.ppBody)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            } else {
                let maxAmount = categories.first?.amount ?? 1
                ForEach(categories.prefix(5)) { cat in
                    categoryRow(cat, maxAmount: maxAmount)
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

    private func categoryRow(_ cat: CategorySpending, maxAmount: Int64) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cat.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary(colorScheme))
                    .lineLimit(1)
                Spacer()
                Text(formatCurrency(cat.amount, code: appState.currencyCode))
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary(colorScheme))
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: cat.color) ?? .ppPrimary)
                    .frame(width: geo.size.width * barRatio(cat.amount, max: maxAmount), height: 4)
            }
            .frame(height: 4)
        }
    }

    private func barRatio(_ amount: Int64, max: Int64) -> Double {
        guard max > 0 else { return 0 }
        return Double(amount) / Double(max)
    }
}
