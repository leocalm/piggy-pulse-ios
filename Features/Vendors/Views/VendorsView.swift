import SwiftUI
import TipKit

struct VendorsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @Environment(\.isWideLayout) private var isWideLayout
    @State private var vendors: [VendorListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingVendor: VendorListItem?
    @State private var vendorToDelete: VendorListItem?
    @State private var vendorToArchive: VendorListItem?
    @State private var searchText = ""

    private let vendorsTip = VendorsTip()

    private var filteredVendors: [VendorListItem] {
        if searchText.isEmpty { return vendors }
        return vendors.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "more.vendors"), showTitle: false)
            } else {
                List {
                    // Tip
                    Section {
                        TipView(vendorsTip)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }

                    if isLoading {
                        Section {
                            HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                                .padding(.vertical, PPSpacing.xxxl)
                                .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if let error = errorMessage {
                        Section {
                            VStack(spacing: PPSpacing.md) {
                                Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(theme.secondary)
                                Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                                Button(String(localized: "common.retry")) { Task { await load() } }.font(.ppHeadline).foregroundColor(theme.primary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if vendors.isEmpty {
                        Section {
                            EmptyStateView(
                                icon: "storefront",
                                title: String(localized: "vendors.empty.title"),
                                message: String(localized: "vendors.empty.message"),
                                steps: [
                                    EmptyStateStep(
                                        title: String(localized: "vendors.empty.step1.title"),
                                        description: String(localized: "vendors.empty.step1.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "vendors.empty.step2.title"),
                                        description: String(localized: "vendors.empty.step2.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "vendors.empty.step3.title"),
                                        description: String(localized: "vendors.empty.step3.description")
                                    ),
                                ],
                                tips: [
                                    String(localized: "vendors.empty.tip1"),
                                    String(localized: "vendors.empty.tip2"),
                                    String(localized: "vendors.empty.tip3"),
                                ],
                                actionLabel: String(localized: "vendors.empty.action"),
                                action: { showAddSheet = true }
                            )
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }
                    } else if !vendors.isEmpty {
                        // Stats bar
                        Section {
                            vendorStatsBar
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }

                        // Search
                        Section {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.ppTextTertiary)
                                TextField(String(localized: "vendors.search"), text: $searchText)
                                    .font(.ppBody)
                                    .foregroundColor(.ppTextPrimary)
                                if !searchText.isEmpty {
                                    Button { searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.ppTextTertiary)
                                    }
                                }
                            }
                            .padding(PPSpacing.md)
                            .background(Color.ppCard)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }

                        // Vendor rows
                        Section {
                            if isWideLayout {
                                // Wide layout: 2-column grid
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: PPSpacing.md), GridItem(.flexible(), spacing: PPSpacing.md)], spacing: PPSpacing.md) {
                                    ForEach(filteredVendors) { vendor in
                                        vendorRow(vendor)
                                            .contextMenu {
                                                vendorContextMenu(vendor)
                                            }
                                    }
                                }
                                .listRowBackground(Color.ppBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                            } else {
                                ForEach(filteredVendors) { vendor in
                                    vendorRow(vendor)
                                        .swipeActions(edge: .trailing) {
                                            if vendor.transactionCount > 0 {
                                                Button {
                                                    vendorToArchive = vendor
                                                } label: {
                                                    Label(String(localized: "common.archive"), systemImage: "archivebox")
                                                }
                                                .tint(theme.secondary)
                                            } else {
                                                Button(role: .destructive) {
                                                    vendorToDelete = vendor
                                                } label: {
                                                    Label(String(localized: "common.delete"), systemImage: "trash")
                                                }
                                                .tint(.ppDestructive)
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button { editingVendor = vendor } label: { Label(String(localized: "common.edit"), systemImage: "pencil") }.tint(theme.primary)
                                        }
                                        .contextMenu {
                                            vendorContextMenu(vendor)
                                        }
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            }
                        } header: {
                            Text(String(localized: "vendors.section.all"))
                                .font(.ppOverline)
                                .foregroundColor(.ppTextSecondary)
                                .tracking(1)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ppBackground)
                .refreshable { await Task { @MainActor in await self.load() }.value }
                .task(id: appState.selectedPeriod?.id) { await load() }
                .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                    AddVendorSheet { }.environmentObject(appState)
                }
                .sheet(item: $editingVendor) { vendor in
                    EditVendorSheet(vendor: vendor) { Task { await load() } }
                        .environmentObject(appState)
                }
                .confirmationDialog("Archive \"\(vendorToArchive?.name ?? "")\"?", isPresented: Binding(get: { vendorToArchive != nil }, set: { if !$0 { vendorToArchive = nil } }), titleVisibility: .visible) {
                    Button(String(localized: "common.archive"), role: .destructive) {
                        if let vendor = vendorToArchive { Task { await archiveVendor(vendor) } }
                    }
                    Button(String(localized: "common.cancel"), role: .cancel) { vendorToArchive = nil }
                } message: {
                    Text(String(localized: "vendors.archive.message"))
                }
                .confirmationDialog("Delete \"\(vendorToDelete?.name ?? "")\"?", isPresented: Binding(get: { vendorToDelete != nil }, set: { if !$0 { vendorToDelete = nil } }), titleVisibility: .visible) {
                    Button(String(localized: "common.delete"), role: .destructive) {
                        if let vendor = vendorToDelete { Task { await deleteVendor(vendor) } }
                    }
                    Button(String(localized: "common.cancel"), role: .cancel) { vendorToDelete = nil }
                } message: {
                    Text(String(localized: "vendors.delete.message"))
                }
                .navigationTitle(String(localized: "more.vendors"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("vendors-add-button")
                    }
                }
            } // else
        } // NavigationStack
    }

    private var vendorStatsBar: some View {
        let activeVendors = vendors.filter { !$0.archived }
        let activeCount = activeVendors.count
        let totalTx = activeVendors.reduce(Int64(0)) { $0 + $1.transactionCount }
        let avgPerVendor = activeCount > 0 ? totalTx / Int64(activeCount) : 0

        return HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(activeCount)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "vendors.stats.active"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("\(totalTx)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "vendors.stats.totalTx"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("\(avgPerVendor)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "vendors.stats.avgTx"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    @ViewBuilder
    private func vendorContextMenu(_ vendor: VendorListItem) -> some View {
        Button {
            editingVendor = vendor
        } label: {
            Label(String(localized: "common.edit"), systemImage: "pencil")
        }
        if vendor.transactionCount > 0 {
            Button {
                vendorToArchive = vendor
            } label: {
                Label(String(localized: "common.archive"), systemImage: "archivebox")
            }
        } else {
            Button(role: .destructive) {
                vendorToDelete = vendor
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
    }

    private func deleteVendor(_ vendor: VendorListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteVendor(vendor.id))
            await load()
        } catch {
            errorMessage = String(localized: "vendors.delete.failed")
        }
    }

    private func archiveVendor(_ vendor: VendorListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.archiveVendor(vendor.id))
            await load()
        } catch {
            errorMessage = String(localized: "vendors.archive.failed")
        }
    }

    private func vendorRow(_ vendor: VendorListItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.name)
                    .font(.ppHeadline)
                    .foregroundColor(vendor.archived ? .ppTextTertiary : .ppTextPrimary)

                if let desc = vendor.description, !desc.isEmpty {
                    Text(desc)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(vendor.transactionCount) tx")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)

                if vendor.archived {
                    Text(String(localized: "common.archived"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                }
            }
        }
        .padding(PPSpacing.lg)
        .frame(minHeight: 68)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let page: PaginatedResponse<EncryptedVendor> = try await appState.apiClient.request(.vendors)
            vendors = try await appState.decryptionService.decrypt(page.data)
        } catch {
            errorMessage = String(localized: "Failed to load vendors.")
        }
        isLoading = false
    }
}
