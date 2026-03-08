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
    @Published var currencyCode: String = "EUR"
    @Published var appColorScheme: ColorScheme? = nil

    func loadUserCurrency() async {
        // Try to get from settings profile
        struct SettingsResponse: Codable {
            let defaultCurrencyId: UUID?
        }
        struct CurrencyItem: Codable, Identifiable {
            let id: UUID
            let currency: String
        }
        
        do {
            let profile: ProfileResponse = try await apiClient.request(.profile)
            if let currencyId = profile.defaultCurrencyId {
                let currencies: [CurrencyItem] = try await apiClient.request(.currencies)
                if let match = currencies.first(where: { $0.id == currencyId }) {
                    currencyCode = match.currency
                }
            }
        } catch {
            // Keep default EUR
        }
    }

    func loadTheme() {
        let stored = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        appColorScheme = colorScheme(from: stored)
    }

    func applyTheme(_ value: String) {
        UserDefaults.standard.set(value, forKey: "appTheme")
        appColorScheme = colorScheme(from: value)
    }

    private func colorScheme(from value: String) -> ColorScheme? {
        switch value {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // "system" / "auto"
        }
    }

    init() {
        loadTheme()
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
            await loadUserCurrency()
        } catch {
            tokenManager.clearTokens()
            isAuthenticated = false
        }

        isLoading = false
        loadTheme()
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
