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
        registerPassword.isEmpty ||
        registerConfirmPassword.isEmpty ||
        isLoading
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
            let deviceName: String
            let deviceId: String
        }

        struct LoginResponse: Decodable {
            let user: User
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let tokenType: String
        }

        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            password: password,
            deviceName: appState.tokenManager.deviceName,
            deviceId: appState.tokenManager.deviceId
        )

        do {
            let response: LoginResponse = try await appState.apiClient.request(.login, body: request)
            appState.tokenManager.setTokens(access: response.accessToken, refresh: response.refreshToken)
            appState.currentUser = response.user
            appState.isAuthenticated = true
        } catch APIError.twoFactorRequired(let token) {
            twoFactorToken = token
            needs2FA = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
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

        struct LoginResponse: Decodable {
            let user: User
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let tokenType: String
        }

        let request = TwoFactorRequest(
            twoFactorToken: twoFactorToken,
            code: twoFactorCode
        )

        do {
            let response: LoginResponse = try await appState.apiClient.request(.login2FA, body: request)
            appState.tokenManager.setTokens(access: response.accessToken, refresh: response.refreshToken)
            appState.currentUser = response.user
            appState.isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
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
            errorMessage = "Passwords do not match."
            isLoading = false
            return
        }

        struct RegisterRequest: Encodable {
            let name: String
            let email: String
            let password: String
        }

        let request = RegisterRequest(
            name: registerName.trimmingCharacters(in: .whitespaces),
            email: registerEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            password: registerPassword
        )

        do {
            // Register creates the account — we need to login afterward for Bearer tokens
            let _: User = try await appState.apiClient.request(.register, body: request)
            
            // Auto-login after successful registration
            email = request.email
            password = registerPassword
            await login()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
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
        isLoading = false
    }
}

// MARK: - Response types

struct ForgotPasswordResponse: Decodable {
    let message: String
}
