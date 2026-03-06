import SwiftUI

struct VendorsView: View {
    @EnvironmentObject var appState: AppState
    @State private var vendors: [VendorListItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text("Vendors")
                        .font(.ppLargeTitle)
                        .foregroundColor(.ppPrimary)
                    Text("Track where transactions occur.")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }
                .listRowBackground(Color.ppBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: PPSpacing.lg, leading: PPSpacing.lg, bottom: PPSpacing.md, trailing: PPSpacing.lg))
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
                        .cornerRadius(PPRadius.full)
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.md)
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
            errorMessage = "Failed to load vendors."
        }
        isLoading = false
    }
}
