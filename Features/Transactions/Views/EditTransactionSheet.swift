import SwiftUI

struct EditTransactionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

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
                                Text("Amount").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                                HStack {
                                    Text("€").font(.ppAmount).foregroundColor(.ppTextSecondary)
                                    TextField("0.00", text: $amountText).font(.ppAmount).foregroundColor(.ppTextPrimary).keyboardType(.decimalPad)
                                }
                                .padding(PPSpacing.lg).background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))

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
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Details
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text("Details").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack(spacing: 2) {
                                        Text("Description").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                    }
                                    TextField("e.g. Groceries", text: $description)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    DatePicker("", selection: $occurredAt, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().tint(.ppPrimary)
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Classification
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text("Classification").font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                if !isTransfer {
                                    HStack {
                                        Text("Category").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Picker("Category", selection: $selectedCategory) {
                                            Text("Select").tag(Optional<CategoryOption>.none)
                                            ForEach(categories) { cat in
                                                Text("\(cat.icon) \(cat.name)").tag(Optional(cat))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.ppPrimary)
                                    }
                                }

                                HStack {
                                    Text("From Account").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Spacer()
                                    Picker("From Account", selection: $selectedFromAccount) {
                                        Text("Select").tag(Optional<AccountOption>.none)
                                        ForEach(accounts) { acc in
                                            Text(acc.name).tag(Optional(acc))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.ppPrimary)
                                }

                                if isTransfer {
                                    HStack {
                                        Text("To Account").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Picker("To Account", selection: $selectedToAccount) {
                                            Text("Select").tag(Optional<AccountOption>.none)
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
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                        }
                        .padding(PPSpacing.xl)
                    }
                }
            }
            .navigationTitle("Edit Transaction").navigationBarTitleDisplayMode(.inline)
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
        occurredAt = DateFormatter.apiDate.date(from: transaction.occurredAt) ?? Date()
        isTransfer = transaction.toAccount != nil

        do {
            async let catsTask: [CategoryOption] = appState.apiClient.request(.categoryOptions)
            async let accsTask: [AccountOption] = appState.apiClient.request(.accountOptions)

            let periodId = appState.selectedPeriod?.id
            async let vendorsTask: PaginatedResponse<VendorOption> = appState.apiClient.request(
                .vendors,
                queryItems: [URLQueryItem(name: "period_id", value: periodId?.uuidString.lowercased() ?? "")]
            )

            transferCategory = try? await appState.apiClient.request(.transferCategory)
            categories = try await catsTask

            accounts = try await accsTask
            vendors = (try? await vendorsTask)?.data ?? []

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
            errorMessage = "Failed to load options."
        }

        isLoadingOptions = false
    }

    private func update() async {
        isLoading = true; errorMessage = nil

        guard let categoryId = selectedCategory?.id,
              let fromAccountId = selectedFromAccount?.id else {
            errorMessage = "Select a category and account."
            isLoading = false; return
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        struct Req: Encodable {
            let amount: Int64; let description: String; let occurredAt: String
            let categoryId: UUID; let fromAccountId: UUID; let toAccountId: UUID?; let vendorId: UUID?
        }

        let req = Req(
            amount: amountInCents,
            description: description.trimmingCharacters(in: .whitespaces),
            occurredAt: fmt.string(from: occurredAt),
            categoryId: categoryId,
            fromAccountId: fromAccountId,
            toAccountId: isTransfer ? selectedToAccount?.id : nil,
            vendorId: isTransfer ? nil : selectedVendor?.id
        )

        do {
            try await appState.apiClient.request(.updateTransaction(transaction.id), body: req)
            onUpdated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to update transaction." }
        isLoading = false
    }
}
