import Foundation
import WatchConnectivity
import WidgetKit

/// Receives auth tokens and currency settings from the paired iPhone app.
final class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    @Published var isAuthenticated: Bool = false

    private override init() {
        super.init()
        isAuthenticated = WatchTokenStore.read(.accessToken) != nil
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Actively request token from iPhone
    func requestTokenFromPhone() {
        guard WCSession.default.activationState == .activated else { return }

        // First check if there's already a received application context
        let context = WCSession.default.receivedApplicationContext
        if let token = context["accessToken"] as? String, !token.isEmpty {
            WatchTokenStore.save(token, for: .accessToken)
            if let currency = context["currencyCode"] as? String, !currency.isEmpty {
                WatchTokenStore.save(currency, for: .currencyCode)
            }
            DispatchQueue.main.async { self.isAuthenticated = true }
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        // If no context yet, send a message to iPhone asking for the token
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["request": "authToken"], replyHandler: { reply in
            self.processReceivedData(reply)
        }, errorHandler: nil)
    }

    /// Process token data from any delivery method
    private func processReceivedData(_ data: [String: Any]) {
        if let token = data["accessToken"] as? String {
            if token.isEmpty {
                WatchTokenStore.clearAll()
                DispatchQueue.main.async { self.isAuthenticated = false }
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                WatchTokenStore.save(token, for: .accessToken)
                if let currency = data["currencyCode"] as? String, !currency.isEmpty {
                    WatchTokenStore.save(currency, for: .currencyCode)
                }
                DispatchQueue.main.async { self.isAuthenticated = true }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        // Try to get token immediately on activation
        requestTokenFromPhone()
    }

    /// Receives real-time messages from the iPhone app.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processReceivedData(message)
    }

    /// Receives user info transfers from the iPhone app.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processReceivedData(userInfo)
    }

    /// Receives application context updates (latest state from iPhone).
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processReceivedData(applicationContext)
    }
}
