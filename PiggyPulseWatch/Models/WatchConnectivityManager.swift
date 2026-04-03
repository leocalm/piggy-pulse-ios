import Foundation
import WatchConnectivity

/// Receives auth tokens and currency settings from the paired iPhone app.
final class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    @Published var isAuthenticated: Bool = false

    private override init() {
        super.init()
        isAuthenticated = WatchKeychainHelper.read(.accessToken) != nil
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No action needed on activation
    }

    /// Receives user info transfers from the iPhone app.
    /// Expected keys: "accessToken" (String), "currencyCode" (String, optional)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let token = userInfo["accessToken"] as? String {
            WatchKeychainHelper.save(token, for: .accessToken)
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }

        if let currency = userInfo["currencyCode"] as? String {
            WatchKeychainHelper.save(currency, for: .currencyCode)
        }

        // Handle logout signal
        if let logout = userInfo["logout"] as? Bool, logout {
            WatchKeychainHelper.clearAll()
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        }
    }

    /// Receives application context updates (latest state from iPhone).
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let token = applicationContext["accessToken"] as? String {
            WatchKeychainHelper.save(token, for: .accessToken)
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }

        if let currency = applicationContext["currencyCode"] as? String {
            WatchKeychainHelper.save(currency, for: .currencyCode)
        }
    }
}
