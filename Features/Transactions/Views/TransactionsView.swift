import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: TransactionsViewModel
    @State private var showAddSheet = false
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
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.sm, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
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
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    }
                } else if viewModel.transactions.isEmpty {
                    Section {
                        VStack(spacing: PPSpacing.lg) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.ppTextTertiary)
                            Text("No transactions found")
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)
                            Text("Start tracking your spending by adding your first transaction.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(viewModel.transactions) { transaction in
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
            .navigationBarTitleDisplayMode(.large)
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
        let value = Double(tx.amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
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
