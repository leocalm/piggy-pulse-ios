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

                            // Submit
                            Button {
                                Task { await createTransaction() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Label("Add Transaction", systemImage: "plus.circle")
                                            .font(.ppHeadline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PPSpacing.md)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.ppPrimary)
                            .cornerRadius(PPRadius.full)
                            .disabled(isDisabled)
                            .opacity(isDisabled ? 0.6 : 1)
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ppTextSecondary)
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
            .cornerRadius(PPRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.lg)
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

            PPTextField(
                label: "Description",
                placeholder: "e.g. Groceries at Albert Heijn",
                isRequired: true,
                text: $description
            )

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
        .cornerRadius(PPRadius.lg)
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

            // Category picker
            pickerRow(
                label: "Category",
                selection: selectedCategory.map { "\($0.icon) \($0.name)" } ?? "Select category",
                isRequired: true
            ) {
                ForEach(categories) { cat in
                    Button("\(cat.icon) \(cat.name)") {
                        selectedCategory = cat
                        isTransfer = cat.categoryType == "Transfer"
                    }
                }
            }

            // From account picker
            pickerRow(
                label: "From Account",
                selection: selectedFromAccount?.name ?? "Select account",
                isRequired: true
            ) {
                ForEach(accounts) { acc in
                    Button {
                        selectedFromAccount = acc
                    } label: {
                        HStack {
                            Text(acc.name)
                                .foregroundColor(.ppTextPrimary)
                            Spacer()
                            if selectedFromAccount?.id == acc.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.ppPrimary)
                            }
                        }
                    }
                }
            }

            // To account (only for transfers)
            if isTransfer {
                pickerRow(
                    label: "To Account",
                    selection: selectedToAccount?.name ?? "Select account",
                    isRequired: true
                ) {
                    ForEach(accounts.filter { $0.id != selectedFromAccount?.id }) { acc in
                        Button {
                            selectedToAccount = acc
                        } label: {
                            HStack {
                                Text(acc.name)
                                    .foregroundColor(.ppTextPrimary)
                                Spacer()
                                if selectedToAccount?.id == acc.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.ppPrimary)
                                }
                            }
                        }
                    }
                }
            } else {
                pickerRow(
                    label: "Vendor",
                    selection: selectedVendor?.name ?? "None",
                    isRequired: false
                ) {
                    VStack(spacing: 0) {
                        Button {
                            selectedVendor = nil
                        } label: {
                            HStack {
                                Text("None")
                                    .foregroundColor(.ppTextPrimary)
                                Spacer()
                                if selectedVendor == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.ppPrimary)
                                }
                            }
                        }
                        ForEach(vendors) { vendor in
                            Button {
                                selectedVendor = vendor
                            } label: {
                                HStack {
                                    Text(vendor.name)
                                        .foregroundColor(.ppTextPrimary)
                                    Spacer()
                                    if selectedVendor?.id == vendor.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.ppPrimary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Picker Row Helper

    private func pickerRow<Content: View>(
        label: String,
        selection: String,
        isRequired: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack(spacing: 2) {
                Text(label)
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                if isRequired {
                    Text("*")
                        .font(.ppCallout)
                        .foregroundColor(.ppDestructive)
                }
            }

            Menu {
                content()
            } label: {
                HStack {
                    Text(selection)
                        .font(.ppBody)
                        .foregroundColor(
                            selection.starts(with: "Select") ? .ppTextTertiary : .ppTextPrimary
                        )
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.ppTextSecondary)
                }
                .padding(.horizontal, PPSpacing.lg)
                .padding(.vertical, PPSpacing.md)
                .background(Color.ppSurface)
                .cornerRadius(PPRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: PPRadius.md)
                        .stroke(Color.ppBorder, lineWidth: 1)
                )
            }
        }
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

            // Fetch categories (options endpoint)
            let categoriesResponse: [CategoryOption] = try await appState.apiClient.request(
                .categoryOptions
            )
            categories = categoriesResponse

            // Also fetch the Transfer category (system, not included in options)
            if let transferCat: CategoryOption = try? await appState.apiClient.request(.transferCategory) {
                if !categories.contains(where: { $0.id == transferCat.id }) {
                    categories.append(transferCat)
                }
            }



            // Fetch vendors (paginated)
            let vendorsResponse: PaginatedResponse<VendorOption> = try await appState.apiClient.request(
                .vendors,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            vendors = vendorsResponse.data
        } catch {
            errorMessage = "Failed to load form options."
        }

        isLoadingOptions = false
    }

    // MARK: - Create Transaction

    private func createTransaction() async {
        isLoading = true
        errorMessage = nil

        guard let categoryId = selectedCategory?.id,
              let fromAccountId = selectedFromAccount?.id else {
            errorMessage = "Please select a category and account."
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
            let _: Transaction = try await appState.apiClient.request(.createTransaction, body: request)
            onCreated()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to create transaction."
        }

        isLoading = false
    }
}
