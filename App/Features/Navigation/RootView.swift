import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                // Launch / splash state
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ppBackground)
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
