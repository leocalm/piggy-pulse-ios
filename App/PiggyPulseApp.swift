import SwiftUI

@main
struct PiggyPulseApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .task {
                    await appState.checkAuth()
                }
        }
    }
}
