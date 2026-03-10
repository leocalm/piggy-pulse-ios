import SwiftUI

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
@Environment(\.colorScheme) private var colorScheme

    let filterOptions: TransactionFilterOptions
    let isLoadingOptions: Bool

    // Local draft state — only committed on Apply
    @State private var draftAccountIds: Set<UUID>
    @State private var draftCategoryIds: Set<UUID>
    @State private var draftVendorIds: Set<UUID>

    @State private var selectionFeedback = UISelectionFeedbackGenerator()
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .medium)

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

                        if !draftAccountIds.isEmpty || !draftCategoryIds.isEmpty || !draftVendorIds.isEmpty {
                            Section {
                                Button("Clear All") {
                                    impactFeedback.impactOccurred()
                                    draftAccountIds = []
                                    draftCategoryIds = []
                                    draftVendorIds = []
                                }
                                .foregroundColor(.ppDestructive)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
            }
            .onAppear {
                selectionFeedback.prepare()
                impactFeedback.prepare()
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
            selectionFeedback.selectionChanged()
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
        .buttonStyle(.plain)
    }
}
