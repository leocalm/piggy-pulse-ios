import SwiftUI

struct SubscriptionDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let subscriptionId: UUID
    let apiClient: APIClient

    @State private var detail: SubscriptionDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showEditSheet = false
    @State private var showCancelSheet = false
    @State private var showDeleteConfirm = false

    private let repository: SubscriptionRepository

    init(subscriptionId: UUID, apiClient: APIClient) {
        self.subscriptionId = subscriptionId
        self.apiClient = apiClient
        self.repository = SubscriptionRepository(apiClient: apiClient)
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.ppTextSecondary)
            } else if let error = errorMessage {
                VStack(spacing: PPSpacing.md) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                    Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                    Button(String(localized: "subscription.retry")) { Task { await load() } }
                        .font(.ppHeadline).foregroundColor(.ppPrimary)
                }
            } else if let detail = detail {
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        // Info card
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            HStack {
                                Text(detail.name)
                                    .font(.ppTitle).foregroundColor(.ppTextPrimary)
                                Spacer()
                                statusBadge(detail.status)
                            }

                            Divider().background(Color.ppBorder)

                            infoRow(label: String(localized: "subscription.detail.amount"),
                                    value: formatCurrency(detail.billingAmount, code: appState.currencyCode))
                            infoRow(label: String(localized: "subscription.detail.cycle"),
                                    value: detail.billingCycle.displayName)
                            infoRow(label: String(localized: "subscription.detail.billingDay"),
                                    value: "\(detail.billingDay)")
                            infoRow(label: String(localized: "subscription.detail.nextCharge"),
                                    value: detail.nextChargeDate)

                            if let cancelledAt = detail.cancelledAt {
                                infoRow(label: String(localized: "subscription.detail.cancelledAt"),
                                        value: cancelledAt)
                            }

                            infoRow(label: String(localized: "subscription.detail.created"),
                                    value: detail.createdAt)
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Billing history
                        if !detail.billingHistory.isEmpty {
                            VStack(alignment: .leading, spacing: PPSpacing.md) {
                                Text(String(localized: "subscription.detail.history"))
                                    .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                ForEach(detail.billingHistory) { event in
                                    billingEventRow(event)
                                }
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                        }

                        // Action buttons
                        VStack(spacing: PPSpacing.md) {
                            if detail.status == .active {
                                Button {
                                    showEditSheet = true
                                } label: {
                                    HStack {
                                        Spacer()
                                        Label(String(localized: "subscription.edit"), systemImage: "pencil")
                                            .font(.ppHeadline)
                                        Spacer()
                                    }
                                    .padding(.vertical, PPSpacing.md)
                                    .background(Color.ppPrimary)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                }

                                Button {
                                    showCancelSheet = true
                                } label: {
                                    HStack {
                                        Spacer()
                                        Label(String(localized: "subscription.cancel"), systemImage: "xmark.circle")
                                            .font(.ppHeadline)
                                        Spacer()
                                    }
                                    .padding(.vertical, PPSpacing.md)
                                    .background(Color.ppAmber)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                }
                            }

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Label(String(localized: "subscription.delete"), systemImage: "trash")
                                        .font(.ppHeadline)
                                    Spacer()
                                }
                                .padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface)
                                .foregroundColor(.sharedDestructive)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
        }
        .navigationTitle(detail?.name ?? String(localized: "subscription.detail.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showEditSheet, onDismiss: { Task { await load() } }) {
            if let d = detail {
                let sub = Subscription(
                    id: d.id, name: d.name, categoryId: d.categoryId, vendorId: d.vendorId,
                    billingAmount: d.billingAmount, billingCycle: d.billingCycle, billingDay: d.billingDay,
                    nextChargeDate: d.nextChargeDate, status: d.status, cancelledAt: d.cancelledAt,
                    createdAt: d.createdAt, updatedAt: d.updatedAt
                )
                EditSubscriptionSheet(subscription: sub, apiClient: apiClient) { Task { await load() } }
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showCancelSheet, onDismiss: { Task { await load() } }) {
            if let d = detail {
                let sub = Subscription(
                    id: d.id, name: d.name, categoryId: d.categoryId, vendorId: d.vendorId,
                    billingAmount: d.billingAmount, billingCycle: d.billingCycle, billingDay: d.billingDay,
                    nextChargeDate: d.nextChargeDate, status: d.status, cancelledAt: d.cancelledAt,
                    createdAt: d.createdAt, updatedAt: d.updatedAt
                )
                CancelSubscriptionSheet(subscription: sub, apiClient: apiClient) { Task { await load() } }
                    .environmentObject(appState)
            }
        }
        .confirmationDialog(
            String(localized: "subscription.deleteConfirm"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "subscription.delete"), role: .destructive) {
                Task {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    do {
                        try await repository.deleteSubscription(id: subscriptionId)
                        dismiss()
                    } catch {
                        errorMessage = String(localized: "subscription.deleteFailed")
                    }
                }
            }
            Button(String(localized: "subscription.cancelAction"), role: .cancel) {}
        } message: {
            Text(String(localized: "subscription.deleteMessage"))
        }
    }

    // MARK: - Helpers

    private func statusBadge(_ status: SubscriptionStatus) -> some View {
        Text(statusText(status))
            .font(.ppCaption)
            .foregroundColor(statusColor(status))
            .padding(.horizontal, PPSpacing.sm)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
    }

    private func statusText(_ status: SubscriptionStatus) -> String {
        switch status {
        case .active: return String(localized: "subscription.status.active")
        case .paused: return String(localized: "subscription.status.paused")
        case .cancelled: return String(localized: "subscription.status.cancelled")
        }
    }

    private func statusColor(_ status: SubscriptionStatus) -> Color {
        switch status {
        case .active: return .ppPrimary
        case .paused: return .ppAmber
        case .cancelled: return .ppTextTertiary
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value)
                .font(.ppBody).foregroundColor(.ppTextPrimary)
        }
    }

    private func billingEventRow(_ event: BillingEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.date)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                HStack(spacing: PPSpacing.xs) {
                    if event.detected {
                        Text(String(localized: "subscription.detail.detected"))
                            .font(.ppCaption).foregroundColor(.ppTextSecondary)
                    }
                    if event.postCancellation {
                        Text(String(localized: "subscription.detail.postCancel"))
                            .font(.ppCaption).foregroundColor(.ppAmber)
                    }
                }
            }
            Spacer()
            Text(formatCurrency(event.amount, code: appState.currencyCode))
                .font(.ppHeadline).foregroundColor(.ppTextPrimary)
        }
        .padding(.vertical, PPSpacing.sm)
    }

    // MARK: - Load

    private func load() async {
        isLoading = true; errorMessage = nil
        do {
            detail = try await repository.fetchSubscription(id: subscriptionId)
        } catch {
            errorMessage = String(localized: "subscription.loadError")
        }
        isLoading = false
    }
}
