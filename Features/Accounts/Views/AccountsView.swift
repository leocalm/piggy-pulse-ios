import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @State private var accounts: [AccountListItem] = []
    @State private var summary: AccountsSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingAccount: AccountListItem?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text("Accounts")
                        .font(.ppLargeTitle)
                        .foregroundColor(.ppPrimary)
                    Text("Balance-level structure across liquid, protected, and debt accounts.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }
                .listRowBackground(Color.ppBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.lg, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
            }
            
            // Add button - in the header section, after subtitle
            Button {
                showAddSheet = true
            } label: {
                Text("Add Account")
                    .font(.ppHeadline).frame(maxWidth: .infinity).padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent).tint(.ppPrimary).cornerRadius(PPRadius.full)
            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))

            if isLoading {
                Section {
                    HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                }
            } else if let error = errorMessage {
                Section {
                    errorView(error)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                }
            } else {
                // Summary
                if let s = summary {
                    Section {
                        summaryCard(s)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                }

                // Grouped by type
                accountSection("LIQUID ACCOUNTS", accounts: accounts.filter { $0.accountType == "Checking" || $0.accountType == "Savings" })
                accountSection("PROTECTED ACCOUNTS", accounts: accounts.filter { $0.accountType == "Investment" || $0.accountType == "Protected" })
                accountSection("DEBT ACCOUNTS", accounts: accounts.filter { $0.accountType == "Credit" || $0.accountType == "Debt" || $0.accountType == "Loan" })
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.ppBackground)
        .refreshable { await load() }
        .task(id: appState.selectedPeriod?.id) { await load() }
        .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
            AddAccountSheet { }.environmentObject(appState)
        }
        .sheet(item: $editingAccount) { account in
            EditAccountSheet(account: account) { Task { await load() } }
                .environmentObject(appState)
        }
    }

    private func accountSection(_ title: String, accounts: [AccountListItem]) -> some View {
        Group {
            if !accounts.isEmpty {
                Section {
                    ForEach(accounts) { account in
                        accountRow(account)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await deleteAccount(account) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingAccount = account
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.ppPrimary)
                            }
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                } header: {
                    HStack {
                        Text(title)
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                        Spacer()
                        Text(formatCurrency(accounts.reduce(0) { $0 + $1.balance }))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                }
            }
        }
    }
    
    private func deleteAccount(_ account: AccountListItem) async {
        do {
            try await appState.apiClient.requestVoid(.deleteAccount(account.id))
            await load()
        } catch {}
    }

    private func summaryCard(_ s: AccountsSummary) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("NET POSITION")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(s.totalNetWorth))
                .font(.ppAmount)
                .foregroundColor(.ppCyan)

            HStack(spacing: PPSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assets")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                    Text(formatCurrency(s.totalAssets))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Liabilities")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                    Text(formatCurrency(s.totalLiabilities))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func accountRow(_ account: AccountListItem) -> some View {
        HStack {
            Circle()
                .fill(Color(hex: account.color) ?? .ppPrimary)
                .frame(width: 36, height: 36)
                .overlay(Text(account.icon).font(.system(size: 16)))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)

                HStack(spacing: 4) {
                    Text("\(account.transactionCount) tx")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)

                    let changePrefix = account.balanceChangeThisPeriod >= 0 ? "+" : ""
                    Text("\(changePrefix)\(formatCurrency(account.balanceChangeThisPeriod))")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                }
            }

            Spacer()

            Text(formatCurrency(account.balance))
                .font(.ppAmountSmall)
                .foregroundColor(.ppTextPrimary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.md)
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: PPSpacing.md) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
            Text(message).font(.ppBody).foregroundColor(.ppTextSecondary)
            Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PPSpacing.xxxl)
    }

    private func load() async {
        guard let periodId = appState.selectedPeriod?.id else { return }
        isLoading = true
        errorMessage = nil

        do {
            async let accountsTask: PaginatedResponse<AccountListItem> = appState.apiClient.request(
                .accounts,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            async let summaryTask: AccountsSummary = appState.apiClient.request(.accountsSummary)

            let (a, s) = try await (accountsTask, summaryTask)
            accounts = a.data
            summary = s
        } catch {
            errorMessage = "Failed to load accounts."
        }
        isLoading = false
    }

    private func formatCurrency(_ cents: Int64) -> String {
        let value = Double(cents) / 100.0
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "EUR"
        return fmt.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}
