import Foundation
import WatchConnectivity

/// Manages WatchConnectivity from the iPhone side.
/// Sends auth tokens and currency to the Watch companion app.
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private let lock = NSLock()

    /// Pending context to send once the session activates.
    private var pendingContext: [String: Any]?

    /// Latest known token/currency for responding to Watch requests.
    private var latestToken: String?
    private var latestCurrency: String?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Send auth token and currency to the Watch.
    /// If the session isn't activated yet, the data is queued and sent on activation.
    func sendAuthToken(_ token: String, currencyCode: String) {
        lock.lock()
        latestToken = token
        latestCurrency = currencyCode
        lock.unlock()

        let context: [String: Any] = [
            "accessToken": token,
            "currencyCode": currencyCode
        ]

        if WCSession.default.activationState == .activated {
            sendContext(context)
        } else {
            lock.lock()
            pendingContext = context
            lock.unlock()
        }
    }

    /// Clear auth on the Watch (logout)
    func clearAuth() {
        lock.lock()
        latestToken = nil
        latestCurrency = nil
        lock.unlock()

        let context: [String: Any] = ["accessToken": "", "currencyCode": ""]
        if WCSession.default.activationState == .activated {
            sendContext(context)
        } else {
            lock.lock()
            pendingContext = context
            lock.unlock()
        }
    }

    private func sendContext(_ context: [String: Any]) {
        try? WCSession.default.updateApplicationContext(context)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(context, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard error == nil, activationState == .activated else { return }

        lock.lock()
        let pending = pendingContext
        pendingContext = nil
        let token = latestToken
        let currency = latestCurrency
        lock.unlock()

        if let context = pending {
            sendContext(context)
        } else if let token = token {
            sendContext([
                "accessToken": token,
                "currencyCode": currency ?? "EUR"
            ])
        }
    }

    /// When Watch becomes reachable, resend the token immediately
    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }

        lock.lock()
        let token = latestToken
        let currency = latestCurrency
        lock.unlock()

        if let token = token {
            sendContext([
                "accessToken": token,
                "currencyCode": currency ?? "EUR"
            ])
        }
    }

    /// Respond to Watch requesting the auth token
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        lock.lock()
        let token = latestToken
        let currency = latestCurrency
        lock.unlock()

        if message["request"] as? String == "authToken", let token = token {
            replyHandler([
                "accessToken": token,
                "currencyCode": currency ?? "EUR"
            ])
        } else {
            replyHandler([:])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
