import SwiftUI

struct EditSubscriptionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let subscription: Subscription
    let apiClient: APIClient
    var onUpdated: () -> Void

    @State private var name = ""
    @State private var selectedCategoryId: UUID?
    @State private var selectedVendorId: UUID?
    @State private var billingAmountText = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var billingDay: Int = 1
    @State private var nextChargeDate = Date()
    @State private var categories: [CategoryOption] = []
    @State private var vendors: [VendorOption] = []
    @State private var isLoading = false
    @State private var isLoadingOptions = true
    @State private var errorMessage: String?

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).count < 2 ||
        selectedCategoryId == nil ||
        billingAmountCents <= 0 ||
        isLoading
    }

    private var billingAmountCents: Int64 {
        let cleaned = billingAmountText.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: cleaned) else { return 0 }
        return NSDecimalNumber(decimal: decimal * 100).int64Value
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                        }

                        if isLoadingOptions {
                            HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                                .padding(.vertical, PPSpacing.xxxl)
                        } else {
                            // Subscription Details
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "subscription.form.details"))
                                    .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                formField(label: String(localized: "subscription.form.name"), required: true) {
                                    TextField(String(localized: "subscription.form.namePlaceholder"), text: $name)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                formField(label: String(localized: "subscription.form.category"), required: true) {
                                    Picker(String(localized: "subscription.form.category"), selection: $selectedCategoryId) {
                                        Text(String(localized: "subscription.form.selectCategory")).tag(Optional<UUID>.none)
                                        ForEach(categories) { cat in
                                            Text("\(cat.icon) \(cat.name)").tag(Optional(cat.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                formField(label: String(localized: "subscription.form.vendor"), required: false) {
                                    Picker(String(localized: "subscription.form.vendor"), selection: $selectedVendorId) {
                                        Text(String(localized: "subscription.form.none")).tag(Optional<UUID>.none)
                                        ForEach(vendors) { vendor in
                                            Text(vendor.name).tag(Optional(vendor.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                            // Billing Details
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "subscription.form.billing"))
                                    .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                formField(label: String(localized: "subscription.form.amount"), required: true) {
                                    TextField("0.00", text: $billingAmountText)
                                        .keyboardType(.decimalPad)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                formField(label: String(localized: "subscription.form.cycle"), required: true) {
                                    Picker(String(localized: "subscription.form.cycle"), selection: $billingCycle) {
                                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                            Text(cycle.displayName).tag(cycle)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                formField(label: String(localized: "subscription.form.billingDay"), required: true) {
                                    Stepper(value: $billingDay, in: 1...31) {
                                        Text("\(billingDay)")
                                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                formField(label: String(localized: "subscription.form.nextCharge"), required: true) {
                                    DatePicker(
                                        String(localized: "subscription.form.nextCharge"),
                                        selection: $nextChargeDate,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .font(.ppBody)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "subscription.edit.title")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isLoading { ProgressView() } else { Image(systemName: "checkmark") }
                    }
                    .foregroundColor(.ppTextSecondary)
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
                }
            }
            .task { await loadOptions() }
            .onAppear { populateForm() }
        }
    }

    // MARK: - Helpers

    private func formField<Content: View>(label: String, required: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack(spacing: 2) {
                Text(label).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                if required {
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
            }
            content()
        }
    }

    private func populateForm() {
        name = subscription.name
        selectedCategoryId = subscription.categoryId
        selectedVendorId = subscription.vendorId
        billingAmountText = String(format: "%.2f", Double(subscription.billingAmount) / 100.0)
        billingCycle = subscription.billingCycle
        billingDay = subscription.billingDay

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        if let date = fmt.date(from: subscription.nextChargeDate) {
            nextChargeDate = date
        }
    }

    // MARK: - Actions

    private func loadOptions() async {
        isLoadingOptions = true
        let store = appState.dataStore
        if store.isLoaded {
            categories = store.categories.filter { $0.status == "active" }
                .map { CategoryOption(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color) }
            vendors = store.vendors.filter { $0.status == "active" }
                .map { VendorOption(id: $0.id, name: $0.name) }
        } else {
            categories = (try? await apiClient.request(.categoryOptions) as [CategoryOption]) ?? []
            vendors = []
        }
        isLoadingOptions = false
    }

    private func save() async {
        isLoading = true; errorMessage = nil

        let req = UpdateSubscriptionRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            categoryId: selectedCategoryId ?? subscription.categoryId,
            vendorId: selectedVendorId,
            billingAmount: billingAmountCents,
            billingCycle: billingCycle,
            billingDay: billingDay,
            nextChargeDate: Self.dateFormatter.string(from: nextChargeDate)
        )

        do {
            let _: Subscription = try await apiClient.request(.updateSubscription(subscription.id), body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onUpdated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "subscription.updateError")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
