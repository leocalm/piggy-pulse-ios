import SwiftUI

struct VendorsView: View {
    @EnvironmentObject var appState: AppState
    @State private var vendors: [VendorListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingVendor: VendorListItem?
    @State private var vendorToDelete: VendorListItem?
    @State private var vendorToArchive: VendorListItem?

    var body: some View {
        List {
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
                } else if vendors.isEmpty {
                    Section {
                        VStack(spacing: PPSpacing.lg) {
                            Image(systemName: "storefront").font(.system(size: 40)).foregroundColor(.ppTextTertiary)
                            Text("No vendors yet").font(.ppBody).foregroundColor(.ppTextSecondary)
                            Text("Vendors are assigned when creating transactions.").font(.ppCallout).foregroundColor(.ppTextTertiary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(vendors) { vendor in
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
            .navigationTitle("Vendors")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.white)
                }
            }
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
