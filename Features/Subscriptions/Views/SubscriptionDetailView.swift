import SwiftUI

struct SubscriptionDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    let subscription: Subscription
    let apiClient: APIClient

    @State private var currentSub: Subscription
    @State private var showEditSheet = false
    @State private var showCancelSheet = false
    @State private var showDeleteConfirm = false

    private var repository: SubscriptionRepository {
        SubscriptionRepository(apiClient: apiClient, decryptionService: appState.decryptionService)
    }

    init(subscription: Subscription, apiClient: APIClient) {
        self.subscription = subscription
        self.apiClient = apiClient
        self._currentSub = State(initialValue: subscription)
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: PPSpacing.xl) {
                    VStack(alignment: .leading, spacing: PPSpacing.lg) {
                        HStack {
                            Text(currentSub.name)
                                .font(.ppTitle).foregroundColor(.ppTextPrimary)
                            Spacer()
                            statusBadge(currentSub.status)
                        }

                        Divider().background(Color.ppBorder)

                        infoRow(label: String(localized: "subscription.detail.amount"),
                                value: formatCurrency(currentSub.billingAmount, code: appState.currencyCode))
                        infoRow(label: String(localized: "subscription.detail.cycle"),
                                value: currentSub.billingCycle.displayName)
                        infoRow(label: String(localized: "subscription.detail.billingDay"),
                                value: "\(currentSub.billingDay)")
                        infoRow(label: String(localized: "subscription.detail.nextCharge"),
                                value: formatDateString(currentSub.nextChargeDate))

                        if let cancelledAt = currentSub.cancelledAt {
                            infoRow(label: String(localized: "subscription.detail.cancelledAt"),
                                    value: formatDateString(cancelledAt))
                        }

                        infoRow(label: String(localized: "subscription.detail.created"),
                                value: formatDateString(currentSub.createdAt))
                    }
                    .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                    VStack(spacing: PPSpacing.md) {
                        if currentSub.status == .active {
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
                                .background(theme.primary)
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
                                .background(theme.secondary)
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
        .navigationTitle(currentSub.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditSubscriptionSheet(subscription: currentSub, apiClient: apiClient) { }
                .environmentObject(appState)
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelSubscriptionSheet(subscription: currentSub, apiClient: apiClient) { }
                .environmentObject(appState)
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
                        try await repository.deleteSubscription(id: subscription.id)
                        dismiss()
                    } catch {}
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
        case .active: return theme.primary
        case .paused: return theme.secondary
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
}
