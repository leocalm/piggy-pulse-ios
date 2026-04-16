import CryptoKit
import Foundation

enum CryptoError: LocalizedError {
    case invalidEnvelope
    case decryptionFailed
    case invalidBase64
    case noDEK

    var errorDescription: String? {
        switch self {
        case .invalidEnvelope: return "Invalid encrypted envelope format"
        case .decryptionFailed: return "Decryption failed — wrong key or corrupted data"
        case .invalidBase64: return "Invalid base64 encoding"
        case .noDEK: return "No decryption key available"
        }
    }
}

enum CryptoManager {

    // MARK: - Envelope format: 12-byte nonce ‖ ciphertext ‖ 16-byte tag

    static func encrypt(_ plaintext: Data, using dek: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(plaintext, using: dek)
        let nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
        return nonce + sealedBox.ciphertext + sealedBox.tag
    }

    static func decrypt(_ envelope: Data, using dek: SymmetricKey) throws -> Data {
        guard envelope.count >= 28 else { throw CryptoError.invalidEnvelope } // 12 nonce + 0 plaintext + 16 tag minimum
        let nonceData = envelope.prefix(12)
        let tagData = envelope.suffix(16)
        let ciphertext = envelope.dropFirst(12).dropLast(16)

        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tagData)
        return try AES.GCM.open(sealedBox, using: dek)
    }

    // MARK: - Base64 envelope helpers

    static func decryptBase64(_ base64String: String, using dek: SymmetricKey) throws -> Data {
        guard let envelope = Data(base64Encoded: base64String) else {
            throw CryptoError.invalidBase64
        }
        return try decrypt(envelope, using: dek)
    }

    static func decryptString(_ base64String: String, using dek: SymmetricKey) throws -> String {
        let data = try decryptBase64(base64String, using: dek)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return string
    }

    static func decryptInt64(_ base64String: String, using dek: SymmetricKey) throws -> Int64 {
        let data = try decryptBase64(base64String, using: dek)
        guard data.count == 8 else { throw CryptoError.decryptionFailed }
        return data.withUnsafeBytes { $0.loadUnaligned(as: Int64.self).littleEndian }
    }

    static func decryptInt32(_ base64String: String, using dek: SymmetricKey) throws -> Int32 {
        let data = try decryptBase64(base64String, using: dek)
        guard data.count == 4 else { throw CryptoError.decryptionFailed }
        return data.withUnsafeBytes { $0.loadUnaligned(as: Int32.self).littleEndian }
    }

    // MARK: - Optional decryption (for nullable encrypted fields)

    static func decryptStringOptional(_ base64String: String?, using dek: SymmetricKey) throws -> String? {
        guard let s = base64String else { return nil }
        return try decryptString(s, using: dek)
    }

    static func decryptInt64Optional(_ base64String: String?, using dek: SymmetricKey) throws -> Int64? {
        guard let s = base64String else { return nil }
        return try decryptInt64(s, using: dek)
    }

    static func decryptInt32Optional(_ base64String: String?, using dek: SymmetricKey) throws -> Int32? {
        guard let s = base64String else { return nil }
        return try decryptInt32(s, using: dek)
    }

    // MARK: - Key generation

    static func generateDEK() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    static func generateRandomBytes(_ count: Int) -> Data {
        var bytes = Data(count: count)
        bytes.withUnsafeMutableBytes { buffer in
            _ = SecRandomCopyBytes(kSecRandomDefault, count, buffer.baseAddress!)
        }
        return bytes
    }
}
