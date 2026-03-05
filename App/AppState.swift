import SwiftUI
internal import Combine

@MainActor
final class AppState: ObservableObject {
    let tokenManager: TokenManager
    let apiClient: APIClient

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedPeriod: BudgetPeriod?
    @Published var isLoading = true

    init() {
        let tm = TokenManager()
        self.tokenManager = tm
        self.apiClient = APIClient(tokenManager: tm)
        self.isAuthenticated = tm.isAuthenticated
    }

    /// Called on app launch to validate existing tokens
    func checkAuth() async {
        let token = tokenManager.getAccessToken()
        
        guard token != nil else {
            isLoading = false
            return
        }

        do {
            let user: User = try await apiClient.request(.me)
            currentUser = user
            isAuthenticated = true
        } catch {
            tokenManager.clearTokens()
            isAuthenticated = false
        }

        isLoading = false
    }
    func logout() async {
        if let refreshToken = tokenManager.getRefreshToken() {
            struct RevokeRequest: Encodable {
                let refreshToken: String
            }
            try? await apiClient.request(.revokeToken, body: RevokeRequest(refreshToken: refreshToken))
        }

        tokenManager.clearTokens()
        currentUser = nil
        selectedPeriod = nil
        isAuthenticated = false
    }
}
