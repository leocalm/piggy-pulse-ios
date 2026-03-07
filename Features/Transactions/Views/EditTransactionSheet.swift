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
                                .padding(PPSpacing.lg).background(Color.ppSurface).cornerRadius(PPRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Details
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text("Details").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                                PPTextField(label: "Description", placeholder: "e.g. Groceries", isRequired: true, text: $description)
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Date").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    DatePicker("", selection: $occurredAt, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().tint(.ppPrimary)
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Classification
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text("Classification").font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                pickerField("Category", selection: selectedCategory.map { "\($0.icon) \($0.name)" } ?? "Select") {
                                    ForEach(categories) { cat in
                                        Button("\(cat.icon) \(cat.name)") {
                                            selectedCategory = cat
                                            isTransfer = cat.categoryType == "Transfer"
                                            if isTransfer { selectedVendor = nil }
                                        }
                                    }
                                }

                                pickerField("From Account", selection: selectedFromAccount?.name ?? "Select") {
                                    ForEach(accounts) { acc in
                                        Button(acc.name) { selectedFromAccount = acc }
                                    }
                                }

                                if isTransfer {
                                    pickerField("To Account", selection: selectedToAccount?.name ?? "Select") {
                                        ForEach(accounts.filter { $0.id != selectedFromAccount?.id }) { acc in
                                            Button(acc.name) { selectedToAccount = acc }
                                        }
                                    }
                                } else {
                                    pickerField("Vendor", selection: selectedVendor?.name ?? "None") {
                                        Button("None") { selectedVendor = nil }
                                        ForEach(vendors) { v in
                                            Button(v.name) { selectedVendor = v }
                                        }
                                    }
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
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

    private func pickerField<Content: View>(_ label: String, selection: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            Text(label).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
            Menu { content() } label: {
                HStack {
                    Text(selection).font(.ppBody).foregroundColor(.ppTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(.ppTextSecondary)
                }
                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                .background(Color.ppSurface).cornerRadius(PPRadius.md)
                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }
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

            // Also fetch transfer category
            if let transferCat: CategoryOption = try? await appState.apiClient.request(.transferCategory) {
                var cats = try await catsTask
                if !cats.contains(where: { $0.id == transferCat.id }) { cats.append(transferCat) }
                categories = cats
            } else {
                categories = try await catsTask
            }

            accounts = try await accsTask
            vendors = (try? await vendorsTask)?.data ?? []

            // Match selections
            selectedCategory = categories.first { $0.id == transaction.category.id }
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
            let _: Transaction = try await appState.apiClient.request(.updateTransaction(transaction.id), body: req)
            onUpdated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to update transaction." }
        isLoading = false
    }
}
