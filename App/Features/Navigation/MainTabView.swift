import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Period selector bar
            PeriodSelectorBar()
                .padding(.horizontal, PPSpacing.lg)
                .padding(.top, PPSpacing.sm)
                .padding(.bottom, PPSpacing.sm)

            TabView(selection: $selectedTab) {
                DashboardView(apiClient: appState.apiClient)
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .tag(0)

                TransactionsView(apiClient: appState.apiClient)
                    .tabItem {
                        Label("Transactions", systemImage: "arrow.left.arrow.right")
                    }
                    .tag(1)

                PeriodsView(apiClient: appState.apiClient)
                    .tabItem {
                        Label("Periods", systemImage: "calendar")
                    }
                    .tag(2)

                moreTab
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .tag(3)
            }
            .tint(.ppPrimary)
        }
        .background(Color.ppBackground)
    }

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
                        .cornerRadius(PPRadius.lg)
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
                        .cornerRadius(PPRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.lg)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }

                    // Logout
                    Button {
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
                        .cornerRadius(PPRadius.lg)
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
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - More Tab Link Helper

    private func moreLink<Destination: View>(
        _ title: String,
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
