import SwiftUI

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let filterOptions: TransactionFilterOptions
    let isLoadingOptions: Bool

    @Binding var selectedAccountIds: Set<UUID>
    @Binding var selectedCategoryIds: Set<UUID>
    @Binding var selectedVendorIds: Set<UUID>

    // Local draft state — only committed on Apply
    @State private var draftAccountIds: Set<UUID>
    @State private var draftCategoryIds: Set<UUID>
    @State private var draftVendorIds: Set<UUID>

    var onApply: (Set<UUID>, Set<UUID>, Set<UUID>) -> Void

    init(
        filterOptions: TransactionFilterOptions,
        isLoadingOptions: Bool,
        selectedAccountIds: Binding<Set<UUID>>,
        selectedCategoryIds: Binding<Set<UUID>>,
        selectedVendorIds: Binding<Set<UUID>>,
        onApply: @escaping (Set<UUID>, Set<UUID>, Set<UUID>) -> Void
    ) {
        self.filterOptions = filterOptions
        self.isLoadingOptions = isLoadingOptions
        self._selectedAccountIds = selectedAccountIds
        self._selectedCategoryIds = selectedCategoryIds
        self._selectedVendorIds = selectedVendorIds
        self.onApply = onApply
        _draftAccountIds = State(initialValue: selectedAccountIds.wrappedValue)
        _draftCategoryIds = State(initialValue: selectedCategoryIds.wrappedValue)
        _draftVendorIds = State(initialValue: selectedVendorIds.wrappedValue)
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
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        draftAccountIds = []
                        draftCategoryIds = []
                        draftVendorIds = []
                    }
                    .foregroundColor(.ppDestructive)
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
                    .foregroundColor(.ppTextPrimary)
                Spacer()
                if selected.wrappedValue.contains(id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.ppPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
