import CryptoKit
import Foundation
import Argon2Kit
import LocalAuthentication

struct DekWrapParams: Codable {
    let salt: String
    let m: UInt32
    let t: UInt32
    let p: UInt32
    let wrapNonce: String
}

enum KeyManagerError: LocalizedError {
    case kekDerivationFailed
    case dekUnwrapFailed
    case keychainError(OSStatus)
    case noDEKStored
    case biometricRequired

    var errorDescription: String? {
        switch self {
        case .kekDerivationFailed: return "Failed to derive encryption key from password"
        case .dekUnwrapFailed: return "Failed to unwrap data encryption key — wrong password?"
        case .keychainError(let status):
            return String(localized: "Unable to securely store data on this device. Please try again. (OSStatus \(status))")
        case .noDEKStored: return "No encryption key stored on device"
        case .biometricRequired: return "Biometric authentication required to access encryption key"
        }
    }
}

enum KeyManager {

    private static let keychainService = "com.piggypulse.encryption"
    private static let keychainDEKAccount = "dek"

    /// Whether the device currently has biometric authentication (Face ID / Touch ID) available.
    /// Returns false on devices without biometric hardware, or when biometrics are not enrolled.
    static var biometricsAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - KEK Derivation (Argon2id)

    static func deriveKEK(password: String, params: DekWrapParams) throws -> SymmetricKey {
        guard let saltData = Data(base64Encoded: params.salt) else {
            throw KeyManagerError.kekDerivationFailed
        }

        let digest = try Argon2.hash(
            password: Data(password.utf8),
            salt: saltData,
            iterations: params.t,
            memory: params.m,
            threads: params.p,
            length: 32,
            type: .id
        )

        return SymmetricKey(data: digest.rawData)
    }

    // MARK: - DEK Wrapping / Unwrapping

    static func wrapDEK(_ dek: SymmetricKey, with kek: SymmetricKey, nonce nonceData: Data) throws -> Data {
        let dekData = dek.withUnsafeBytes { Data($0) }
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.seal(dekData, using: kek, nonce: nonce)
        return sealedBox.ciphertext + sealedBox.tag
    }

    static func unwrapDEK(wrappedDek: Data, with kek: SymmetricKey, nonce nonceData: Data) throws -> SymmetricKey {
        guard wrappedDek.count >= 16 else { throw KeyManagerError.dekUnwrapFailed }
        let ciphertext = wrappedDek.dropLast(16)
        let tag = wrappedDek.suffix(16)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let dekData = try AES.GCM.open(sealedBox, using: kek)
        return SymmetricKey(data: dekData)
    }

    // MARK: - Generate wrap params + wrapped DEK for registration / password change

    static func generateWrappedDEK(password: String) throws -> (dek: SymmetricKey, wrappedDek: String, params: DekWrapParams) {
        let salt = CryptoManager.generateRandomBytes(16)
        let wrapNonce = CryptoManager.generateRandomBytes(12)
        let dek = CryptoManager.generateDEK()

        let params = DekWrapParams(
            salt: salt.base64EncodedString(),
            m: 65536,
            t: 3,
            p: 4,
            wrapNonce: wrapNonce.base64EncodedString()
        )

        let kek = try deriveKEK(password: password, params: params)
        let wrapped = try wrapDEK(dek, with: kek, nonce: wrapNonce)

        return (dek, wrapped.base64EncodedString(), params)
    }

    // MARK: - Unwrap from server response

    static func unwrapFromServer(password: String, wrappedDekBase64: String, params: DekWrapParams) throws -> SymmetricKey {
        guard let wrappedData = Data(base64Encoded: wrappedDekBase64) else {
            throw KeyManagerError.dekUnwrapFailed
        }
        guard let nonceData = Data(base64Encoded: params.wrapNonce) else {
            throw KeyManagerError.dekUnwrapFailed
        }

        let kek = try deriveKEK(password: password, params: params)
        return try unwrapDEK(wrappedDek: wrappedData, with: kek, nonce: nonceData)
    }

    // MARK: - Keychain DEK Storage (biometric-protected)

    static func storeDEK(_ dek: SymmetricKey) throws {
        let dekData = dek.withUnsafeBytes { Data($0) }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDEKAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDEKAccount,
            kSecValueData as String: dekData,
        ]

        if biometricsAvailable,
           let accessControl = SecAccessControlCreateWithFlags(
               nil,
               kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
               .biometryCurrentSet,
               nil
           ) {
            query[kSecAttrAccessControl as String] = accessControl
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyManagerError.keychainError(status)
        }
    }

    static func loadDEK() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDEKAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: "Unlock PiggyPulse",
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeyManagerError.noDEKStored }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            throw KeyManagerError.noDEKStored
        case errSecInteractionNotAllowed:
            // Device is locked, biometrics unavailable, or running in a restricted
            // environment (e.g. App Review sandbox). Treat as no DEK — the caller
            // will fall through to the password unlock flow.
            throw KeyManagerError.noDEKStored
        case errSecUserCanceled, errSecAuthFailed:
            throw KeyManagerError.biometricRequired
        default:
            throw KeyManagerError.keychainError(status)
        }
    }

    static func deleteDEK() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDEKAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func hasDEKStored() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDEKAccount,
            kSecReturnData as String: false,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }
}
