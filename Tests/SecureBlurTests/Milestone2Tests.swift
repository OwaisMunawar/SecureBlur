//
//  Milestone2Tests.swift
//  SecureBlurTests
//
//  Unit tests for crypto, biometrics, and revoke functionality
//

import Testing
import Foundation
import UIKit
@testable import SecureBlur

// MARK: - Test Utilities

private func createTestImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .blue) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}

// MARK: - SecureBlurError Tests

@Suite("SecureBlurError Tests")
struct SecureBlurErrorTests {

    @Test("Error descriptions are not nil")
    func errorDescriptions() {
        let errors: [SecureBlurError] = [
            .metalNotSupported,
            .encryptionFailed,
            .decryptionFailed,
            .keyNotFound,
            .biometricNotAvailable,
            .alreadyRevoked
        ]

        for error in errors {
            #expect(error.localizedDescription.isEmpty == false)
        }
    }

    @Test("Unknown error wrapping")
    func unknownErrorWrapping() {
        struct TestError: Error {}
        let testError = TestError()
        let wrappedError = SecureBlurError.unknownError(testError)

        #expect(wrappedError.localizedDescription.contains("Unknown error"))
    }
}

// MARK: - EncryptedImage Tests

@Suite("EncryptedImage Tests")
struct EncryptedImageTests {

    @Test("EncryptedImage initialization")
    func encryptedImageInit() {
        let ciphertext = Data(repeating: 1, count: 100)
        let iv = Data(repeating: 2, count: 12)
        let tag = Data(repeating: 3, count: 16)
        let dimensions = EncryptedImage.ImageDimensions(width: 100, height: 100)

        let encrypted = EncryptedImage(
            ciphertext: ciphertext,
            iv: iv,
            tag: tag,
            keyIdentifier: "test-key",
            dimensions: dimensions
        )

        #expect(encrypted.ciphertext == ciphertext)
        #expect(encrypted.iv == iv)
        #expect(encrypted.tag == tag)
        #expect(encrypted.keyIdentifier == "test-key")
        #expect(encrypted.isRevoked == false)
    }

    @Test("EncryptedImage revocation")
    func encryptedImageRevocation() {
        let ciphertext = Data(repeating: 1, count: 100)
        let iv = Data(repeating: 2, count: 12)
        let tag = Data(repeating: 3, count: 16)
        let dimensions = EncryptedImage.ImageDimensions(width: 100, height: 100)

        var encrypted = EncryptedImage(
            ciphertext: ciphertext,
            iv: iv,
            tag: tag,
            keyIdentifier: "test-key",
            dimensions: dimensions
        )

        #expect(encrypted.isRevoked == false)
        encrypted.revoke()
        #expect(encrypted.isRevoked == true)
    }

    @Test("EncryptedImage size calculation")
    func encryptedImageSize() {
        let ciphertext = Data(repeating: 1, count: 100)
        let iv = Data(repeating: 2, count: 12)
        let tag = Data(repeating: 3, count: 16)
        let dimensions = EncryptedImage.ImageDimensions(width: 100, height: 100)

        let encrypted = EncryptedImage(
            ciphertext: ciphertext,
            iv: iv,
            tag: tag,
            keyIdentifier: "test-key",
            dimensions: dimensions
        )

        #expect(encrypted.encryptedSize == 128) // 100 + 12 + 16
    }

    @Test("EncryptedImage Codable")
    func encryptedImageCodable() throws {
        let ciphertext = Data(repeating: 1, count: 100)
        let iv = Data(repeating: 2, count: 12)
        let tag = Data(repeating: 3, count: 16)
        let dimensions = EncryptedImage.ImageDimensions(width: 100, height: 100)

        let original = EncryptedImage(
            ciphertext: ciphertext,
            iv: iv,
            tag: tag,
            keyIdentifier: "test-key",
            dimensions: dimensions
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EncryptedImage.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - KeychainManager Tests

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    @Test("KeychainManager initialization")
    func keychainManagerInit() {
        let manager = KeychainManager()
        #expect(manager != nil)
    }

    @Test("Generate and retrieve key")
    func generateAndRetrieveKey() throws {
        let manager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        // Clean up any existing key
        try? manager.deleteKey(identifier: identifier)

        // Generate key
        let key1 = try manager.generateKey(identifier: identifier)
        #expect(key1.bitCount == 256)

        // Retrieve key
        let key2 = try manager.retrieveKey(identifier: identifier)
        #expect(key2.bitCount == 256)

        // Clean up
        try manager.deleteKey(identifier: identifier)
    }

    @Test("Delete key")
    func deleteKey() throws {
        let manager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        // Generate key
        _ = try manager.generateKey(identifier: identifier)
        #expect(manager.keyExists(identifier: identifier) == true)

        // Delete key
        try manager.deleteKey(identifier: identifier)
        #expect(manager.keyExists(identifier: identifier) == false)
    }

    @Test("Key exists check")
    func keyExistsCheck() throws {
        let manager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        #expect(manager.keyExists(identifier: identifier) == false)

        _ = try manager.generateKey(identifier: identifier)
        #expect(manager.keyExists(identifier: identifier) == true)

        try manager.deleteKey(identifier: identifier)
        #expect(manager.keyExists(identifier: identifier) == false)
    }

    @Test("Delete all keys")
    func deleteAllKeys() throws {
        let manager = KeychainManager()

        // Generate multiple keys
        _ = try manager.generateKey(identifier: "test-1")
        _ = try manager.generateKey(identifier: "test-2")

        // Delete all
        try manager.deleteAllKeys()

        #expect(manager.keyExists(identifier: "test-1") == false)
        #expect(manager.keyExists(identifier: "test-2") == false)
    }
}

// MARK: - CryptoManager Tests

@Suite("CryptoManager Tests")
struct CryptoManagerTests {

    @Test("CryptoManager initialization")
    func cryptoManagerInit() {
        let manager = CryptoManager()
        #expect(manager != nil)
    }

    @Test("Encrypt and decrypt image")
    func encryptAndDecryptImage() throws {
        let manager = CryptoManager()
        let keychainManager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        // Clean up
        try? keychainManager.deleteKey(identifier: identifier)

        let originalImage = createTestImage()

        // Encrypt
        let encrypted = try manager.encrypt(originalImage, keyIdentifier: identifier)
        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.iv.count > 0)
        #expect(encrypted.tag.count > 0)
        #expect(encrypted.keyIdentifier == identifier)

        // Decrypt
        let decrypted = try manager.decrypt(encrypted)
        #expect(decrypted != nil)

        // Clean up
        try keychainManager.deleteKey(identifier: identifier)
    }

    @Test("Encrypt with auto-generated key")
    func encryptWithAutoKey() throws {
        let manager = CryptoManager()
        let keychainManager = KeychainManager()
        let originalImage = createTestImage()

        // Encrypt without providing identifier
        let encrypted = try manager.encrypt(originalImage)
        #expect(encrypted.keyIdentifier.isEmpty == false)

        // Decrypt
        let decrypted = try manager.decrypt(encrypted)
        #expect(decrypted != nil)

        // Clean up
        try keychainManager.deleteKey(identifier: encrypted.keyIdentifier)
    }

    @Test("Decrypt fails with revoked image")
    func decryptFailsWithRevokedImage() throws {
        let manager = CryptoManager()
        let keychainManager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        let originalImage = createTestImage()

        // Encrypt
        var encrypted = try manager.encrypt(originalImage, keyIdentifier: identifier)

        // Revoke
        encrypted.revoke()

        // Try to decrypt
        #expect(throws: SecureBlurError.self) {
            _ = try manager.decrypt(encrypted)
        }

        // Clean up
        try keychainManager.deleteKey(identifier: identifier)
    }

    @Test("Revoke encrypted image")
    func revokeEncryptedImage() throws {
        let manager = CryptoManager()
        let keychainManager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        let originalImage = createTestImage()

        // Encrypt
        var encrypted = try manager.encrypt(originalImage, keyIdentifier: identifier)
        #expect(encrypted.isRevoked == false)

        // Revoke
        try manager.revoke(&encrypted)
        #expect(encrypted.isRevoked == true)

        // Key should be deleted
        #expect(keychainManager.keyExists(identifier: identifier) == false)
    }

    @Test("Revoke already revoked image fails")
    func revokeAlreadyRevokedFails() throws {
        let manager = CryptoManager()
        let keychainManager = KeychainManager()
        let identifier = "test-key-\(UUID().uuidString)"

        let originalImage = createTestImage()

        // Encrypt
        var encrypted = try manager.encrypt(originalImage, keyIdentifier: identifier)

        // Revoke once
        try manager.revoke(&encrypted)

        // Try to revoke again
        #expect(throws: SecureBlurError.self) {
            try manager.revoke(&encrypted)
        }
    }
}

// MARK: - BiometricManager Tests

@Suite("BiometricManager Tests")
struct BiometricManagerTests {

    @Test("BiometricManager initialization")
    func biometricManagerInit() {
        let manager = BiometricManager()
        #expect(manager != nil)
    }

    @Test("Check biometric availability")
    func checkBiometricAvailability() {
        let manager = BiometricManager()

        // This may be true or false depending on device/simulator
        let isAvailable = manager.isBiometricAvailable()
        #expect(isAvailable == true || isAvailable == false)
    }

    @Test("Get biometric type")
    func getBiometricType() {
        let manager = BiometricManager()
        let type = manager.biometricType()

        // Should be one of the valid types
        let validTypes: [BiometricManager.BiometricType] = [.none, .touchID, .faceID, .opticID]
        #expect(validTypes.contains {
            switch (type, $0) {
            case (.none, .none), (.touchID, .touchID), (.faceID, .faceID), (.opticID, .opticID):
                return true
            default:
                return false
            }
        })
    }

    @Test("Get biometric type name")
    func getBiometricTypeName() {
        let manager = BiometricManager()
        let name = manager.biometricTypeName()

        #expect(name.isEmpty == false)
        #expect(["None", "Touch ID", "Face ID", "Optic ID"].contains(name))
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Full encrypt-decrypt-revoke flow")
    func fullFlow() throws {
        let keychainManager = KeychainManager()
        let cryptoManager = CryptoManager(keychainManager: keychainManager)
        let identifier = "test-key-\(UUID().uuidString)"

        let originalImage = createTestImage(size: CGSize(width: 200, height: 200), color: .red)

        // 1. Encrypt
        var encrypted = try cryptoManager.encrypt(originalImage, keyIdentifier: identifier)
        #expect(encrypted.isRevoked == false)
        #expect(encrypted.ciphertext.count > 0)

        // 2. Decrypt
        let decrypted = try cryptoManager.decrypt(encrypted)
        #expect(decrypted != nil)

        // 3. Revoke
        try cryptoManager.revoke(&encrypted)
        #expect(encrypted.isRevoked == true)

        // 4. Try to decrypt after revoke (should fail)
        #expect(throws: SecureBlurError.self) {
            _ = try cryptoManager.decrypt(encrypted)
        }
    }
}
