import SwiftUI
import TipKit

struct TransactionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: TransactionsViewModel
    @State private var showAddSheet = false
    @State private var showFilterSheet = false
    @State private var editingTransaction: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var searchText = ""

    private let transactionsTip = TransactionsTip()

    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty { return viewModel.transactions }
        return viewModel.transactions.filter {
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            ($0.vendor?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.category.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "tab.transactions"))
            } else {
            List {
                // Tip
                Section {
                    TipView(transactionsTip)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                }

                // Header section
                Section {
                    // Direction tabs
                    directionTabs
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.sm, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
                }
                
                // Stats bar
                if !viewModel.isLoading && !viewModel.transactions.isEmpty {
                    Section {
                        transactionStatsBar
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                }

                // Content section
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView().tint(.ppTextSecondary)
                            Spacer()
                        }
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    }
                } else if let error = viewModel.errorMessage {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.ppAmber)
                            Text(error)
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Button(String(localized: "common.retry")) {
                                if let periodId = appState.selectedPeriod?.id {
                                    Task { await viewModel.load(periodId: periodId) }
                                }
                            }
                            .font(.ppHeadline)
                            .foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    }
                } else if viewModel.transactions.isEmpty {
                    Section {
                        EmptyStateView(
                            icon: "arrow.left.arrow.right",
                            title: String(localized: "transactions.empty.title"),
                            message: String(localized: "transactions.empty.message"),
                            steps: [
                                EmptyStateStep(
                                    title: String(localized: "transactions.empty.step1.title"),
                                    description: String(localized: "transactions.empty.step1.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "transactions.empty.step2.title"),
                                    description: String(localized: "transactions.empty.step2.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "transactions.empty.step3.title"),
                                    description: String(localized: "transactions.empty.step3.description")
                                ),
                            ],
                            tips: [
                                String(localized: "transactions.empty.tip1"),
                                String(localized: "transactions.empty.tip2"),
                                String(localized: "transactions.empty.tip3"),
                            ],
                            actionLabel: String(localized: "transactions.empty.action"),
                            action: { showAddSheet = true }
                        )
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                } else {
                    Section {
                        ForEach(filteredTransactions) { transaction in
                            transactionRow(transaction)
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                .onTapGesture {
                                    editingTransaction = transaction
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
                                    .tint(.ppDestructive)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingTransaction = transaction
                                    } label: {
                                        Label(String(localized: "common.edit"), systemImage: "pencil")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        editingTransaction = transaction
                                    } label: {
                                        Label(String(localized: "common.edit"), systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
                                }
                                .onAppear {
                                    if transaction.id == filteredTransactions.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }
                        
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView().tint(.ppTextSecondary)
                                Spacer()
                            }
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground)
            .searchable(text: $searchText, prompt: String(localized: "transactions.search"))
            .refreshable {
                if let periodId = appState.selectedPeriod?.id {
                    await viewModel.refresh(periodId: periodId)
                }
            }
            .task(id: appState.selectedPeriod?.id) {
                if let periodId = appState.selectedPeriod?.id {
                    await viewModel.load(periodId: periodId)
                }
            }
            .sheet(isPresented: $showAddSheet, onDismiss: {
                if let periodId = appState.selectedPeriod?.id {
                    Task { await viewModel.refresh(periodId: periodId) }
                }
            }) {
                AddTransactionSheet {
                    // onDismiss handles refresh
                }
                .environmentObject(appState)
            }
            .sheet(item: $editingTransaction) { tx in
                EditTransactionSheet(transaction: tx) {
                    if let periodId = appState.selectedPeriod?.id {
                        Task { await viewModel.refresh(periodId: periodId) }
                    }
                }
                .environmentObject(appState)
            }
            .confirmationDialog(String(localized: "transactions.delete.title"), isPresented: Binding(get: { transactionToDelete != nil }, set: { if !$0 { transactionToDelete = nil } }), titleVisibility: .visible) {
                Button(String(localized: "common.delete"), role: .destructive) {
                    if let tx = transactionToDelete { Task { await deleteTransaction(tx) } }
                }
                Button(String(localized: "common.cancel"), role: .cancel) { transactionToDelete = nil }
            } message: {
                Text(String(localized: "transactions.delete.message"))
            }
            .navigationTitle(String(localized: "tab.transactions"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAddSheet = true
                    } label: {
                        Image("custom.arrow.left.arrow.right.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilterSheet = true
                        Task { await viewModel.loadFilterOptions() }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .imageScale(.medium)
                            if viewModel.activeFilterCount > 0 {
                                Text("\(viewModel.activeFilterCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Color.ppPrimary)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel(viewModel.activeFilterCount > 0 ? "Filter, \(viewModel.activeFilterCount) active" : "Filter")
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                TransactionFilterSheet(
                    filterOptions: viewModel.filterOptions,
                    isLoadingOptions: viewModel.isLoadingFilterOptions,
                    initialAccountIds: viewModel.selectedAccountIds,
                    initialCategoryIds: viewModel.selectedCategoryIds,
                    initialVendorIds: viewModel.selectedVendorIds
                ) { accountIds, categoryIds, vendorIds in
                    if let periodId = appState.selectedPeriod?.id {
                        Task {
                            await viewModel.applyFilters(
                                accountIds: accountIds,
                                categoryIds: categoryIds,
                                vendorIds: vendorIds,
                                periodId: periodId
                            )
                        }
                    }
                }
            }
            } // else
        }
    }

    // MARK: - Stats Bar

    private var transactionStatsBar: some View {
        let inflows = viewModel.transactions.filter { $0.category.categoryType == "incoming" }.reduce(Int64(0)) { $0 + $1.amount }
        let outflows = viewModel.transactions.filter { $0.category.categoryType == "outgoing" }.reduce(Int64(0)) { $0 + $1.amount }
        let net = inflows - outflows
        let count = viewModel.transactions.count

        return HStack(spacing: 0) {
            statsItem(label: String(localized: "stats.inflows"), value: formatCurrency(inflows, code: appState.currencyCode))
            statsItem(label: String(localized: "stats.outflows"), value: formatCurrency(outflows, code: appState.currencyCode))
            statsItem(label: String(localized: "stats.net"), value: formatCurrency(net, code: appState.currencyCode))
            statsItem(label: String(localized: "stats.transactions"), value: "\(count)")
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func statsItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ppCallout)
                .fontWeight(.semibold)
                .foregroundColor(.ppTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.ppCaption)
                .foregroundColor(.ppTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Direction Tabs

    private var directionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PPSpacing.sm) {
                ForEach(TransactionDirection.allCases, id: \.self) { direction in
                    Button {
                        if let periodId = appState.selectedPeriod?.id {
                            Task { await viewModel.changeDirection(direction, periodId: periodId) }
                        }
                    } label: {
                        Text(direction.label)
                            .font(.ppCallout)
                            .fontWeight(viewModel.selectedDirection == direction ? .semibold : .regular)
                            .foregroundColor(
                                viewModel.selectedDirection == direction
                                    ? .ppTextPrimary
                                    : .ppTextSecondary
                            )
                            .padding(.horizontal, PPSpacing.lg)
                            .padding(.vertical, PPSpacing.sm)
                            .background(
                                viewModel.selectedDirection == direction
                                    ? Color.ppCard
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                            .overlay(
                                RoundedRectangle(cornerRadius: PPRadius.full)
                                    .stroke(
                                        viewModel.selectedDirection == direction
                                            ? Color.ppBorder
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }

    // MARK: - Transaction Row

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: PPSpacing.md) {
            // Category icon circle
            Circle()
                .fill(Color(hex: tx.category.color) ?? .ppPrimary)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(tx.category.icon.prefix(2))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

            // Description + category
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description)
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(tx.category.name)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)

                    if let vendor = tx.vendor {
                        Text("·")
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary)
                        Text(vendor.name)
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary)
                    }
                }
            }

            Spacer()

            // Amount + date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(tx))
                    .font(.ppAmountSmall)
                    .foregroundColor(.ppTextPrimary)

                Text(tx.formattedDate)
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary)
            }
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.md)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func formatAmount(_ tx: Transaction) -> String {
        formatCurrency(tx.amount, code: appState.currencyCode)
    }
    
    private func deleteTransaction(_ tx: Transaction) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteTransaction(tx.id))
            if let periodId = appState.selectedPeriod?.id {
                await viewModel.refresh(periodId: periodId)
            }
        } catch {
            viewModel.errorMessage = String(localized: "transactions.delete.failed")
        }
    }
}

// MARK: - Color from hex string

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
