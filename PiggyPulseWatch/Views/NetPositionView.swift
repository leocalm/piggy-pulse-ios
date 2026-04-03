import SwiftUI

struct NetPositionView: View {

    let state: WatchLoadingState<WatchNetPosition>

    private let accentColor = WatchDesign.accentColor

    var body: some View {
        ScrollView {
            switch state {
            case .idle, .loading:
                loadingView
            case .loaded(let position):
                positionContent(position)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle(String(localized: "Net Position"))
    }

    // MARK: - Content

    @ViewBuilder
    private func positionContent(_ position: WatchNetPosition) -> some View {
        VStack(spacing: 12) {
            // Total
            VStack(spacing: 2) {
                Text(String(localized: "Total"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(WatchCurrencyFormatter.format(position.total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }

            // Change this period
            changeThisPeriod(position.differenceThisPeriod)

            Divider()

            // Breakdown
            VStack(spacing: 8) {
                breakdownRow(
                    icon: "drop.fill",
                    label: String(localized: "Liquid"),
                    amount: position.liquidAmount
                )

                breakdownRow(
                    icon: "lock.fill",
                    label: String(localized: "Protected"),
                    amount: position.protectedAmount
                )

                breakdownRow(
                    icon: "creditcard.fill",
                    label: String(localized: "Debt"),
                    amount: position.debtAmount
                )
            }

            Divider()

            // Account count
            HStack {
                Image(systemName: "building.columns")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(String(localized: "\(position.numberOfAccounts) accounts"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func changeThisPeriod(_ difference: Int64) -> some View {
        let isPositive = difference >= 0
        let arrow = isPositive ? "arrow.up.right" : "arrow.down.right"
        let color: Color = .secondary

        HStack(spacing: 4) {
            Image(systemName: arrow)
                .font(.caption2)
            Text(WatchCurrencyFormatter.format(difference, compact: true))
                .font(.caption)
        }
        .foregroundStyle(color)
    }

    @ViewBuilder
    private func breakdownRow(icon: String, label: String, amount: Int64) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)

            Spacer()

            Text(WatchCurrencyFormatter.format(amount, compact: true))
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Loading & Error

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(String(localized: "Loading..."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
