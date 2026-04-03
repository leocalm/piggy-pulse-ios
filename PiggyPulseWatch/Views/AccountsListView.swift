import SwiftUI

struct AccountsListView: View {

    let state: WatchLoadingState<[WatchAccountSummary]>

    private let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255)

    var body: some View {
        switch state {
        case .idle, .loading:
            loadingView
        case .loaded(let accounts):
            accountsList(accounts)
        case .error(let message):
            errorView(message)
        }
    }

    // MARK: - Accounts List

    @ViewBuilder
    private func accountsList(_ accounts: [WatchAccountSummary]) -> some View {
        if accounts.isEmpty {
            emptyView
        } else {
            List {
                ForEach(accounts) { account in
                    accountRow(account)
                }
            }
            .navigationTitle(String(localized: "Accounts"))
        }
    }

    @ViewBuilder
    private func accountRow(_ account: WatchAccountSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(account.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Text(WatchCurrencyFormatter.format(account.currentBalance, compact: true))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)
            }

            accountTypeBadge(account.type)
        }
    }

    @ViewBuilder
    private func accountTypeBadge(_ type: String) -> some View {
        Text(displayName(for: type))
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
            )
    }

    private func displayName(for type: String) -> String {
        switch type.lowercased() {
        case "checking":
            return String(localized: "Checking")
        case "savings":
            return String(localized: "Savings")
        case "creditcard":
            return String(localized: "Credit Card")
        case "allowance":
            return String(localized: "Allowance")
        case "wallet":
            return String(localized: "Wallet")
        default:
            return type
        }
    }

    // MARK: - Empty / Loading / Error

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "building.columns")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(String(localized: "No accounts"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
