import SwiftUI

struct GettingStartedCard: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.themeManager) private var theme
    @State private var hasAccounts = false
    @State private var hasPeriods = false
    @State private var hasCategories = false
    @State private var hasTransactions = false

    private var steps: [(key: String, title: String, desc: String, complete: Bool)] {
        [
            ("createAccount", String(localized: "gettingStarted.steps.createAccount.title"), String(localized: "gettingStarted.steps.createAccount.desc"), hasAccounts),
            ("createPeriod", String(localized: "gettingStarted.steps.createPeriod.title"), String(localized: "gettingStarted.steps.createPeriod.desc"), hasPeriods),
            ("setCategories", String(localized: "gettingStarted.steps.setCategories.title"), String(localized: "gettingStarted.steps.setCategories.desc"), hasCategories),
            ("addTransaction", String(localized: "gettingStarted.steps.addTransaction.title"), String(localized: "gettingStarted.steps.addTransaction.desc"), hasTransactions),
        ]
    }

    private var completedCount: Int { steps.filter(\.complete).count }
    private var allComplete: Bool { completedCount == steps.count }

    var body: some View {
        if allComplete {
            EmptyView()
        } else {
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
                        Text(step.title)
                            .font(.ppCallout)
                            .fontWeight(.medium)
                            .foregroundColor(step.complete ? .ppTextTertiary : .ppTextPrimary)
                            .strikethrough(step.complete)

                        Text(step.desc)
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
        } // else !allComplete
    }

    private func checkProgress() async {
        let api = appState.apiClient

        struct SimpleAccount: Codable { let id: UUID }
        async let accountsTask: PaginatedResponse<SimpleAccount>? = try? api.request(.accounts, queryItems: [URLQueryItem(name: "limit", value: "1")])
        async let periodsTask = try? PeriodRepository(apiClient: api).fetchPeriods()
        async let catsTask: PaginatedResponse<CategoryListItem>? = try? api.request(.categories, queryItems: [URLQueryItem(name: "limit", value: "1")])

        let txnsTask: CursorPaginatedTransactions? = await {
            guard let periodId = appState.selectedPeriod?.id else { return nil }
            return try? await api.request(.transactions, queryItems: [
                URLQueryItem(name: "periodId", value: periodId.uuidString),
                URLQueryItem(name: "limit", value: "1")
            ])
        }()

        let accounts = await accountsTask
        let periods = await periodsTask
        let cats = await catsTask

        hasAccounts = !(accounts?.data.isEmpty ?? true)
        hasPeriods = !(periods ?? []).isEmpty
        hasCategories = !(cats?.data.isEmpty ?? true)
        hasTransactions = !(txnsTask?.data.isEmpty ?? true)
    }
}
