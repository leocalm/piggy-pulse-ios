import SwiftUI

struct EditTransactionSheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    let transaction: Transaction
    var onUpdated: () -> Void

    @State private var amountText = ""
    @State private var description = ""
    @State private var occurredAt = Date()
    @State private var selectedCategory: CategoryOption?
    @State private var selectedFromAccount: AccountOption?
    @State private var selectedToAccount: AccountOption?
    @State private var selectedVendor: VendorOption?
    @State private var isTransfer = false

    @State private var categories: [CategoryOption] = []
    @State private var transferCategory: CategoryOption?
    @State private var accounts: [AccountOption] = []
    @State private var vendors: [VendorOption] = []

    @State private var isLoading = false
    @State private var isLoadingOptions = true
    @State private var errorMessage: String?

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = appState.currencyCode
        return fmt.currencySymbol ?? appState.currencyCode
    }

    private var amountInCents: Int64 {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return 0 }
        return Int64(value * 100)
    }

    private var isDisabled: Bool {
        amountInCents <= 0 ||
        description.trimmingCharacters(in: .whitespaces).count < 3 ||
        selectedCategory == nil ||
        selectedFromAccount == nil ||
        (isTransfer && selectedToAccount == nil) ||
        isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                if isLoadingOptions {
                    ProgressView().tint(.ppTextSecondary)
                } else {
                    ScrollView {
                        VStack(spacing: PPSpacing.xl) {
                            if let error = errorMessage {
                                Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                            }

                            // Amount
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "field.amount")).font(.ppTitle3).foregroundColor(.ppTextPrimary)
                                HStack {
                                    Text(currencySymbol).font(.ppAmount).foregroundColor(.ppTextSecondary)
                                    TextField("0.00", text: $amountText).font(.ppAmount).foregroundColor(.ppTextPrimary).keyboardType(.decimalPad)
                                }
                                .padding(PPSpacing.lg).background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))

                                Toggle(isOn: $isTransfer) {
                                    Text(String(localized: "transaction.transferBetween"))
                                        .font(.ppCallout)
                                        .foregroundColor(.ppTextPrimary)
                                }
                                .tint(theme.primary)
                                .onChange(of: isTransfer) { _, transfer in
                                    if transfer {
                                        selectedCategory = transferCategory
                                        selectedVendor = nil
                                    } else {
                                        selectedToAccount = nil
                                        if selectedCategory?.id == transferCategory?.id {
                                            selectedCategory = nil
                                        }
                                    }
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Details
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "section.details")).font(.ppTitle3).foregroundColor(.ppTextPrimary)
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack(spacing: 2) {
                                        Text(String(localized: "field.description")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                    }
                                    TextField("e.g. Groceries", text: $description)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text(String(localized: "field.date")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    DatePicker("", selection: $occurredAt, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().tint(theme.primary)
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Classification
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "section.classification")).font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                if !isTransfer {
                                    HStack {
                                        Text(String(localized: "field.category")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Picker("Category", selection: $selectedCategory) {
                                            Text("Select").tag(Optional<CategoryOption>.none)
                                            ForEach(categories) { cat in
                                                Text("\(cat.icon) \(cat.name)").tag(Optional(cat))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(theme.primary)
                                    }
                                }

                                HStack {
                                    Text(String(localized: "field.fromAccount")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Spacer()
                                    Picker("From Account", selection: $selectedFromAccount) {
                                        Text("Select").tag(Optional<AccountOption>.none)
                                        ForEach(accounts) { acc in
                                            Text(acc.name).tag(Optional(acc))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(theme.primary)
                                }

                                if isTransfer {
                                    HStack {
                                        Text(String(localized: "field.toAccount")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Picker("To Account", selection: $selectedToAccount) {
                                            Text("Select").tag(Optional<AccountOption>.none)
                                            ForEach(accounts.filter { $0.id != selectedFromAccount?.id }) { acc in
                                                Text(acc.name).tag(Optional(acc))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(theme.primary)
                                    }
                                } else {
                                    HStack {
                                        Text(String(localized: "field.vendor")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Picker("Vendor", selection: $selectedVendor) {
                                            Text("None").tag(Optional<VendorOption>.none)
                                            ForEach(vendors) { v in
                                                Text(v.name).tag(Optional(v))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(theme.primary)
                                    }
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                        }
                        .padding(PPSpacing.xl)
                    }
                }
            }
            .navigationTitle(String(localized: "nav.editTransaction")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await update() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .foregroundColor(.ppTextSecondary)
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
                }
            }
            .task { await loadOptions() }
        }
    }

    private func loadOptions() async {
        isLoadingOptions = true

        // Pre-populate from transaction
        amountText = String(format: "%.2f", Double(transaction.amount) / 100.0)
        description = transaction.description
        occurredAt = DateFormatter.apiDate.date(from: transaction.date) ?? Date()
        isTransfer = transaction.toAccount != nil

        do {
            let store = appState.dataStore
            if let periodId = appState.selectedPeriod?.id, !store.isLoaded {
                try await store.loadAll(periodId: periodId)
            }

            let allCats = store.categories.filter { $0.status == "active" }
                .map { CategoryOption(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color) }
            transferCategory = allCats.first(where: { $0.name == "Transfer" })
            categories = allCats.filter { $0.name != "Transfer" }
            accounts = store.accounts.map { AccountOption(id: $0.id, name: $0.name, color: $0.color) }
            vendors = store.vendors.filter { $0.status == "active" }
                .map { VendorOption(id: $0.id, name: $0.name) }

            // Match selections
            if isTransfer {
                selectedCategory = transferCategory
            } else {
                selectedCategory = categories.first { $0.id == transaction.category.id }
            }
            selectedFromAccount = accounts.first { $0.id == transaction.fromAccount.id }
            selectedToAccount = transaction.toAccount.flatMap { to in accounts.first { $0.id == to.id } }
            selectedVendor = transaction.vendor.flatMap { v in vendors.first { $0.id == v.id } }
        } catch {
            errorMessage = String(localized: "Failed to load options.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isLoadingOptions = false
    }

    private func update() async {
        isLoading = true; errorMessage = nil

        guard let categoryId = selectedCategory?.id,
              let fromAccountId = selectedFromAccount?.id else {
            errorMessage = String(localized: "Select a category and account.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            isLoading = false; return
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        struct Req: Encodable {
            let amount: Int64; let description: String; let date: String
            let categoryId: UUID; let fromAccountId: UUID; let toAccountId: UUID?; let vendorId: UUID?
            let transactionType: String
        }

        let req = Req(
            amount: amountInCents,
            description: description.trimmingCharacters(in: .whitespaces),
            date: fmt.string(from: occurredAt),
            categoryId: categoryId,
            fromAccountId: fromAccountId,
            toAccountId: isTransfer ? selectedToAccount?.id : nil,
            vendorId: isTransfer ? nil : selectedVendor?.id,
            transactionType: isTransfer ? "Transfer" : "Regular"
        )

        do {
            try await appState.apiClient.request(.updateTransaction(transaction.id), body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onUpdated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to update transaction.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
