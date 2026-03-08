import SwiftUI

struct AddTransactionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle("Add Transaction")
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
            Text("Amount")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            HStack(alignment: .center, spacing: PPSpacing.sm) {
                Text("€")
                    .font(.ppAmount)
                    .foregroundColor(.ppTextSecondary)

                TextField("0.00", text: $amountText)
                    .font(.ppAmount)
                    .foregroundColor(.ppTextPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppSurface)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )

            Toggle(isOn: $isTransfer) {
                Text("Transfer between accounts")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextPrimary)
            }
            .tint(.ppPrimary)
            .onChange(of: isTransfer) { _, transfer in
                if transfer {
                    selectedCategory = transferCategory
                    selectedVendor = nil
                } else {
                    selectedToAccount = nil
                    if selectedCategory?.categoryType == "Transfer" {
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
            Text("Details")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text("Description").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                TextField("e.g. Groceries at Albert Heijn", text: $description)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                Text("Date")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)

                DatePicker("", selection: $occurredAt, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.ppPrimary)
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
            Text("Classification")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            // Category picker (hidden when transfer — category is auto-set)
            if !isTransfer {
                HStack {
                    HStack(spacing: 2) {
                        Text("Category").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                    .tint(.ppPrimary)
                }
            }

            // From account picker
            HStack {
                HStack(spacing: 2) {
                    Text("From Account").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                .tint(.ppPrimary)
            }

            // To account (only for transfers)
            if isTransfer {
                HStack {
                    HStack(spacing: 2) {
                        Text("To Account").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                    .tint(.ppPrimary)
                }
            } else {
                HStack {
                    Text("Vendor").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Spacer()
                    Picker("Vendor", selection: $selectedVendor) {
                        Text("None").tag(Optional<VendorOption>.none)
                        ForEach(vendors) { v in
                            Text(v.name).tag(Optional(v))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.ppPrimary)
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

        guard let periodId = appState.selectedPeriod?.id else {
            isLoadingOptions = false
            return
        }

        do {
            // Fetch accounts
            let accountsResponse: [AccountOption] = try await appState.apiClient.request(
                .accountOptions
            )
            accounts = accountsResponse

            // Fetch categories (options endpoint) — excludes transfer category
            categories = try await appState.apiClient.request(.categoryOptions)

            // Fetch transfer category separately for auto-assignment
            transferCategory = try? await appState.apiClient.request(.transferCategory)



            // Fetch vendors (paginated)
            let vendorsResponse: PaginatedResponse<VendorOption> = try await appState.apiClient.request(
                .vendors,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            vendors = vendorsResponse.data
        } catch {
            errorMessage = String(localized: "Failed to load form options.")
        }

        isLoadingOptions = false
    }

    // MARK: - Create Transaction

    private func createTransaction() async {
        isLoading = true
        errorMessage = nil

        guard let categoryId = selectedCategory?.id,
              let fromAccountId = selectedFromAccount?.id else {
            errorMessage = String(localized: "Please select a category and account.")
            isLoading = false
            return
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        struct CreateTransactionRequest: Encodable {
            let amount: Int64
            let description: String
            let occurredAt: String
            let categoryId: UUID
            let fromAccountId: UUID
            let toAccountId: UUID?
            let vendorId: UUID?
        }

        let request = CreateTransactionRequest(
            amount: amountInCents,
            description: description.trimmingCharacters(in: .whitespaces),
            occurredAt: fmt.string(from: occurredAt),
            categoryId: categoryId,
            fromAccountId: fromAccountId,
            toAccountId: isTransfer ? selectedToAccount?.id : nil,
            vendorId: selectedVendor?.id
        )

        do {
            try await appState.apiClient.request(.createTransaction, body: request)
            onCreated()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "Failed to create transaction.")
        }

        isLoading = false
    }
}
