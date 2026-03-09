import SwiftUI

struct BalanceOverTimeCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let dataPoints: [BalanceDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("BALANCE OVER TIME")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary(colorScheme))
                .tracking(1)

            if dataPoints.isEmpty {
                Text("Not enough data to display")
                    .font(.ppBody)
                    .foregroundColor(.ppTextTertiary(colorScheme))
                    .frame(height: 120)
            } else {
                sparklineChart
                    .frame(height: 120)
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

    private var sparklineChart: some View {
        GeometryReader { geo in
            let values = dataPoints.map { Double($0.balance) }
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = max(maxVal - minVal, 1)

            Path { path in
                for (i, val) in values.enumerated() {
                    let x = geo.size.width * Double(i) / max(Double(values.count - 1), 1)
                    let y = geo.size.height * (1.0 - (val - minVal) / range)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.ppPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
