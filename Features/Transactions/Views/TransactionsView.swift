import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: TransactionsViewModel
    @State private var showAddSheet = false
    @State private var showFilterSheet = false
    @State private var editingTransaction: Transaction?
    @State private var transactionToDelete: Transaction?

    init(apiClient: APIClient) {
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            List {
                // Header section
                Section {
                    // Direction tabs
                    directionTabs
                        .listRowBackground(Color.ppBackground(colorScheme))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.sm, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
                }
                
                // Content section
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView().tint(.ppTextSecondary(colorScheme))
                            Spacer()
                        }
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground(colorScheme))
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
                                .foregroundColor(.ppTextSecondary(colorScheme))
                            Button("Retry") {
                                if let periodId = appState.selectedPeriod?.id {
                                    Task { await viewModel.load(periodId: periodId) }
                                }
                            }
                            .font(.ppHeadline)
                            .foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground(colorScheme))
                        .listRowSeparator(.hidden)
                    }
                } else if viewModel.transactions.isEmpty {
                    Section {
                        VStack(spacing: PPSpacing.lg) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.ppTextTertiary(colorScheme))
                            Text("No transactions found")
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary(colorScheme))
                            Text("Start tracking your spending by adding your first transaction.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextTertiary(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground(colorScheme))
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(viewModel.transactions) { transaction in
                            transactionRow(transaction)
                                .listRowBackground(Color.ppBackground(colorScheme))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                .onTapGesture {
                                    editingTransaction = transaction
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.ppDestructive)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingTransaction = transaction
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                                .onAppear {
                                    if transaction.id == viewModel.transactions.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }
                        
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView().tint(.ppTextSecondary(colorScheme))
                                Spacer()
                            }
                            .listRowBackground(Color.ppBackground(colorScheme))
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground(colorScheme))
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
            .confirmationDialog("Delete transaction?", isPresented: Binding(get: { transactionToDelete != nil }, set: { if !$0 { transactionToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let tx = transactionToDelete { Task { await deleteTransaction(tx) } }
                }
                Button("Cancel", role: .cancel) { transactionToDelete = nil }
            } message: {
                Text("This transaction will be permanently deleted.")
            }
            .navigationTitle("Transactions")
            .toolbar {
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
        }
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
                        Text(direction.rawValue)
                            .font(.ppCallout)
                            .fontWeight(viewModel.selectedDirection == direction ? .semibold : .regular)
                            .foregroundColor(
                                viewModel.selectedDirection == direction
                                    ? .ppTextPrimary(colorScheme)
                                    : .ppTextSecondary(colorScheme)
                            )
                            .padding(.horizontal, PPSpacing.lg)
                            .padding(.vertical, PPSpacing.sm)
                            .background(
                                viewModel.selectedDirection == direction
                                    ? Color.ppCard(colorScheme)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                            .overlay(
                                RoundedRectangle(cornerRadius: PPRadius.full)
                                    .stroke(
                                        viewModel.selectedDirection == direction
                                            ? Color.ppBorder(colorScheme)
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
                    .foregroundColor(.ppTextPrimary(colorScheme))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(tx.category.name)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary(colorScheme))

                    if let vendor = tx.vendor {
                        Text("·")
                            .font(.ppCaption)
                            .foregroundColor(.ppTextTertiary(colorScheme))
                        Text(vendor.name)
                            .font(.ppCaption)
                            .foregroundColor(.ppTextSecondary(colorScheme))
                    }
                }
            }

            Spacer()

            // Amount + date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(tx))
                    .font(.ppAmountSmall)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                Text(tx.formattedDate)
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            }
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.md)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
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
        } catch {}
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
