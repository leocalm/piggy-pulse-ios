import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "tab.dashboard"), systemImage: "house.fill", value: 0) {
                DashboardView(apiClient: appState.apiClient)
            }
            Tab(String(localized: "tab.transactions"), systemImage: "arrow.left.arrow.right", value: 1) {
                TransactionsView(apiClient: appState.apiClient)
            }
            Tab(String(localized: "tab.accounts"), systemImage: "creditcard.fill", value: 2) {
                AccountsView().environmentObject(appState)
            }
            Tab(String(localized: "tab.more"), systemImage: "ellipsis.circle", value: 3) {
                moreTab
            }
        }
        .tabViewBottomAccessory {
            PeriodSelectorBar()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(appState.themeManager.primary)
        .background(Color.ppBackground)
    }

    // MARK: - More Tab

    private var moreTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.xl) {
                    // Planning section
                    moreSection(String(localized: "more.planning")) {
                        moreLink("more.periods", icon: "calendar") {
                            PeriodsView(apiClient: appState.apiClient).environmentObject(appState)
                        }
                        moreLink("more.categories", icon: "tag") {
                            CategoriesView().environmentObject(appState)
                        }
                        moreLink("more.targets", icon: "chart.pie") {
                            BudgetPlanView(apiClient: appState.apiClient).environmentObject(appState)
                        }
                    }

                    // Tracking section
                    moreSection(String(localized: "more.tracking")) {
                        moreLink("more.subscriptions", icon: "repeat") {
                            SubscriptionsView(apiClient: appState.apiClient).environmentObject(appState)
                        }
                        moreLink("more.vendors", icon: "storefront") {
                            VendorsView().environmentObject(appState)
                        }
                    }

                    // App section
                    moreSection(String(localized: "more.app")) {
                        moreLink("more.settings", icon: "gearshape") {
                            SettingsView().environmentObject(appState)
                        }
                    }

                    // Logout
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await appState.logout() }
                    } label: {
                        HStack {
                            Label(String(localized: "more.logout"), systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.ppBody)
                                .foregroundColor(.sharedDestructive)
                            Spacer()
                        }
                        .padding(.horizontal, PPSpacing.lg)
                        .padding(.vertical, PPSpacing.lg)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .navigationTitle(String(localized: "tab.more"))
        }
    }

    // MARK: - Helpers

    private func moreSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text(title.uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)
                .padding(.horizontal, PPSpacing.lg)

            VStack(spacing: 1) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )
        }
    }

    private func moreLink<Destination: View>(
        _ titleKey: LocalizedStringResource,
        icon: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Label(String(localized: titleKey), systemImage: icon)
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.ppTextTertiary)
            }
            .padding(.horizontal, PPSpacing.lg)
            .padding(.vertical, PPSpacing.lg)
            .background(Color.ppCard)
        }
    }
}
