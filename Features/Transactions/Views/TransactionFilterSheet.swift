import SwiftUI

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let filterOptions: TransactionFilterOptions
    let isLoadingOptions: Bool

    // Local draft state — only committed on Apply
    @State private var draftAccountIds: Set<UUID>
    @State private var draftCategoryIds: Set<UUID>
    @State private var draftVendorIds: Set<UUID>

    var onApply: (Set<UUID>, Set<UUID>, Set<UUID>) -> Void

    init(
        filterOptions: TransactionFilterOptions,
        isLoadingOptions: Bool,
        initialAccountIds: Set<UUID> = [],
        initialCategoryIds: Set<UUID> = [],
        initialVendorIds: Set<UUID> = [],
        onApply: @escaping (Set<UUID>, Set<UUID>, Set<UUID>) -> Void
    ) {
        self.filterOptions = filterOptions
        self.isLoadingOptions = isLoadingOptions
        self.onApply = onApply
        _draftAccountIds = State(initialValue: initialAccountIds)
        _draftCategoryIds = State(initialValue: initialCategoryIds)
        _draftVendorIds = State(initialValue: initialVendorIds)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingOptions {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(.ppTextSecondary)
                } else {
                    List {
                        if !filterOptions.accounts.isEmpty {
                            Section("Account") {
                                ForEach(filterOptions.accounts) { account in
                                    filterRow(
                                        title: account.name,
                                        id: account.id,
                                        selected: $draftAccountIds
                                    )
                                }
                            }
                        }

                        if !filterOptions.categories.isEmpty {
                            Section("Category") {
                                ForEach(filterOptions.categories) { category in
                                    filterRow(
                                        title: category.name,
                                        id: category.id,
                                        selected: $draftCategoryIds
                                    )
                                }
                            }
                        }

                        if !filterOptions.vendors.isEmpty {
                            Section("Vendor") {
                                ForEach(filterOptions.vendors) { vendor in
                                    filterRow(
                                        title: vendor.name,
                                        id: vendor.id,
                                        selected: $draftVendorIds
                                    )
                                }
                            }
                        }

                        Section {
                            Button("Clear All") {
                                UISelectionFeedbackGenerator().selectionChanged()
                                draftAccountIds = []
                                draftCategoryIds = []
                                draftVendorIds = []
                            }
                            .foregroundStyle(.ppDestructive)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draftAccountIds, draftCategoryIds, draftVendorIds)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func filterRow(title: String, id: UUID, selected: Binding<Set<UUID>>) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            if selected.wrappedValue.contains(id) {
                selected.wrappedValue.remove(id)
            } else {
                selected.wrappedValue.insert(id)
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.ppTextPrimary)
                Spacer()
                if selected.wrappedValue.contains(id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.ppPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
