import SwiftUI

struct CategoryBreakdownCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let categoryName: String
    let spending: [CategoryBreakdownItem]

    var total: Int64 {
        spending.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(categoryName.uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            Text(formatCurrency(total, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppTextPrimary(colorScheme))

            if spending.isEmpty {
                Text("No spending data")
                    .font(.ppBody)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            } else {
                segmentBar
                    .frame(height: 8)

                ForEach(spending.prefix(4)) { item in
                    HStack {
                        Circle()
                            .fill(Color(hex: item.color) ?? .ppPrimary)
                            .frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.ppCaption)
                            .foregroundColor(.ppTextPrimary(colorScheme))
                            .lineLimit(1)
                        Spacer()
                        Text(formatCurrency(item.amount, code: appState.currencyCode))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary(colorScheme))
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

    private var segmentBar: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(spending.prefix(4)) { item in
                    let ratio = total > 0 ? Double(item.amount) / Double(total) : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: item.color) ?? .ppPrimary)
                        .frame(width: max(geo.size.width * ratio, 2))
                }
            }
        }
    }
}
