import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
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

            Text("More")
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .tag(3)
        }
        .tint(.ppPrimary)
    }
}
