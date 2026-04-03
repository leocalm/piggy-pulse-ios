import SwiftUI
import TipKit

struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var accounts: [AccountListItem] = []
    @State private var summary: AccountsSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingAccount: AccountListItem?
    @State private var accountToDelete: AccountListItem?
    @State private var accountToArchive: AccountListItem?

    private let accountsTip = AccountsTip()

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "tab.accounts"), showTitle: false)
            } else {
                List {
                    // Tip
                    Section {
                        TipView(accountsTip)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }

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
                    } else if accounts.isEmpty {
                        Section {
                            EmptyStateView(
                                icon: "building.columns",
                                title: String(localized: "accounts.empty.title"),
                                message: String(localized: "accounts.empty.message"),
                                steps: [
                                    EmptyStateStep(
                                        title: String(localized: "accounts.empty.step1.title"),
                                        description: String(localized: "accounts.empty.step1.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "accounts.empty.step2.title"),
                                        description: String(localized: "accounts.empty.step2.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "accounts.empty.step3.title"),
                                        description: String(localized: "accounts.empty.step3.description")
                                    ),
                                ],
                                tips: [
                                    String(localized: "accounts.empty.tip1"),
                                    String(localized: "accounts.empty.tip2"),
                                    String(localized: "accounts.empty.tip3"),
                                ],
                                actionLabel: String(localized: "accounts.empty.action"),
                                action: { showAddSheet = true }
                            )
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
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
                        accountSection(String(localized: "LIQUID ACCOUNTS"), accounts: accounts.filter { $0.accountType == "Checking" || $0.accountType == "Wallet" || $0.accountType == "Allowance" })
                        accountSection(String(localized: "PROTECTED ACCOUNTS"), accounts: accounts.filter { $0.accountType == "Savings" || $0.accountType == "Investment" || $0.accountType == "Protected" })
                        accountSection(String(localized: "DEBT ACCOUNTS"), accounts: accounts.filter { $0.accountType == "CreditCard" || $0.accountType == "Credit" || $0.accountType == "Debt" || $0.accountType == "Loan" })
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ppBackground)
                .refreshable { await Task { @MainActor in await self.load() }.value }
                .task(id: appState.selectedPeriod?.id) { await load() }
                .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                    AddAccountSheet { }.environmentObject(appState)
                }
                .sheet(item: $editingAccount) { account in
                    EditAccountSheet(account: account) { Task { await load() } }
                        .environmentObject(appState)
                }
                .confirmationDialog("Archive \"\(accountToArchive?.name ?? "")\"?", isPresented: Binding(get: { accountToArchive != nil }, set: { if !$0 { accountToArchive = nil } }), titleVisibility: .visible) {
                    Button(String(localized: "common.archive"), role: .destructive) {
                        if let account = accountToArchive { Task { await archiveAccount(account) } }
                    }
                    Button(String(localized: "common.cancel"), role: .cancel) { accountToArchive = nil }
                } message: {
                    Text(String(localized: "accounts.archive.message"))
                }
                .confirmationDialog("Delete \"\(accountToDelete?.name ?? "")\"?", isPresented: Binding(get: { accountToDelete != nil }, set: { if !$0 { accountToDelete = nil } }), titleVisibility: .visible) {
                    Button(String(localized: "common.delete"), role: .destructive) {
                        if let account = accountToDelete { Task { await deleteAccount(account) } }
                    }
                    Button(String(localized: "common.cancel"), role: .cancel) { accountToDelete = nil }
                } message: {
                    Text(String(localized: "accounts.delete.message"))
                }
                .navigationTitle(String(localized: "tab.accounts"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            } // else
        } // NavigationStack
    }

    private func accountSection(_ title: String, accounts: [AccountListItem]) -> some View {
        Group {
            if !accounts.isEmpty {
                Section {
                    if horizontalSizeClass == .regular {
                        // Wide layout: 2-column grid for account cards
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: PPSpacing.md), GridItem(.flexible(), spacing: PPSpacing.md)], spacing: PPSpacing.md) {
                            ForEach(accounts) { account in
                                accountRow(account)
                                    .contextMenu {
                                        accountContextMenu(account)
                                    }
                            }
                        }
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    } else {
                        ForEach(accounts) { account in
                            accountRow(account)
                                .swipeActions(edge: .trailing) {
                                    if account.transactionCount > 0 {
                                        Button {
                                            accountToArchive = account
                                        } label: {
                                            Label(String(localized: "common.archive"), systemImage: "archivebox")
                                        }
                                        .tint(theme.secondary)
                                    } else {
                                        Button(role: .destructive) {
                                            accountToDelete = account
                                        } label: {
                                            Label(String(localized: "common.delete"), systemImage: "trash")
                                        }
                                        .tint(.ppDestructive)
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingAccount = account
                                    } label: {
                                        Label(String(localized: "common.edit"), systemImage: "pencil")
                                    }
                                }
                                .contextMenu {
                                    accountContextMenu(account)
                                }
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }
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

    @ViewBuilder
    private func accountContextMenu(_ account: AccountListItem) -> some View {
        Button {
            editingAccount = account
        } label: {
            Label(String(localized: "common.edit"), systemImage: "pencil")
        }
        if account.transactionCount > 0 {
            Button {
                accountToArchive = account
            } label: {
                Label(String(localized: "common.archive"), systemImage: "archivebox")
            }
        } else {
            Button(role: .destructive) {
                accountToDelete = account
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
    }
    
    private func deleteAccount(_ account: AccountListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteAccount(account.id))
            await load()
        } catch {
            errorMessage = String(localized: "accounts.delete.failed")
        }
    }

    private func archiveAccount(_ account: AccountListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.archiveAccount(account.id))
            await load()
        } catch {
            errorMessage = String(localized: "accounts.archive.failed")
        }
    }

    private func summaryCard(_ s: AccountsSummary) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "accounts.netPosition"))
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Text(formatCurrency(s.totalNetWorth, code: appState.currencyCode))
                .font(.ppAmount)
                .foregroundColor(theme.tertiary)

            // Breakdown bar
            netPositionBar(s)

            HStack(spacing: PPSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(theme.tertiary).frame(width: 8, height: 8)
                        Text(String(localized: "accounts.liquid"))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary)
                    }
                    Text(formatCurrency(liquidTotal, code: appState.currencyCode))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(theme.primary).frame(width: 8, height: 8)
                        Text(String(localized: "accounts.protected"))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary)
                    }
                    Text(formatCurrency(protectedTotal, code: appState.currencyCode))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(theme.secondary).frame(width: 8, height: 8)
                        Text(String(localized: "accounts.debt"))
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary)
                    }
                    Text(formatCurrency(debtTotal, code: appState.currencyCode))
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

    private var liquidTotal: Int64 {
        accounts.filter { $0.accountType == "Checking" || $0.accountType == "Wallet" || $0.accountType == "Allowance" }.reduce(0) { $0 + $1.balance }
    }

    private var protectedTotal: Int64 {
        accounts.filter { $0.accountType == "Savings" || $0.accountType == "Investment" || $0.accountType == "Protected" }.reduce(0) { $0 + $1.balance }
    }

    private var debtTotal: Int64 {
        accounts.filter { $0.accountType == "CreditCard" || $0.accountType == "Credit" || $0.accountType == "Debt" || $0.accountType == "Loan" }.reduce(0) { $0 + $1.balance }
    }

    private func netPositionBar(_ s: AccountsSummary) -> some View {
        let total = abs(liquidTotal) + abs(protectedTotal) + abs(debtTotal)
        let liquidFrac = total > 0 ? CGFloat(abs(liquidTotal)) / CGFloat(total) : 0.33
        let protectedFrac = total > 0 ? CGFloat(abs(protectedTotal)) / CGFloat(total) : 0.33

        return GeometryReader { geo in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.tertiary)
                    .frame(width: max(geo.size.width * liquidFrac, 4))
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.primary)
                    .frame(width: max(geo.size.width * protectedFrac, 4))
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.secondary)
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility.accounts.netPositionBar \(formatCurrency(liquidTotal, code: appState.currencyCode)) \(formatCurrency(protectedTotal, code: appState.currencyCode)) \(formatCurrency(debtTotal, code: appState.currencyCode))"))
    }

    private func accountRow(_ account: AccountListItem) -> some View {
        HStack {
            Circle()
                .fill(Color(hex: account.color) ?? theme.primary)
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
            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(theme.secondary)
            Text(message).font(.ppBody).foregroundColor(.ppTextSecondary)
            Button(String(localized: "common.retry")) { Task { await load() } }.font(.ppHeadline).foregroundColor(theme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PPSpacing.xxxl)
    }

    private func load() async {
        guard let periodId = appState.selectedPeriod?.id else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response: PaginatedResponse<AccountListItem> = try await appState.apiClient.request(
                .accountsSummary,
                queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)]
            )
            accounts = response.data
            // Compute summary from accounts
            let assets = accounts.filter { $0.type != "CreditCard" && $0.status == "active" }.reduce(Int64(0)) { $0 + $1.currentBalance }
            let liabilities = accounts.filter { $0.type == "CreditCard" && $0.status == "active" }.reduce(Int64(0)) { $0 + $1.currentBalance }
            summary = AccountsSummary(totalNetWorth: assets - liabilities, totalAssets: assets, totalLiabilities: liabilities)
        } catch {
            errorMessage = String(localized: "Failed to load accounts.")
        }
        isLoading = false
    }
}
