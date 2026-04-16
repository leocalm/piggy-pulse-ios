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
        let store = appState.dataStore

        // If data store is loaded, use cached decrypted data
        if store.isLoaded {
            hasAccounts = !store.accounts.isEmpty
            hasCategories = !store.categories.isEmpty
            hasTransactions = !store.periodTransactions.isEmpty
        } else {
            // Has-any-transactions endpoint returns a simple boolean (not encrypted)
            let txns: HasTransactionsResponse? = try? await appState.apiClient.request(.transactionsHasAny)
            hasTransactions = txns?.hasTransactions ?? false
            // For accounts/categories, try to decrypt from encrypted endpoints
            hasAccounts = ((try? await appState.apiClient.request(.accounts) as [EncryptedAccount])?.isEmpty == false)
            hasCategories = ((try? await appState.apiClient.request(.categories) as [EncryptedCategory])?.isEmpty == false)
        }

        let periods = try? await PeriodRepository(apiClient: appState.apiClient).fetchPeriods()
        hasPeriods = !(periods ?? []).isEmpty
    }
}
