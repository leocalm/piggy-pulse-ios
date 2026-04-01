import SwiftUI

struct CategorySubscriptionSection: View {
    let categoryId: UUID
    let apiClient: APIClient
    let currencyCode: String
    var onSubscriptionChanged: (() -> Void)? = nil

    @StateObject private var viewModel = SubscriptionsViewModel()
    @State private var showAddSheet = false
    @State private var cancellingSubscription: Subscription?
    @State private var subscriptionToDelete: Subscription?

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            // Monthly target summary (hidden while loading)
            if !viewModel.isCategoryLoading {
                HStack {
                    VStack(alignment: .leading, spacing: PPSpacing.xs) {
                        Text(String(localized: "category.subscription.monthlyTarget"))
                            .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text(String(localized: "category.subscription.autoComputed"))
                            .font(.ppCaption).foregroundColor(.ppTextTertiary)
                    }
                    Spacer()
                    Text(formatCurrency(viewModel.categoryMonthlyCost, code: currencyCode))
                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                }
                .padding(PPSpacing.lg)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }

            // Subscription rows
            if viewModel.isCategoryLoading {
                HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                    .padding(.vertical, PPSpacing.lg)
            } else if viewModel.categorySubscriptions.isEmpty {
                Text(String(localized: "category.subscription.empty"))
                    .font(.ppBody).foregroundColor(.ppTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, PPSpacing.md)
            } else {
                VStack(spacing: PPSpacing.sm) {
                    ForEach(viewModel.categorySubscriptions) { sub in
                        subscriptionRow(sub)
                            .contextMenu {
                                if sub.status == .active || sub.status == .paused {
                                    Button {
                                        cancellingSubscription = sub
                                    } label: {
                                        Label(String(localized: "subscription.cancel"), systemImage: "xmark.circle")
                                    }
                                }
                                Button(role: .destructive) {
                                    subscriptionToDelete = sub
                                } label: {
                                    Label(String(localized: "common.delete"), systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // Add subscription button
            Button {
                showAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text(String(localized: "category.subscription.add"))
                        .font(.ppHeadline)
                }
                .foregroundColor(.ppTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }
        }
        .task {
            viewModel.configure(apiClient: apiClient)
            await viewModel.loadForCategory(categoryId: categoryId)
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            Task { await viewModel.loadForCategory(categoryId: categoryId) }
            onSubscriptionChanged?()
        }) {
            AddSubscriptionSheet(
                apiClient: apiClient,
                fixedCategoryId: categoryId,
                onCreated: {}
            )
        }
        .sheet(item: $cancellingSubscription, onDismiss: {
            Task { await viewModel.loadForCategory(categoryId: categoryId) }
            onSubscriptionChanged?()
        }) { sub in
            CancelSubscriptionSheet(subscription: sub, apiClient: apiClient) { }
        }
        .confirmationDialog(
            String(localized: "subscription.deleteConfirm"),
            isPresented: Binding(
                get: { subscriptionToDelete != nil },
                set: { if !$0 { subscriptionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "subscription.delete"), role: .destructive) {
                if let sub = subscriptionToDelete {
                    Task {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        await viewModel.deleteSubscription(id: sub.id, reloadAfter: false)
                        await viewModel.loadForCategory(categoryId: categoryId)
                        onSubscriptionChanged?()
                    }
                }
            }
            Button(String(localized: "subscription.cancelAction"), role: .cancel) {
                subscriptionToDelete = nil
            }
        } message: {
            Text(String(localized: "subscription.deleteMessage"))
        }
    }

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(.ppHeadline)
                    .foregroundColor(sub.status == .cancelled ? .ppTextTertiary : .ppTextPrimary)
                Text(sub.billingCycle.displayName)
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(sub.billingAmount, code: currencyCode))
                    .font(.ppHeadline)
                    .foregroundColor(sub.status == .cancelled ? .ppTextTertiary : .ppTextPrimary)
                if sub.status == .cancelled {
                    Text(String(localized: "subscription.status.cancelled"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                        .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                } else if sub.status == .paused {
                    Text(String(localized: "subscription.status.paused"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                        .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                } else {
                    Text(formatDateString(sub.nextChargeDate))
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                }
            }
        }
        .padding(PPSpacing.lg)
        .frame(minHeight: 60)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }
}
