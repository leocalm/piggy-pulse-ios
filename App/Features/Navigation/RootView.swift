import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ppBackground(colorScheme))
            } else if appState.isAuthenticated {
                if appState.currentUser?.onboardingStatus == "completed" {
                    MainTabView()
                } else {
                    OnboardingView(apiClient: appState.apiClient)
                }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}
