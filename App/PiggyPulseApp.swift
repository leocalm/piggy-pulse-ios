import SwiftUI
import BackgroundTasks

@main
struct PiggyPulseApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    private static let bgTaskIdentifier = "com.piggypulse.notifications.refresh"

    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Self.handleBackgroundRefresh(task: refreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.appColorScheme)
                .task {
                    await appState.checkAuth()
                    scheduleNextBackgroundRefresh()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        appState.lastBackgroundedAt = Date()
                    case .active:
                        appState.lockIfNeeded()
                    default:
                        break
                    }
                }
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour minimum
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // A fresh AppState is created intentionally — background tasks run in a separate
        // execution context and cannot access the live appState from the main scene.
        // This instance reads auth tokens from Keychain independently.
        let appState = AppState()
        let taskHandle = Task {
            await appState.scheduleNotifications()
            // Re-submit so the background refresh chain continues
            let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
            try? BGTaskScheduler.shared.submit(request)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            taskHandle.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
