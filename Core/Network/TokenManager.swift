import Foundation
import UIKit
internal import Combine


@MainActor
final class TokenManager: ObservableObject {
    @Published var isAuthenticated = false

    private var accessToken: String? {
        didSet { isAuthenticated = accessToken != nil }
    }

    /// Persists across logouts — unique to this app install
    var deviceId: String {
        if let existing = KeychainHelper.read(.deviceId) {
            return existing
        }
        let newId = UUID().uuidString
        KeychainHelper.save(newId, for: .deviceId)
        return newId
    }

    var deviceName: String {
        UIDevice.current.name
    }

    init() {
        self.accessToken = KeychainHelper.read(.accessToken)
    }

    func setTokens(access: String, refresh: String) {
        accessToken = access
        KeychainHelper.save(access, for: .accessToken)
        KeychainHelper.save(refresh, for: .refreshToken)
    }

    func updateAccessToken(_ token: String) {
        accessToken = token
        KeychainHelper.save(token, for: .accessToken)
    }

    func getAccessToken() -> String? {
        accessToken
    }

    func getRefreshToken() -> String? {
        KeychainHelper.read(.refreshToken)
    }

    func clearTokens() {
        accessToken = nil
        KeychainHelper.clearAll()
    }
}
