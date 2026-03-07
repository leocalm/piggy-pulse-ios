import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @State private var accounts: [AccountListItem] = []
    @State private var summary: AccountsSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingAccount: AccountListItem?
    @State private var accountToDelete: AccountListItem?
    @State private var accountToArchive: AccountListItem?

    var body: some View {
        List {
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
            .confirmationDialog("Archive \"\(accountToArchive?.name ?? "")\"?", isPresented: Binding(get: { accountToArchive != nil }, set: { if !$0 { accountToArchive = nil } }), titleVisibility: .visible) {
                Button("Archive", role: .destructive) {
                    if let account = accountToArchive { Task { await archiveAccount(account) } }
                }
                Button("Cancel", role: .cancel) { accountToArchive = nil }
            } message: {
                Text("This account will be hidden but its history will be preserved.")
            }
            .confirmationDialog("Delete \"\(accountToDelete?.name ?? "")\"?", isPresented: Binding(get: { accountToDelete != nil }, set: { if !$0 { accountToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete { Task { await deleteAccount(account) } }
                }
                Button("Cancel", role: .cancel) { accountToDelete = nil }
            } message: {
                Text("This account will be permanently deleted.")
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.white)
                }
            }
    }

    private func accountSection(_ title: String, accounts: [AccountListItem]) -> some View {
        Group {
            if !accounts.isEmpty {
                Section {
                    ForEach(accounts) { account in
                        accountRow(account)
                            .swipeActions(edge: .trailing) {
                                if account.transactionCount > 0 {
                                    Button {
                                        accountToArchive = account
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.ppAmber)
                                } else {
                                    Button(role: .destructive) {
                                        accountToDelete = account
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.ppDestructive)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingAccount = account
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
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
                        Text(formatCurrency(accounts.reduce(0) { $0 + $1.balance }, code: appState.currencyCode))
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

    private func archiveAccount(_ account: AccountListItem) async {
        do {
            try await appState.apiClient.requestVoid(.archiveAccount(account.id))
            await load()
        } catch {}
    }

    private func summaryCard(_ s: AccountsSummary) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("NET POSITION")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(s.totalNetWorth, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(.ppCyan)

            HStack(spacing: PPSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assets")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                    Text(formatCurrency(s.totalAssets, code: appState.currencyCode))
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
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func accountRow(_ account: AccountListItem) -> some View {
        HStack {
            Circle()
                .fill(Color(hex: account.color) ?? .ppPrimary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)

                HStack(spacing: 4) {
                    Text("\(account.transactionCount) tx")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)

                    let changePrefix = account.balanceChangeThisPeriod >= 0 ? "+" : ""
                    Text("\(changePrefix)\(formatCurrency(account.balanceChangeThisPeriod, code: appState.currencyCode))")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                }
            }

            Spacer()

            Text(formatCurrency(account.balance, code: appState.currencyCode))
                .font(.ppAmountSmall)
                .foregroundColor(.ppTextPrimary)
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
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
}
