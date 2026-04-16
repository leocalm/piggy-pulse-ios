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
    let decryptionService: DecryptionService
    let dataStore: EncryptedDataStore

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedPeriod: BudgetPeriod?
    @Published var isLoading = true
    @Published var onboardingCompleted = true
    @Published var currencyCode: String = "EUR"
    @Published var isEncryptionUnlocked = false

    var currencySymbol: String {
        Locale.availableIdentifiers
            .lazy
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == currencyCode }?
            .currencySymbol ?? currencyCode
    }
    let themeManager = ThemeManager.shared

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
        // Handled by ThemeManager
    }

    func applyTheme(_ value: String) {
        switch value {
        case "light": themeManager.appearanceMode = .light
        case "dark":  themeManager.appearanceMode = .dark
        default:      themeManager.appearanceMode = .system
        }
    }

    nonisolated static func shouldLock(
        biometricEnabled: Bool,
        lastBackgroundedAt: Date?,
        gracePeriod: TimeInterval = 10
    ) -> Bool {
        guard biometricEnabled, let backgroundedAt = lastBackgroundedAt else { return false }
        return Date().timeIntervalSince(backgroundedAt) > gracePeriod
    }

    func lockIfNeeded() {
        guard !isBiometricLocked else { return }
        if Self.shouldLock(biometricEnabled: biometricEnabled, lastBackgroundedAt: lastBackgroundedAt) {
            isBiometricLocked = true
        }
    }

    func unlockWithBiometrics() async {
        biometricAuthFailed = false
        do {
            try await BiometricHelper.authenticate()
            lastBackgroundedAt = nil
            isBiometricLocked = false

            if !isEncryptionUnlocked {
                try await unlockEncryptionFromKeychain()
            }
        } catch {
            biometricAuthFailed = true
        }
    }

    // MARK: - Encryption unlock from Keychain (biometric-protected)

    func unlockEncryptionFromKeychain() async throws {
        let dek = try KeyManager.loadDEK()
        decryptionService.setDEK(dek)

        let dekBase64 = try decryptionService.dekBase64()
        try await apiClient.request(.unlock, body: UnlockRequest(dek: dekBase64))
        isEncryptionUnlocked = true
    }

    // MARK: - Init

    init() {
        let tm = TokenManager()
        let client = APIClient(tokenManager: tm)
        let ds = DecryptionService()

        self.tokenManager = tm
        self.apiClient = client
        self.periodRepository = PeriodRepository(apiClient: client)
        self.overlayRepository = OverlayRepository(apiClient: client)
        self.notificationScheduler = NotificationScheduler()
        self.decryptionService = ds
        self.dataStore = EncryptedDataStore(apiClient: client, decryptionService: ds)
        self.isAuthenticated = tm.isAuthenticated
        loadTheme()
        WatchSessionManager.shared.activate()
    }

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

            if KeyManager.hasDEKStored() {
                do {
                    try await unlockEncryptionFromKeychain()
                } catch KeyManagerError.biometricRequired {
                    isBiometricLocked = true
                } catch {
                    // DEK stored but can't unlock — will need password re-entry
                }
            }

            if biometricEnabled && !isEncryptionUnlocked {
                isBiometricLocked = true
            }

            await loadUserCurrency()
            await checkOnboardingStatus()
            await scheduleNotifications()

            if let token = tokenManager.getAccessToken() {
                WatchSessionManager.shared.sendAuthToken(token, currencyCode: currencyCode)
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
            onboardingCompleted = true
        }
    }

    func scheduleNotifications() async {
        do {
            let periods = try await periodRepository.fetchPeriods()
            try await notificationScheduler.scheduleAll(periods: periods, overlays: [])
        } catch {
            // Notifications are best-effort
        }
    }

    func deleteAccount(confirmation: String) async throws {
        struct DeleteAccountRequest: Encodable {
            let confirmation: String
        }
        try await apiClient.request(.deleteUserAccount, body: DeleteAccountRequest(confirmation: confirmation))
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearSession()
    }

    func logout() async {
        if let refreshToken = tokenManager.getRefreshToken() {
            struct RevokeRequest: Encodable {
                let refreshToken: String
            }
            try? await apiClient.request(.revokeToken, body: RevokeRequest(refreshToken: refreshToken))
        }
        clearSession()
    }

    private func clearSession() {
        tokenManager.clearTokens()
        KeyManager.deleteDEK()
        decryptionService.clearDEK()
        dataStore.clear()
        WatchSessionManager.shared.clearAuth()
        currentUser = nil
        selectedPeriod = nil
        isAuthenticated = false
        isEncryptionUnlocked = false
        isBiometricLocked = false
        biometricAuthFailed = false
    }
}
