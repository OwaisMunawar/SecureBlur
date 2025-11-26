//
//  Milestone3Tests.swift
//  SecureBlurTests
//
//  Comprehensive integration tests for public API facade
//

import Testing
import UIKit
@testable import SecureBlur

// MARK: - Helper Functions

fileprivate func createTestImage(size: CGSize = CGSize(width: 200, height: 200), color: UIColor = .systemBlue) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // Add some pattern to make blur more visible
        UIColor.white.setFill()
        for i in stride(from: 0, to: Int(size.width), by: 20) {
            context.fill(CGRect(x: i, y: 0, width: 10, height: size.height))
        }
    }
}

// MARK: - SecureBlur Facade Tests

@Suite("SecureBlur Facade Tests")
struct SecureBlurFacadeTests {

    @Test("SecureBlur initialization")
    func testInitialization() throws {
        let secureBlur = try SecureBlur()
        #expect(secureBlur != nil)
    }

    @Test("Version property")
    func testVersion() {
        let version = SecureBlur.version
        #expect(version == "1.0.0")
    }

    @Test("Component access properties")
    func testComponentAccess() throws {
        let secureBlur = try SecureBlur()

        #expect(secureBlur.blur != nil)
        #expect(secureBlur.crypto != nil)
        #expect(secureBlur.biometric != nil)
    }

    @Test("Biometric availability check")
    func testBiometricAvailability() throws {
        let secureBlur = try SecureBlur()

        // Should return boolean without crashing
        let isAvailable = secureBlur.isBiometricAvailable
        #expect(isAvailable == true || isAvailable == false)
    }

    @Test("Biometric type check")
    func testBiometricType() throws {
        let secureBlur = try SecureBlur()

        let type = secureBlur.biometricType
        #expect(type != nil)

        let typeName = secureBlur.biometricTypeName
        #expect(typeName.count > 0)
    }
}

// MARK: - BlurIntensity Tests

@Suite("BlurIntensity Enum Tests")
struct BlurIntensityTests {

    @Test("Light intensity configuration")
    func testLightIntensity() {
        let intensity = SecureBlur.BlurIntensity.light
        let config = intensity.configuration
        #expect(config.radius == 10.0)
    }

    @Test("Medium intensity configuration")
    func testMediumIntensity() {
        let intensity = SecureBlur.BlurIntensity.medium
        let config = intensity.configuration
        #expect(config.radius == 20.0)
    }

    @Test("Heavy intensity configuration")
    func testHeavyIntensity() {
        let intensity = SecureBlur.BlurIntensity.heavy
        let config = intensity.configuration
        #expect(config.radius == 40.0)
    }

    @Test("Maximum intensity configuration")
    func testMaximumIntensity() {
        let intensity = SecureBlur.BlurIntensity.maximum
        let config = intensity.configuration
        #expect(config.radius == 100.0)
    }

    @Test("Custom intensity configuration")
    func testCustomIntensity() {
        let intensity = SecureBlur.BlurIntensity.custom(35.0)
        let config = intensity.configuration
        #expect(config.radius == 35.0)
    }
}

// MARK: - Blur-Only Operations Tests

@Suite("SecureBlur Blur-Only Operations")
struct BlurOnlyOperationsTests {

    @Test("Simple blur with default intensity")
    func testSimpleBlur() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let blurred = try secureBlur.blur(image)

        #expect(blurred.size == image.size)
        #expect(blurred != nil)
    }

    @Test("Blur with light intensity")
    func testBlurLightIntensity() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let blurred = try secureBlur.blur(image, intensity: .light)

        #expect(blurred.size == image.size)
    }

    @Test("Blur with heavy intensity")
    func testBlurHeavyIntensity() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let blurred = try secureBlur.blur(image, intensity: .heavy)

        #expect(blurred.size == image.size)
    }

    @Test("Blur with custom intensity")
    func testBlurCustomIntensity() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let blurred = try secureBlur.blur(image, intensity: .custom(50.0))

        #expect(blurred.size == image.size)
    }

    @Test("Async blur operation")
    func testAsyncBlur() async throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let blurred = try await secureBlur.blur(image, intensity: .medium)

        #expect(blurred.size == image.size)
    }
}

// MARK: - Blur and Encrypt Integration Tests

@Suite("Blur and Encrypt Integration Tests")
struct BlurAndEncryptTests {

    @Test("Blur and encrypt with default settings")
    func testBlurAndEncryptDefault() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted = try secureBlur.blurAndEncrypt(image)

        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.iv.count == 12)
        #expect(encrypted.tag.count == 16)
        #expect(encrypted.isRevoked == false)
        #expect(encrypted.dimensions.width == 200)
        #expect(encrypted.dimensions.height == 200)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Blur and encrypt with light blur")
    func testBlurAndEncryptLight() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted = try secureBlur.blurAndEncrypt(image, blurIntensity: .light)

        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.isRevoked == false)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Blur and encrypt with heavy blur")
    func testBlurAndEncryptHeavy() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted = try secureBlur.blurAndEncrypt(image, blurIntensity: .heavy)

        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.isRevoked == false)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Blur and encrypt with custom key identifier")
    func testBlurAndEncryptCustomKey() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()
        let keyId = "test-key-\(UUID().uuidString)"

        let encrypted = try secureBlur.blurAndEncrypt(
            image,
            blurIntensity: .medium,
            keyIdentifier: keyId
        )

        #expect(encrypted.keyIdentifier == keyId)
        #expect(encrypted.ciphertext.count > 0)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Async blur and encrypt")
    func testAsyncBlurAndEncrypt() async throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted = try await secureBlur.blurAndEncrypt(image, blurIntensity: .medium)

        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.isRevoked == false)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }
}

// MARK: - Decrypt Tests (Without Biometric)

@Suite("Decrypt Tests")
struct DecryptTests {

    @Test("Encrypt and decrypt workflow")
    func testEncryptDecryptWorkflow() throws {
        let secureBlur = try SecureBlur()
        let originalImage = createTestImage()

        // Encrypt
        let encrypted = try secureBlur.blurAndEncrypt(originalImage)

        // Decrypt (directly via crypto manager, no biometric in tests)
        let decrypted = try secureBlur.crypto.decrypt(encrypted)

        #expect(decrypted.size == originalImage.size)
        #expect(decrypted != nil)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Multiple encrypt/decrypt cycles")
    func testMultipleEncryptDecryptCycles() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        for i in 0..<3 {
            let keyId = "cycle-\(i)-\(UUID().uuidString)"

            // Encrypt
            let encrypted = try secureBlur.blurAndEncrypt(
                image,
                blurIntensity: .medium,
                keyIdentifier: keyId
            )

            // Decrypt
            let decrypted = try secureBlur.crypto.decrypt(encrypted)

            #expect(decrypted.size == image.size)

            // Cleanup
            try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
        }
    }
}

// MARK: - Revoke Tests

@Suite("Revoke Tests")
struct RevokeTests {

    @Test("Revoke encrypted image")
    func testRevoke() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        var encrypted = try secureBlur.blurAndEncrypt(image)

        #expect(encrypted.isRevoked == false)

        // Revoke
        try secureBlur.revoke(&encrypted)

        #expect(encrypted.isRevoked == true)
    }

    @Test("Decrypt after revoke should fail")
    func testDecryptAfterRevoke() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        var encrypted = try secureBlur.blurAndEncrypt(image)

        // Revoke
        try secureBlur.revoke(&encrypted)

        // Try to decrypt - should fail
        #expect(throws: SecureBlurError.self) {
            _ = try secureBlur.crypto.decrypt(encrypted)
        }
    }

    @Test("Double revoke should fail")
    func testDoubleRevoke() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        var encrypted = try secureBlur.blurAndEncrypt(image)

        // First revoke - should succeed
        try secureBlur.revoke(&encrypted)

        // Second revoke - should fail
        #expect(throws: SecureBlurError.self) {
            try secureBlur.revoke(&encrypted)
        }
    }
}

// MARK: - EncryptedImage Model Tests

@Suite("EncryptedImage Model Tests")
struct EncryptedImageModelTests {

    @Test("EncryptedImage properties")
    func testEncryptedImageProperties() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 300, height: 400))

        let encrypted = try secureBlur.blurAndEncrypt(image)

        #expect(encrypted.id != nil)
        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.iv.count == 12)
        #expect(encrypted.tag.count == 16)
        #expect(encrypted.keyIdentifier.count > 0)
        #expect(encrypted.timestamp != nil)
        #expect(encrypted.dimensions.width == 300)
        #expect(encrypted.dimensions.height == 400)
        #expect(encrypted.isRevoked == false)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("EncryptedImage computed properties")
    func testEncryptedImageComputedProperties() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted = try secureBlur.blurAndEncrypt(image)

        let size = encrypted.encryptedSize
        #expect(size > 0)

        let formatted = encrypted.encryptedSizeFormatted
        #expect(formatted.count > 0)
        #expect(formatted.contains("KB") || formatted.contains("MB") || formatted.contains("bytes"))

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("EncryptedImage Codable support")
    func testEncryptedImageCodable() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let original = try secureBlur.blurAndEncrypt(image)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        #expect(data.count > 0)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EncryptedImage.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.ciphertext == original.ciphertext)
        #expect(decoded.iv == original.iv)
        #expect(decoded.tag == original.tag)
        #expect(decoded.keyIdentifier == original.keyIdentifier)
        #expect(decoded.dimensions.width == original.dimensions.width)
        #expect(decoded.dimensions.height == original.dimensions.height)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&original).pointee)
    }

    @Test("EncryptedImage Equatable support")
    func testEncryptedImageEquatable() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        let encrypted1 = try secureBlur.blurAndEncrypt(image)
        let encrypted2 = try secureBlur.blurAndEncrypt(image)

        // Different encryptions should not be equal (different IDs and keys)
        #expect(encrypted1 != encrypted2)

        // Same encrypted image should be equal to itself
        #expect(encrypted1 == encrypted1)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted1).pointee)
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted2).pointee)
    }
}

// MARK: - End-to-End Integration Tests

@Suite("End-to-End Integration Tests")
struct EndToEndIntegrationTests {

    @Test("Complete workflow: blur → encrypt → decrypt → revoke")
    func testCompleteWorkflow() throws {
        let secureBlur = try SecureBlur()
        let originalImage = createTestImage()

        // Step 1: Blur and encrypt
        var encrypted = try secureBlur.blurAndEncrypt(
            originalImage,
            blurIntensity: .heavy,
            keyIdentifier: "test-workflow-\(UUID().uuidString)"
        )

        #expect(encrypted.isRevoked == false)
        #expect(encrypted.ciphertext.count > 0)

        // Step 2: Decrypt
        let decrypted = try secureBlur.crypto.decrypt(encrypted)

        #expect(decrypted.size == originalImage.size)

        // Step 3: Revoke
        try secureBlur.revoke(&encrypted)

        #expect(encrypted.isRevoked == true)

        // Step 4: Verify decryption fails after revoke
        #expect(throws: SecureBlurError.self) {
            _ = try secureBlur.crypto.decrypt(encrypted)
        }
    }

    @Test("Multiple images workflow")
    func testMultipleImagesWorkflow() throws {
        let secureBlur = try SecureBlur()

        let images = [
            createTestImage(size: CGSize(width: 100, height: 100), color: .red),
            createTestImage(size: CGSize(width: 200, height: 150), color: .green),
            createTestImage(size: CGSize(width: 300, height: 200), color: .blue)
        ]

        var encryptedImages: [EncryptedImage] = []

        // Encrypt all images
        for (index, image) in images.enumerated() {
            let encrypted = try secureBlur.blurAndEncrypt(
                image,
                blurIntensity: .medium,
                keyIdentifier: "multi-\(index)-\(UUID().uuidString)"
            )
            encryptedImages.append(encrypted)
        }

        #expect(encryptedImages.count == 3)

        // Decrypt all images
        for (index, encrypted) in encryptedImages.enumerated() {
            let decrypted = try secureBlur.crypto.decrypt(encrypted)
            #expect(decrypted.size == images[index].size)
        }

        // Revoke all
        for i in 0..<encryptedImages.count {
            try secureBlur.revoke(&encryptedImages[i])
            #expect(encryptedImages[i].isRevoked == true)
        }
    }

    @Test("Persistence simulation: encode → decode → decrypt")
    func testPersistenceWorkflow() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        // Encrypt
        let encrypted = try secureBlur.blurAndEncrypt(image)

        // Simulate persistence: encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(encrypted)

        // Simulate loading: decode from JSON
        let decoder = JSONDecoder()
        let loaded = try decoder.decode(EncryptedImage.self, from: jsonData)

        #expect(loaded.id == encrypted.id)
        #expect(loaded.keyIdentifier == encrypted.keyIdentifier)

        // Decrypt the loaded encrypted image
        let decrypted = try secureBlur.crypto.decrypt(loaded)

        #expect(decrypted.size == image.size)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }
}

// MARK: - Error Handling Tests

@Suite("Error Handling Tests")
struct ErrorHandlingTests {

    @Test("Decrypt with invalid key should fail")
    func testDecryptInvalidKey() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        // Create encrypted image
        var encrypted = try secureBlur.blurAndEncrypt(image)

        // Manually delete the key
        try secureBlur.crypto.revoke(&encrypted)

        // Try to decrypt - should fail with keyNotFound or alreadyRevoked
        #expect(throws: SecureBlurError.self) {
            _ = try secureBlur.crypto.decrypt(encrypted)
        }
    }

    @Test("SecureBlurError descriptions")
    func testErrorDescriptions() {
        let errors: [SecureBlurError] = [
            .metalNotSupported,
            .imageConversionFailed,
            .encryptionFailed,
            .decryptionFailed,
            .keyNotFound,
            .biometricNotAvailable,
            .alreadyRevoked
        ]

        for error in errors {
            let description = error.localizedDescription
            #expect(description.count > 0)
        }
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Blur performance for standard image")
    func testBlurPerformance() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))

        let startTime = Date()
        _ = try secureBlur.blur(image, intensity: .medium)
        let duration = Date().timeIntervalSince(startTime)

        // Should complete in reasonable time (< 5 seconds on any device)
        #expect(duration < 5.0)
    }

    @Test("Encryption performance for standard image")
    func testEncryptionPerformance() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))

        let startTime = Date()
        let encrypted = try secureBlur.blurAndEncrypt(image, blurIntensity: .medium)
        let duration = Date().timeIntervalSince(startTime)

        // Should complete in reasonable time (< 10 seconds)
        #expect(duration < 10.0)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }
}

// MARK: - Component Integration Tests

@Suite("Component Integration Tests")
struct ComponentIntegrationTests {

    @Test("BlurEngine integration via facade")
    func testBlurEngineIntegration() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        // Access via facade
        let config = BlurConfiguration(radius: 25.0)
        let blurred = try secureBlur.blur.blur(image, configuration: config)

        #expect(blurred.size == image.size)
    }

    @Test("CryptoManager integration via facade")
    func testCryptoManagerIntegration() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage()

        // Blur first
        let blurred = try secureBlur.blur(image)

        // Encrypt via crypto manager
        let encrypted = try secureBlur.crypto.encrypt(blurred)

        #expect(encrypted.ciphertext.count > 0)

        // Decrypt
        let decrypted = try secureBlur.crypto.decrypt(encrypted)

        #expect(decrypted.size == image.size)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("BiometricManager integration via facade")
    func testBiometricManagerIntegration() throws {
        let secureBlur = try SecureBlur()

        // Access biometric manager
        let isAvailable = secureBlur.biometric.isBiometricAvailable()
        let type = secureBlur.biometric.biometricType()
        let typeName = secureBlur.biometric.biometricTypeName()

        #expect(isAvailable == true || isAvailable == false)
        #expect(type != nil)
        #expect(typeName.count > 0)
    }
}

// MARK: - Edge Cases Tests

@Suite("Edge Cases Tests")
struct EdgeCasesTests {

    @Test("Very small image")
    func testVerySmallImage() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 10, height: 10))

        let encrypted = try secureBlur.blurAndEncrypt(image)

        #expect(encrypted.ciphertext.count > 0)
        #expect(encrypted.dimensions.width == 10)
        #expect(encrypted.dimensions.height == 10)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Large image (4K simulation)")
    func testLargeImage() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 3840, height: 2160))

        let encrypted = try secureBlur.blurAndEncrypt(image, blurIntensity: .light)

        #expect(encrypted.ciphertext.count > 0)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }

    @Test("Non-square image")
    func testNonSquareImage() throws {
        let secureBlur = try SecureBlur()
        let image = createTestImage(size: CGSize(width: 400, height: 200))

        let encrypted = try secureBlur.blurAndEncrypt(image)
        let decrypted = try secureBlur.crypto.decrypt(encrypted)

        #expect(decrypted.size.width == 400)
        #expect(decrypted.size.height == 200)

        // Cleanup
        try? secureBlur.crypto.revoke(UnsafeMutablePointer(&encrypted).pointee)
    }
}
