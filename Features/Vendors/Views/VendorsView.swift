import SwiftUI
import TipKit

struct VendorsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
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
                                Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                                Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                                Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
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
                    } else if !filteredVendors.isEmpty {
                        Section {
                            ForEach(filteredVendors) { vendor in
                                vendorRow(vendor)
                                    .swipeActions(edge: .trailing) {
                                        if vendor.transactionCount > 0 {
                                            Button {
                                                vendorToArchive = vendor
                                            } label: {
                                                Label("Archive", systemImage: "archivebox")
                                            }
                                            .tint(.ppAmber)
                                        } else {
                                            Button(role: .destructive) {
                                                vendorToDelete = vendor
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(.ppDestructive)
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { editingVendor = vendor } label: { Label("Edit", systemImage: "pencil") }.tint(.ppPrimary)
                                    }
                                    .listRowBackground(Color.ppBackground)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                            }
                        } header: {
                            Text("ALL VENDORS")
                                .font(.ppOverline)
                                .foregroundColor(.ppTextSecondary)
                                .tracking(1)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ppBackground)
                .refreshable { await load() }
                .task(id: appState.selectedPeriod?.id) { await load() }
                .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                    AddVendorSheet { }.environmentObject(appState)
                }
                .sheet(item: $editingVendor) { vendor in
                    EditVendorSheet(vendor: vendor) { Task { await load() } }
                        .environmentObject(appState)
                }
                .confirmationDialog("Archive \"\(vendorToArchive?.name ?? "")\"?", isPresented: Binding(get: { vendorToArchive != nil }, set: { if !$0 { vendorToArchive = nil } }), titleVisibility: .visible) {
                    Button("Archive", role: .destructive) {
                        if let vendor = vendorToArchive { Task { await archiveVendor(vendor) } }
                    }
                    Button("Cancel", role: .cancel) { vendorToArchive = nil }
                } message: {
                    Text("This vendor will be hidden but its history will be preserved.")
                }
                .confirmationDialog("Delete \"\(vendorToDelete?.name ?? "")\"?", isPresented: Binding(get: { vendorToDelete != nil }, set: { if !$0 { vendorToDelete = nil } }), titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        if let vendor = vendorToDelete { Task { await deleteVendor(vendor) } }
                    }
                    Button("Cancel", role: .cancel) { vendorToDelete = nil }
                } message: {
                    Text("This vendor will be permanently deleted.")
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
                    }
                }
            } // else
        } // NavigationStack
    }

    private var vendorStatsBar: some View {
        let activeCount = vendors.filter { !$0.archived }.count
        let totalTx = vendors.reduce(Int64(0)) { $0 + $1.transactionCount }
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

    private func deleteVendor(_ vendor: VendorListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteVendor(vendor.id))
            await load()
        } catch {}
    }

    private func archiveVendor(_ vendor: VendorListItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.archiveVendor(vendor.id))
            await load()
        } catch {}
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
                    Text("Archived")
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
        guard let periodId = appState.selectedPeriod?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response: PaginatedResponse<VendorListItem> = try await appState.apiClient.request(
                .vendors,
                queryItems: [URLQueryItem(name: "period_id", value: periodId.uuidString.lowercased())]
            )
            vendors = response.data
        } catch {
            errorMessage = String(localized: "Failed to load vendors.")
        }
        isLoading = false
    }
}
