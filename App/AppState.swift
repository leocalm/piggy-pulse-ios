import SwiftUI
import UserNotifications
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
    @Published var onboardingCompleted = true
    @Published var currencyCode: String = "EUR"
    

    var currencySymbol: String {
        Locale.availableIdentifiers
            .lazy
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == currencyCode }?
            .currencySymbol ?? currencyCode
    }
    let themeManager = ThemeManager.shared

    /// Legacy proxy — reads from ThemeManager. Use themeManager.colorScheme directly in new code.
    var appColorScheme: ColorScheme? { themeManager.colorScheme }
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
            let code: String
        }

        do {
            let profile: ProfileResponse = try await apiClient.request(.profile)
            if let currencyId = profile.defaultCurrencyId {
                let currencies: [CurrencyItem] = try await apiClient.request(.currencies)
                if let match = currencies.first(where: { $0.id == currencyId }) {
                    currencyCode = match.code
                }
            }
        } catch {
            // Keep default EUR
        }
    }

    func loadTheme() {
        // Now handled by ThemeManager — this method is kept for backward compat
    }

    func applyTheme(_ value: String) {
        switch value {
        case "light": themeManager.appearanceMode = .light
        case "dark":  themeManager.appearanceMode = .dark
        default:      themeManager.appearanceMode = .system
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
        WatchSessionManager.shared.activate()
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
            await checkOnboardingStatus()
            await scheduleNotifications()
            // Sync auth token to Apple Watch and widgets
            if let token = tokenManager.getAccessToken() {
                WatchSessionManager.shared.sendAuthToken(token, currencyCode: currencyCode)
                WidgetTokenStore.syncFromApp(
                    token: token,
                    currencyCode: currencyCode,
                    periodId: selectedPeriod?.id.uuidString
                )
            }
        } catch {
            tokenManager.clearTokens()
            isAuthenticated = false
        }

        isLoading = false
        loadTheme()
    }
    func checkOnboardingStatus() async {
        struct OnboardingStatus: Codable {
            let status: String
        }
        do {
            let response: OnboardingStatus = try await apiClient.request(.onboardingStatus)
            onboardingCompleted = response.status == "completed"
        } catch {
            // If endpoint fails, assume completed (existing user)
            onboardingCompleted = true
        }
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

    func deleteAccount(confirmation: String) async throws {
        struct DeleteAccountRequest: Encodable {
            let confirmation: String
        }
        try await apiClient.request(.deleteUserAccount, body: DeleteAccountRequest(confirmation: confirmation))
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        tokenManager.clearTokens()
        WidgetTokenStore.clearAndReload()
        currentUser = nil
        selectedPeriod = nil
        isAuthenticated = false
        isBiometricLocked = false
        biometricAuthFailed = false
    }

    func logout() async {
        if let refreshToken = tokenManager.getRefreshToken() {
            struct RevokeRequest: Encodable {
                let refreshToken: String
            }
            try? await apiClient.request(.revokeToken, body: RevokeRequest(refreshToken: refreshToken))
        }

        tokenManager.clearTokens()
        WatchSessionManager.shared.clearAuth()
        WidgetTokenStore.clearAndReload()
        currentUser = nil
        selectedPeriod = nil
        isAuthenticated = false
        isBiometricLocked = false
        biometricAuthFailed = false
    }
}
