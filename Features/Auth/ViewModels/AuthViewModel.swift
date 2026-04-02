import SwiftUI
internal import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    // Login
    @Published var email = ""
    @Published var password = ""

    // Register
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""

    // Forgot password
    @Published var forgotEmail = ""
    @Published var forgotPasswordSent = false

    // 2FA
    @Published var needs2FA = false
    @Published var twoFactorToken = ""
    @Published var twoFactorCode = ""
    @Published var twoFactorUseRecovery = false

    // Shared
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Validation

    var isLoginDisabled: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty ||
        password.isEmpty ||
        isLoading
    }

    var is2FADisabled: Bool {
        twoFactorCode.isEmpty || isLoading
    }

    var isRegisterDisabled: Bool {
        registerName.trimmingCharacters(in: .whitespaces).isEmpty ||
        registerEmail.trimmingCharacters(in: .whitespaces).isEmpty ||
        !isValidEmail(registerEmail) ||
        registerPassword.isEmpty ||
        PasswordStrength.score(for: registerPassword) < 3 ||
        registerConfirmPassword.isEmpty ||
        registerPassword != registerConfirmPassword ||
        isLoading
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var isForgotDisabled: Bool {
        forgotEmail.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
    }

    // MARK: - Login

    func login() async {
        isLoading = true
        errorMessage = nil

        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }

        struct LoginResponse: Decodable {
            let requiresTwoFactor: Bool
            let user: User?
            let token: String?
            let twoFactorToken: String?
        }

        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            password: password
        )

        do {
            let response: LoginResponse = try await appState.apiClient.request(.login, body: request)
            if response.requiresTwoFactor, let tfToken = response.twoFactorToken {
                twoFactorToken = tfToken
                needs2FA = true
            } else if let user = response.user, let token = response.token {
                appState.tokenManager.setTokens(access: token, refresh: token)
                appState.currentUser = user
                appState.isAuthenticated = true
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "Something went wrong. Please try again.")
        }

        isLoading = false
    }

    // MARK: - 2FA

    func submit2FA() async {
        isLoading = true
        errorMessage = nil

        struct TwoFactorRequest: Encodable {
            let twoFactorToken: String
            let code: String
        }

        struct TwoFactorResponse: Decodable {
            let requiresTwoFactor: Bool
            let user: User
            let token: String?
        }

        let request = TwoFactorRequest(
            twoFactorToken: twoFactorToken,
            code: twoFactorCode
        )

        do {
            let response: TwoFactorResponse = try await appState.apiClient.request(.login2FA, body: request)
            if let token = response.token {
                appState.tokenManager.setTokens(access: token, refresh: token)
            }
            appState.currentUser = response.user
            appState.isAuthenticated = true
            Task { await appState.loadUserCurrency() }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "Something went wrong. Please try again.")
        }

        isLoading = false
    }

    // MARK: - Register

    func register() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        // Client-side validation
        guard registerPassword == registerConfirmPassword else {
            errorMessage = String(localized: "Passwords do not match.")
            isLoading = false
            return
        }

        struct RegisterRequest: Encodable {
            let name: String
            let email: String
            let password: String
        }

        // Reuse the same response shape as login — v2 register auto-authenticates
        struct RegisterResponse: Decodable {
            let requiresTwoFactor: Bool
            let user: User?
            let token: String?
        }

        let request = RegisterRequest(
            name: registerName.trimmingCharacters(in: .whitespaces),
            email: registerEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            password: registerPassword
        )

        do {
            let response: RegisterResponse = try await appState.apiClient.request(.register, body: request)
            guard let token = response.token else {
                errorMessage = String(localized: "auth.register.errorGeneric")
                isLoading = false
                return
            }
            appState.tokenManager.setTokens(access: token, refresh: token)
            await appState.checkAuth()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "Something went wrong. Please try again.")
        }

        isLoading = false
    }

    // MARK: - Forgot Password

    func requestPasswordReset() async {
        isLoading = true
        errorMessage = nil
        forgotPasswordSent = false

        struct ForgotRequest: Encodable {
            let email: String
        }

        let request = ForgotRequest(
            email: forgotEmail.trimmingCharacters(in: .whitespaces).lowercased()
        )

        do {
            // This always succeeds (server doesn't reveal if email exists)
            let _: ForgotPasswordResponse = try await appState.apiClient.request(.forgotPassword, body: request)
            forgotPasswordSent = true
        } catch {
            // Even on error, show success to prevent email enumeration
            forgotPasswordSent = true
        }

        isLoading = false
    }

    // MARK: - Reset

    func resetState() {
        email = ""
        password = ""
        registerName = ""
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        forgotEmail = ""
        forgotPasswordSent = false
        errorMessage = nil
        successMessage = nil
        needs2FA = false
        twoFactorToken = ""
        twoFactorCode = ""
        twoFactorUseRecovery = false
        isLoading = false
    }
}

// MARK: - Response types

struct ForgotPasswordResponse: Decodable {
    let message: String
}
