import SwiftUI

struct CurrentPeriodView: View {

    let state: WatchLoadingState<WatchCurrentPeriod>

    private let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255)

    var body: some View {
        ScrollView {
            switch state {
            case .idle, .loading:
                loadingView
            case .loaded(let period):
                periodContent(period)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle(String(localized: "Current Period"))
    }

    // MARK: - Period Content

    @ViewBuilder
    private func periodContent(_ period: WatchCurrentPeriod) -> some View {
        VStack(spacing: 12) {
            // Spent amount
            VStack(spacing: 2) {
                Text(String(localized: "Spent"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(WatchCurrencyFormatter.format(period.spent))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)

                Text(String(localized: "of \(WatchCurrencyFormatter.format(period.target))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress
            progressBar(period)

            Divider()

            // Days remaining
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(String(localized: "\(period.daysRemaining) days remaining"))
                    .font(.caption)
            }

            // Projected spend
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "Projected"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(WatchCurrencyFormatter.format(period.projectedSpend))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func progressBar(_ period: WatchCurrentPeriod) -> some View {
        let progress = period.target > 0
            ? min(Double(period.spent) / Double(period.target), 1.0)
            : 0.0
        let daysProgress = period.daysInPeriod > 0
            ? Double(period.daysInPeriod - period.daysRemaining) / Double(period.daysInPeriod)
            : 0.0

        VStack(spacing: 4) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 60, height: 60)

            // Time progress label
            Text(String(localized: "\(Int(daysProgress * 100))% of period elapsed"))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
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
