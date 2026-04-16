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
                    if appState.onboardingCompleted {
                        AdaptiveNavigationView()
                    } else {
                        OnboardingView(apiClient: appState.apiClient, decryptionService: appState.decryptionService)
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
