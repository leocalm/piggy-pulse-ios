import SwiftUI
internal import Combine

@MainActor
final class AppState: ObservableObject {
    let tokenManager: TokenManager
    let apiClient: APIClient
    let periodRepository: PeriodRepository
    let overlayRepository: OverlayRepository
    let notificationScheduler: NotificationScheduler

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedPeriod: BudgetPeriod?
    @Published var isLoading = true
    @Published var currencyCode: String = "EUR"
    

    var currencySymbol: String {
        Locale.availableIdentifiers
            .lazy
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == currencyCode }?
            .currencySymbol ?? currencyCode
    }
    @Published var appColorScheme: ColorScheme? = nil
    @Published var isBiometricLocked = false
    @Published var biometricAuthFailed = false
    var lastBackgroundedAt: Date?

    var biometricEnabled: Bool {
        get { BiometricPreferences().isEnabled }
        set {
            var prefs = BiometricPreferences()
            prefs.isEnabled = newValue
        }
    }

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

    /// Pure logic: determines whether the app should lock.
    /// Static for unit-testability without an AppState instance.
    nonisolated static func shouldLock(
        biometricEnabled: Bool,
        lastBackgroundedAt: Date?,
        gracePeriod: TimeInterval = 10
    ) -> Bool {
        guard biometricEnabled, let backgroundedAt = lastBackgroundedAt else { return false }
        return Date().timeIntervalSince(backgroundedAt) > gracePeriod
    }

    /// Called when the app comes to foreground. Locks if grace period elapsed.
    func lockIfNeeded() {
        guard !isBiometricLocked else { return }
        if Self.shouldLock(biometricEnabled: biometricEnabled, lastBackgroundedAt: lastBackgroundedAt) {
            isBiometricLocked = true
        }
    }

    /// Attempts biometric authentication. Sets `isBiometricLocked = false` on success,
    /// sets `biometricAuthFailed = true` on failure so the UI can show "Try Again".
    func unlockWithBiometrics() async {
        biometricAuthFailed = false
        do {
            try await BiometricHelper.authenticate()
            lastBackgroundedAt = nil
            isBiometricLocked = false
        } catch {
            biometricAuthFailed = true
        }
    }

    init() {
        let tm = TokenManager()
        self.tokenManager = tm
        self.apiClient = APIClient(tokenManager: tm)
        self.periodRepository = PeriodRepository(apiClient: apiClient)
        self.overlayRepository = OverlayRepository(apiClient: apiClient)
        self.notificationScheduler = NotificationScheduler()
        self.isAuthenticated = tm.isAuthenticated
        loadTheme()
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
            if biometricEnabled {
                isBiometricLocked = true
            }
            await loadUserCurrency()
            await scheduleNotifications()
        } catch {
            tokenManager.clearTokens()
            isAuthenticated = false
        }

        isLoading = false
        loadTheme()
    }
    func scheduleNotifications() async {
        do {
            async let periodsTask = periodRepository.fetchPeriods()
            async let overlaysTask = overlayRepository.fetchOverlays()
            let (periods, overlays) = try await (periodsTask, overlaysTask)
            try await notificationScheduler.scheduleAll(periods: periods, overlays: overlays)
        } catch {
            // Notifications are best-effort; do not surface errors to user
        }
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
        isBiometricLocked = false
        biometricAuthFailed = false
    }
}
