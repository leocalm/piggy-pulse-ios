import SwiftUI

struct GettingStartedCard: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.themeManager) private var theme
    @State private var hasAccounts = false
    @State private var hasPeriods = false
    @State private var hasCategories = false
    @State private var hasTransactions = false

    private var steps: [(key: String, complete: Bool, route: String)] {
        [
            ("createAccount", hasAccounts, "/v2/accounts"),
            ("createPeriod", hasPeriods, "/v2/periods"),
            ("setCategories", hasCategories, "/v2/categories"),
            ("addTransaction", hasTransactions, "/v2/transactions"),
        ]
    }

    private var completedCount: Int { steps.filter(\.complete).count }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text(String(localized: "widget.gettingStarted.name"))
                        .font(.ppTitle3)
                        .foregroundColor(.ppTextPrimary)
                    Text(String(localized: "widget.gettingStarted.subtitle"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
                Spacer()
                Text("\(completedCount)/\(steps.count)")
                    .font(.ppCaption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextTertiary)
            }

            ForEach(steps, id: \.key) { step in
                HStack(spacing: PPSpacing.md) {
                    Image(systemName: step.complete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(step.complete ? theme.primary : .ppTextTertiary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: String.LocalizationValue("gettingStarted.steps.\(step.key).title")))
                            .font(.ppCallout)
                            .fontWeight(.medium)
                            .foregroundColor(step.complete ? .ppTextTertiary : .ppTextPrimary)
                            .strikethrough(step.complete)

                        Text(String(localized: String.LocalizationValue("gettingStarted.steps.\(step.key).desc")))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                }
            }
        }
        .dashboardCard()
        .task {
            await checkProgress()
        }
    }

    private func checkProgress() async {
        let api = appState.apiClient
        // Check accounts
        if let accounts: PaginatedResponse<AccountListItem> = try? await api.request(.accounts, queryItems: [URLQueryItem(name: "limit", value: "1")]) {
            hasAccounts = !accounts.data.isEmpty
        }
        // Check periods
        let periods = try? await PeriodRepository(apiClient: api).fetchPeriods()
        hasPeriods = !(periods ?? []).isEmpty
        // Check categories
        if let cats: PaginatedResponse<CategoryListItem> = try? await api.request(.categories, queryItems: [URLQueryItem(name: "limit", value: "1")]) {
            hasCategories = !cats.data.isEmpty
        }
        // Transactions require a period
        if let periodId = appState.selectedPeriod?.id {
            if let txns: CursorPaginatedTransactions = try? await api.request(.transactions, queryItems: [
                URLQueryItem(name: "periodId", value: periodId.uuidString),
                URLQueryItem(name: "limit", value: "1")
            ]) {
                hasTransactions = !txns.data.isEmpty
            }
        }
    }
}
