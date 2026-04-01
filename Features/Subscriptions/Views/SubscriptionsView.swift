import SwiftUI
import TipKit

struct SubscriptionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = SubscriptionsViewModel()
    @State private var cancellingSubscription: Subscription?
    @State private var subscriptionToDelete: Subscription?
    @State private var selectedSubscription: Subscription?
    @State private var showCancelled = false
    @State private var allCategories: [CategoryManagementItem] = []
    @State private var managingCategory: CategoryManagementItem?

    private let subscriptionsTip = SubscriptionsTip()

    var body: some View {
        NavigationStack {
            if appState.selectedPeriod == nil {
                NoPeriodStateView(pageTitle: String(localized: "more.subscriptions"), showTitle: false)
            } else {
                List {
                    // Tip
                    Section {
                        TipView(subscriptionsTip)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }

                    if viewModel.isLoading {
                        Section {
                            HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                                .padding(.vertical, PPSpacing.xxxl)
                                .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if let error = viewModel.errorMessage {
                        Section {
                            VStack(spacing: PPSpacing.md) {
                                Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(theme.secondary)
                                Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                                Button(String(localized: "subscription.retry")) { Task { await viewModel.load() } }
                                    .font(.ppHeadline).foregroundColor(theme.primary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                        }
                    } else if viewModel.subscriptions.isEmpty {
                        Section {
                            EmptyStateView(
                                icon: "repeat",
                                title: String(localized: "subscriptions.empty.title"),
                                message: String(localized: "subscriptions.empty.message"),
                                steps: [
                                    EmptyStateStep(
                                        title: String(localized: "subscriptions.empty.step1.title"),
                                        description: String(localized: "subscriptions.empty.step1.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "subscriptions.empty.step2.title"),
                                        description: String(localized: "subscriptions.empty.step2.description")
                                    ),
                                    EmptyStateStep(
                                        title: String(localized: "subscriptions.empty.step3.title"),
                                        description: String(localized: "subscriptions.empty.step3.description")
                                    ),
                                ],
                                tips: [
                                    String(localized: "subscriptions.empty.tip1"),
                                    String(localized: "subscriptions.empty.tip2"),
                                    String(localized: "subscriptions.empty.tip3"),
                                ],
                                actionLabel: nil,
                                action: nil
                            )
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
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
                                            Button { cancellingSubscription = sub } label: {
                                                Label(String(localized: "subscription.cancel"), systemImage: "xmark.circle")
                                            }
                                            .tint(theme.secondary)
                                        }
                                        .contextMenu {
                                            Button { Task { await loadCategoryAndManage(sub) } } label: {
                                                Label(String(localized: "subscription.manage.category"), systemImage: "folder")
                                            }
                                            Button { cancellingSubscription = sub } label: {
                                                Label(String(localized: "subscription.cancel"), systemImage: "xmark.circle")
                                            }
                                            Button(role: .destructive) { subscriptionToDelete = sub } label: {
                                                Label(String(localized: "common.delete"), systemImage: "trash")
                                            }
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
                                        .contextMenu {
                                            Button { Task { await loadCategoryAndManage(sub) } } label: {
                                                Label(String(localized: "subscription.manage.category"), systemImage: "folder")
                                            }
                                            Button(role: .destructive) { subscriptionToDelete = sub } label: {
                                                Label(String(localized: "common.delete"), systemImage: "trash")
                                            }
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
                                            .contextMenu {
                                                Button(role: .destructive) { subscriptionToDelete = sub } label: {
                                                    Label(String(localized: "common.delete"), systemImage: "trash")
                                                }
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
                .refreshable { let vm = viewModel; await Task { @MainActor in await vm.load() }.value }
                .task {
                    viewModel.configure(apiClient: appState.apiClient)
                    await viewModel.load()
                    // Load categories for "Manage Category" lookup
                    let catResponse: PaginatedResponse<CategoryManagementItem>? = try? await appState.apiClient.request(
                        .categoriesManagement,
                        queryItems: [URLQueryItem(name: "limit", value: "200")]
                    )
                    allCategories = catResponse?.data ?? []
                }
                .sheet(item: $cancellingSubscription, onDismiss: { Task { await viewModel.load() } }) { sub in
                    CancelSubscriptionSheet(subscription: sub, apiClient: appState.apiClient) { }
                        .environmentObject(appState)
                }
                .sheet(item: $managingCategory, onDismiss: { Task { await viewModel.load() } }) { cat in
                    EditCategorySheet(
                        category: cat,
                        apiClient: appState.apiClient,
                        onUpdated: { Task { await viewModel.load() } }
                    )
                    .environmentObject(appState)
                }
                .navigationDestination(item: $selectedSubscription) { sub in
                    SubscriptionDetailView(subscriptionId: sub.id, apiClient: appState.apiClient)
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
                Text(formatDateString(charge.nextChargeDate))
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
                    Text(formatDateString(sub.nextChargeDate))
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

    // MARK: - Manage

    @MainActor
    private func loadCategoryAndManage(_ sub: Subscription) async {
        // Look up category from pre-loaded list
        if let cat = allCategories.first(where: { $0.id == sub.categoryId }) {
            managingCategory = cat
        }
    }
}
