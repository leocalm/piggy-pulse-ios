import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var sizeClass

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color.ppBackground).withAlphaComponent(0.8)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2", value: 0) {
                DashboardView(apiClient: appState.apiClient)
            }
            Tab("Transactions", systemImage: "arrow.left.arrow.right", value: 1) {
                TransactionsView(apiClient: appState.apiClient)
            }
            Tab("Periods", systemImage: "calendar", value: 2) {
                PeriodsView(apiClient: appState.apiClient)
            }
            Tab("More", systemImage: "ellipsis.circle", value: 3) {
                moreTab
            }
        }
        .tabViewBottomAccessory {
            PeriodSelectorBar()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.ppPrimary)
        .background(Color.ppBackground)
    }

    // MARK: - More Tab

    private var moreTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.xl) {
                    // Structure section
                    VStack(alignment: .leading, spacing: PPSpacing.md) {
                        Text("STRUCTURE")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                            .padding(.horizontal, PPSpacing.lg)

                        VStack(spacing: 1) {
                            moreLink("Accounts", icon: "building.columns") {
                                AccountsView().environmentObject(appState)
                            }
                            moreLink("Categories", icon: "tag") {
                                CategoriesView().environmentObject(appState)
                            }
                            moreLink("Vendors", icon: "storefront") {
                                VendorsView().environmentObject(appState)
                            }
                            moreLink("Category Targets", icon: "chart.pie") {
                                BudgetPlanView(apiClient: appState.apiClient).environmentObject(appState)
                            }
                            moreLink("Overlays", icon: "square.stack") {
                                OverlaysView().environmentObject(appState)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }

                    // App section
                    VStack(alignment: .leading, spacing: PPSpacing.md) {
                        Text("APP")
                            .font(.ppOverline)
                            .foregroundColor(.ppTextSecondary)
                            .tracking(1)
                            .padding(.horizontal, PPSpacing.lg)

                        moreLink("Settings", icon: "gearshape") {
                            SettingsView().environmentObject(appState)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }

                    // Logout
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await appState.logout() }
                    } label: {
                        HStack {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.ppBody)
                                .foregroundColor(.ppDestructive)
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
            .navigationTitle("More")
        }
    }

    // MARK: - More Tab Link Helper

    private func moreLink<Destination: View>(
        _ title: LocalizedStringKey,
        icon: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Label(title, systemImage: icon)
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
