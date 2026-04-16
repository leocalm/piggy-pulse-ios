import SwiftUI

struct AddTransactionSheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    // Form fields
    @State private var amountText = ""
    @State private var description = ""
    @State private var occurredAt = Date()
    @State private var selectedCategory: CategoryOption?
    @State private var selectedFromAccount: AccountOption?
    @State private var selectedToAccount: AccountOption?
    @State private var selectedVendor: VendorOption?
    @State private var isTransfer = false

    // Options
    @State private var categories: [CategoryOption] = []
    @State private var transferCategory: CategoryOption?
    @State private var accounts: [AccountOption] = []
    @State private var vendors: [VendorOption] = []

    // State
    @State private var isLoading = false
    @State private var isLoadingOptions = true
    @State private var errorMessage: String?

    var onCreated: () -> Void

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
        (!isTransfer && selectedCategory == nil) ||
        selectedFromAccount == nil ||
        (isTransfer && selectedToAccount == nil) ||
        isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                if isLoadingOptions {
                    ProgressView()
                        .tint(.ppTextSecondary)
                } else {
                    ScrollView {
                        VStack(spacing: PPSpacing.xl) {
                            if let error = errorMessage {
                                Text(error)
                                    .font(.ppCallout)
                                    .foregroundColor(.ppDestructive)
                                    .multilineTextAlignment(.center)
                            }

                            // Amount
                            amountSection

                            // Details
                            detailsSection

                            // Classification
                            classificationSection
                        }
                        .padding(PPSpacing.xl)
                    }
                }
            }
            .navigationTitle(String(localized: "nav.addTransaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                        Task { await createTransaction() }
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
                    .accessibilityIdentifier("transaction-form-submit")
                }
            }
            .task {
                await loadOptions()
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "field.amount"))
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            HStack(alignment: .center, spacing: PPSpacing.sm) {
                Text(currencySymbol)
                    .font(.ppAmount)
                    .foregroundColor(.ppTextSecondary)

                TextField("0.00", text: $amountText)
                    .font(.ppAmount)
                    .foregroundColor(.ppTextPrimary)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("transaction-amount-input")
            }
            .padding(PPSpacing.lg)
            .background(Color.ppSurface)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )

            Toggle(isOn: $isTransfer) {
                Text(String(localized: "transaction.transferBetween"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextPrimary)
            }
            .tint(theme.primary)
            .accessibilityIdentifier("transaction-transfer-toggle")
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
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "section.details"))
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text(String(localized: "field.description")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                TextField("e.g. Groceries at Albert Heijn", text: $description)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    .accessibilityIdentifier("transaction-description-input")
            }

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                Text(String(localized: "field.date"))
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)

                DatePicker("", selection: $occurredAt, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(theme.primary)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Classification Section

    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "section.classification"))
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            // Category picker (hidden when transfer — category is auto-set)
            if !isTransfer {
                HStack {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.category")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    Spacer()
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select category").tag(Optional<CategoryOption>.none)
                        ForEach(categories) { cat in
                            Text("\(cat.icon) \(cat.name)").tag(Optional(cat))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.primary)
                    .accessibilityIdentifier("transaction-category-select")
                }
            }

            // From account picker
            HStack {
                HStack(spacing: 2) {
                    Text(String(localized: "field.fromAccount")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                Spacer()
                Picker("From Account", selection: $selectedFromAccount) {
                    Text("Select account").tag(Optional<AccountOption>.none)
                    ForEach(accounts) { acc in
                        Text(acc.name).tag(Optional(acc))
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.primary)
                .accessibilityIdentifier("transaction-account-select")
            }

            // To account (only for transfers)
            if isTransfer {
                HStack {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.toAccount")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    Spacer()
                    Picker("To Account", selection: $selectedToAccount) {
                        Text("Select account").tag(Optional<AccountOption>.none)
                        ForEach(accounts.filter { $0.id != selectedFromAccount?.id }) { acc in
                            Text(acc.name).tag(Optional(acc))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.primary)
                    .accessibilityIdentifier("transaction-to-account-select")
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
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Load Options

    private func loadOptions() async {
        isLoadingOptions = true

        let store = appState.dataStore
        // Always refresh to pick up newly created entities
        if let periodId = appState.selectedPeriod?.id {
            store.clear()
            try? await store.loadAll(periodId: periodId)
        }

        accounts = store.accounts.map { AccountOption(id: $0.id, name: $0.name, color: $0.color) }
        let allCats = store.categories.filter { $0.status == "active" }
            .map { CategoryOption(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color) }
        transferCategory = allCats.first(where: { $0.name == "Transfer" })
        categories = allCats.filter { $0.name != "Transfer" }
        vendors = store.vendors.filter { $0.status == "active" }
            .map { VendorOption(id: $0.id, name: $0.name) }

        isLoadingOptions = false
    }

    // MARK: - Create Transaction

    private func createTransaction() async {
        isLoading = true
        errorMessage = nil

        let categoryId = selectedCategory?.id ?? transferCategory?.id
        guard let categoryId, let fromAccountId = selectedFromAccount?.id else {
            errorMessage = String(localized: "Please select a category and account.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            isLoading = false
            return
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        struct CreateTransactionRequest: Encodable {
            let amount: Int64
            let description: String
            let date: String
            let categoryId: UUID
            let fromAccountId: UUID
            let toAccountId: UUID?
            let vendorId: UUID?
            let transactionType: String
            enum CodingKeys: String, CodingKey {
                case amount, description, date, categoryId, fromAccountId, toAccountId, vendorId, transactionType
            }
            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(amount, forKey: .amount)
                try c.encode(description, forKey: .description)
                try c.encode(date, forKey: .date)
                try c.encode(categoryId, forKey: .categoryId)
                try c.encode(fromAccountId, forKey: .fromAccountId)
                try c.encodeIfPresent(toAccountId, forKey: .toAccountId)
                try c.encodeIfPresent(vendorId, forKey: .vendorId)
                try c.encode(transactionType, forKey: .transactionType)
            }
        }

        let request = CreateTransactionRequest(
            amount: amountInCents,
            description: description.trimmingCharacters(in: .whitespaces),
            date: fmt.string(from: occurredAt),
            categoryId: categoryId,
            fromAccountId: fromAccountId,
            toAccountId: isTransfer ? selectedToAccount?.id : nil,
            vendorId: selectedVendor?.id,
            transactionType: isTransfer ? "Transfer" : "Regular"
        )

        do {
            try await appState.apiClient.request(.createTransaction, body: request)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCreated()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to create transaction.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isLoading = false
    }
}
