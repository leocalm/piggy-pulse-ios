import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Group {
                if appState.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.ppBackground)
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

            if appState.isBiometricLocked {
                BiometricLockView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isBiometricLocked)
    }
}
