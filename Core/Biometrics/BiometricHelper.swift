// Core/Biometrics/BiometricHelper.swift
import LocalAuthentication

/// Persists the user's biometric lock preference.
struct BiometricPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: "biometricEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "biometricEnabled") }
    }
}

/// Thin wrapper around LAContext for biometric authentication.
enum BiometricHelper {
    enum BiometricError: Error {
        case notAvailable
        case authFailed
    }

    /// Returns the available biometry type on this device.
    static func availableBiometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .none
        }
        return context.biometryType
    }

    /// Authenticates using biometrics with passcode fallback.
    /// Throws `BiometricError.notAvailable` or `BiometricError.authFailed`.
    static func authenticate(reason: String = "Unlock PiggyPulse") async throws {
        let context = LAContext()
        var canEvalError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &canEvalError) else {
            throw BiometricError.notAvailable
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if !success { throw BiometricError.authFailed }
        } catch let error as BiometricError {
            throw error
        } catch {
            throw BiometricError.authFailed
        }
    }
}
