import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: SubscriptionsViewModel
    @State private var showAddSheet = false
    @State private var editingSubscription: Subscription?
    @State private var cancellingSubscription: Subscription?
    @State private var subscriptionToDelete: Subscription?
    @State private var selectedSubscription: Subscription?
    @State private var showCancelled = false

    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        _viewModel = StateObject(wrappedValue: SubscriptionsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "more.subscriptions"), showTitle: false)
            } else {
                List {
                    if viewModel.isLoading {
                        Section {
                            HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                                .padding(.vertical, PPSpacing.xxxl)
                                .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if let error = viewModel.errorMessage {
                        Section {
                            VStack(spacing: PPSpacing.md) {
                                Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                                Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                                Button(String(localized: "subscription.retry")) { Task { await viewModel.load() } }
                                    .font(.ppHeadline).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if viewModel.subscriptions.isEmpty {
                        Section {
                            VStack(spacing: PPSpacing.lg) {
                                Image(systemName: "repeat").font(.system(size: 40)).foregroundColor(.ppTextTertiary)
                                Text(String(localized: "subscription.empty.title")).font(.ppBody).foregroundColor(.ppTextSecondary)
                                Text(String(localized: "subscription.empty.subtitle")).font(.ppCallout).foregroundColor(.ppTextTertiary).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else {
                        // Stats bar
                        Section {
                            statsBar
                                .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.sm, leading: PPSpacing.lg, bottom: PPSpacing.sm, trailing: PPSpacing.lg))
                        }

                        // Upcoming charges
                        if !viewModel.upcomingCharges.isEmpty {
                            Section {
                                ForEach(viewModel.upcomingCharges) { charge in
                                    upcomingChargeRow(charge)
                                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            } header: {
                                Text(String(localized: "subscription.upcoming"))
                                    .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                            }
                        }

                        // Active subscriptions
                        if !viewModel.activeSubs.isEmpty {
                            Section {
                                ForEach(viewModel.activeSubs) { sub in
                                    subscriptionRow(sub)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedSubscription = sub }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { cancellingSubscription = sub } label: {
                                                Label(String(localized: "subscription.cancel"), systemImage: "xmark.circle")
                                            }
                                            .tint(.ppAmber)
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button { editingSubscription = sub } label: {
                                                Label(String(localized: "subscription.edit"), systemImage: "pencil")
                                            }
                                            .tint(.ppPrimary)
                                        }
                                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            } header: {
                                Text(String(localized: "subscription.active"))
                                    .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                            }
                        }

                        // Paused subscriptions
                        if !viewModel.pausedSubs.isEmpty {
                            Section {
                                ForEach(viewModel.pausedSubs) { sub in
                                    subscriptionRow(sub)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedSubscription = sub }
                                        .swipeActions(edge: .leading) {
                                            Button { editingSubscription = sub } label: {
                                                Label(String(localized: "subscription.edit"), systemImage: "pencil")
                                            }
                                            .tint(.ppPrimary)
                                        }
                                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            } header: {
                                Text(String(localized: "subscription.paused"))
                                    .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                            }
                        }

                        // Cancelled subscriptions (collapsible)
                        if !viewModel.cancelledSubs.isEmpty {
                            Section {
                                Button {
                                    withAnimation { showCancelled.toggle() }
                                } label: {
                                    HStack {
                                        Text(String(localized: "subscription.cancelled"))
                                            .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                                        Spacer()
                                        Image(systemName: showCancelled ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.ppTextTertiary)
                                        Text("\(viewModel.cancelledSubs.count)")
                                            .font(.ppCaption).foregroundColor(.ppTextTertiary)
                                    }
                                }
                                .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))

                                if showCancelled {
                                    ForEach(viewModel.cancelledSubs) { sub in
                                        subscriptionRow(sub)
                                            .contentShape(Rectangle())
                                            .onTapGesture { selectedSubscription = sub }
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) { subscriptionToDelete = sub } label: {
                                                    Label(String(localized: "subscription.delete"), systemImage: "trash")
                                                }
                                                .tint(.ppDestructive)
                                            }
                                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ppBackground)
                .refreshable { await viewModel.load() }
                .task { await viewModel.load() }
                .sheet(isPresented: $showAddSheet, onDismiss: { Task { await viewModel.load() } }) {
                    AddSubscriptionSheet(apiClient: apiClient) { }
                        .environmentObject(appState)
                }
                .sheet(item: $editingSubscription, onDismiss: { Task { await viewModel.load() } }) { sub in
                    EditSubscriptionSheet(subscription: sub, apiClient: apiClient) { }
                        .environmentObject(appState)
                }
                .sheet(item: $cancellingSubscription, onDismiss: { Task { await viewModel.load() } }) { sub in
                    CancelSubscriptionSheet(subscription: sub, apiClient: apiClient) { }
                        .environmentObject(appState)
                }
                .navigationDestination(item: $selectedSubscription) { sub in
                    SubscriptionDetailView(subscriptionId: sub.id, apiClient: apiClient)
                        .environmentObject(appState)
                }
                .confirmationDialog(
                    String(localized: "subscription.deleteConfirm"),
                    isPresented: Binding(get: { subscriptionToDelete != nil }, set: { if !$0 { subscriptionToDelete = nil } }),
                    titleVisibility: .visible
                ) {
                    Button(String(localized: "subscription.delete"), role: .destructive) {
                        if let sub = subscriptionToDelete {
                            Task {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                await viewModel.deleteSubscription(id: sub.id)
                            }
                        }
                    }
                    Button(String(localized: "subscription.cancelAction"), role: .cancel) { subscriptionToDelete = nil }
                } message: {
                    Text(String(localized: "subscription.deleteMessage"))
                }
                .navigationTitle(String(localized: "more.subscriptions"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: PPSpacing.sm) {
            statCard(
                title: String(localized: "subscription.stats.monthly"),
                value: formatCurrency(viewModel.monthlyCost, code: appState.currencyCode)
            )
            statCard(
                title: String(localized: "subscription.stats.yearly"),
                value: formatCurrency(viewModel.yearlyCost, code: appState.currencyCode)
            )
            statCard(
                title: String(localized: "subscription.stats.active"),
                value: "\(viewModel.activeSubs.count)"
            )
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: PPSpacing.xs) {
            Text(value)
                .font(.ppHeadline)
                .foregroundColor(.ppTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.ppCaption)
                .foregroundColor(.ppTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PPSpacing.md)
        .padding(.horizontal, PPSpacing.sm)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    // MARK: - Rows

    private func upcomingChargeRow(_ charge: UpcomingCharge) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(charge.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                if let vendorName = charge.vendorName {
                    Text(vendorName)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(charge.billingAmount, code: appState.currencyCode))
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                Text(charge.nextChargeDate)
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
        }
        .padding(PPSpacing.lg)
        .frame(minHeight: 60)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
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
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(sub.billingAmount, code: appState.currencyCode))
                    .font(.ppHeadline)
                    .foregroundColor(sub.status == .cancelled ? .ppTextTertiary : .ppTextPrimary)
                if sub.status == .cancelled {
                    Text(String(localized: "subscription.status.cancelled"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                } else if sub.status == .paused {
                    Text(String(localized: "subscription.status.paused"))
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                        .padding(.horizontal, PPSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                } else {
                    Text(sub.nextChargeDate)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
        }
        .padding(PPSpacing.lg)
        .frame(minHeight: 68)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }
}
