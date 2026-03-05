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
                Text("Dashboard")
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .tag(0)

                Text("Transactions")
                    .tabItem {
                        Label("Transactions", systemImage: "arrow.left.arrow.right")
                    }
                    .tag(1)

                Text("Periods")
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
            List {
                Section {
                    Label("Accounts", systemImage: "building.columns")
                    Label("Categories", systemImage: "tag")
                    Label("Vendors", systemImage: "storefront")
                    Label("Overlays", systemImage: "square.stack")
                    Label("Budget Plan", systemImage: "chart.pie")
                } header: {
                    Text("Structure")
                }

                Section {
                    Label("Settings", systemImage: "gearshape")
                } header: {
                    Text("App")
                }

                Section {
                    Button(role: .destructive) {
                        Task { await appState.logout() }
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.ppDestructive)
                    }
                }
            }
            .navigationTitle("More")
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground)
        }
    }
}
