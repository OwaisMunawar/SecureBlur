//
//  SecureBlur.swift
//  SecureBlur
//
//  Clean public API facade for SecureBlur SDK
//

import Foundation
import UIKit

/// Main facade class providing unified access to SecureBlur functionality
///
/// SecureBlur combines GPU-accelerated image blurring with AES-GCM encryption
/// and biometric authentication for maximum privacy and security.
///
/// # Usage
///
/// ```swift
/// // Initialize
/// let secureBlur = SecureBlur()
///
/// // Blur and encrypt
/// let encrypted = try await secureBlur.blurAndEncrypt(image, blurIntensity: .heavy)
///
/// // Decrypt and reveal (requires biometric auth)
/// let revealed = try await secureBlur.revealImage(encrypted)
///
/// // Revoke access
/// try secureBlur.revoke(&encrypted)
/// ```
public final class SecureBlur {

    // MARK: - Properties

    private let blurEngine: BlurEngine
    private let cryptoManager: CryptoManager
    private let biometricManager: BiometricManager

    // MARK: - Initialization

    /// Creates a new SecureBlur instance
    /// - Throws: SecureBlurError if Metal is not available
    public init() throws {
        self.blurEngine = try BlurEngine()
        self.cryptoManager = CryptoManager()
        self.biometricManager = BiometricManager()
    }

    // MARK: - Version

    /// Returns the SDK version
    public static var version: String {
        return "1.0.0"
    }

    // MARK: - Blur Intensity Presets

    /// Predefined blur intensity levels
    public enum BlurIntensity {
        case light
        case medium
        case heavy
        case maximum
        case custom(Float)

        var configuration: BlurConfiguration {
            switch self {
            case .light:
                return .light
            case .medium:
                return .medium
            case .heavy:
                return .heavy
            case .maximum:
                return .maximum
            case .custom(let radius):
                return BlurConfiguration(radius: radius)
            }
        }
    }

    // MARK: - High-Level API

    /// Blur an image and encrypt it in one step
    /// - Parameters:
    ///   - image: Image to blur and encrypt
    ///   - blurIntensity: Blur intensity level (default: .medium)
    ///   - keyIdentifier: Optional key identifier (auto-generated if nil)
    /// - Returns: Encrypted image data
    /// - Throws: SecureBlurError if operation fails
    public func blurAndEncrypt(
        _ image: UIImage,
        blurIntensity: BlurIntensity = .medium,
        keyIdentifier: String? = nil
    ) throws -> EncryptedImage {
        // Blur the image
        let blurred = try blurEngine.blur(image, configuration: blurIntensity.configuration)

        // Encrypt the blurred image
        let encrypted = try cryptoManager.encrypt(blurred, keyIdentifier: keyIdentifier)

        return encrypted
    }

    /// Blur an image and encrypt it asynchronously
    /// - Parameters:
    ///   - image: Image to blur and encrypt
    ///   - blurIntensity: Blur intensity level (default: .medium)
    ///   - keyIdentifier: Optional key identifier (auto-generated if nil)
    ///   - completion: Completion handler with result
    public func blurAndEncryptAsync(
        _ image: UIImage,
        blurIntensity: BlurIntensity = .medium,
        keyIdentifier: String? = nil,
        completion: @escaping (Result<EncryptedImage, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let encrypted = try self.blurAndEncrypt(
                    image,
                    blurIntensity: blurIntensity,
                    keyIdentifier: keyIdentifier
                )
                DispatchQueue.main.async {
                    completion(.success(encrypted))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Blur an image and encrypt it (async/await)
    /// - Parameters:
    ///   - image: Image to blur and encrypt
    ///   - blurIntensity: Blur intensity level (default: .medium)
    ///   - keyIdentifier: Optional key identifier (auto-generated if nil)
    /// - Returns: Encrypted image data
    /// - Throws: SecureBlurError if operation fails
    @available(iOS 15.0, *)
    public func blurAndEncrypt(
        _ image: UIImage,
        blurIntensity: BlurIntensity = .medium,
        keyIdentifier: String? = nil
    ) async throws -> EncryptedImage {
        return try await withCheckedThrowingContinuation { continuation in
            blurAndEncryptAsync(image, blurIntensity: blurIntensity, keyIdentifier: keyIdentifier) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Reveal (Decrypt with Biometric Auth)

    /// Reveal (decrypt) an encrypted image with biometric authentication
    /// - Parameters:
    ///   - encryptedImage: Encrypted image to reveal
    ///   - reason: Reason to show user for biometric authentication
    /// - Returns: Decrypted original image
    /// - Throws: SecureBlurError if decryption or authentication fails
    public func revealImage(
        _ encryptedImage: EncryptedImage,
        reason: String = "Authenticate to reveal image"
    ) throws -> UIImage {
        // Check biometric availability
        guard biometricManager.isBiometricAvailable() else {
            throw SecureBlurError.biometricNotAvailable
        }

        // Note: For synchronous API, biometric auth must be handled by caller
        // or we need to use a semaphore (not recommended for main thread)

        // Decrypt the image
        let decrypted = try cryptoManager.decrypt(encryptedImage)

        return decrypted
    }

    /// Reveal (decrypt) an encrypted image with biometric authentication asynchronously
    /// - Parameters:
    ///   - encryptedImage: Encrypted image to reveal
    ///   - reason: Reason to show user for biometric authentication
    ///   - completion: Completion handler with result
    public func revealImageAsync(
        _ encryptedImage: EncryptedImage,
        reason: String = "Authenticate to reveal image",
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // Check biometric availability
        guard biometricManager.isBiometricAvailable() else {
            completion(.failure(SecureBlurError.biometricNotAvailable))
            return
        }

        // Authenticate with biometrics
        biometricManager.authenticate(reason: reason) { authResult in
            switch authResult {
            case .success:
                // Authentication successful, decrypt
                self.cryptoManager.decryptAsync(encryptedImage) { decryptResult in
                    completion(decryptResult)
                }
            case .failure(let error):
                // Authentication failed
                completion(.failure(error))
            }
        }
    }

    /// Reveal (decrypt) an encrypted image with biometric authentication (async/await)
    /// - Parameters:
    ///   - encryptedImage: Encrypted image to reveal
    ///   - reason: Reason to show user for biometric authentication
    /// - Returns: Decrypted original image
    /// - Throws: SecureBlurError if decryption or authentication fails
    @available(iOS 15.0, *)
    public func revealImage(
        _ encryptedImage: EncryptedImage,
        reason: String = "Authenticate to reveal image"
    ) async throws -> UIImage {
        // Check biometric availability
        guard biometricManager.isBiometricAvailable() else {
            throw SecureBlurError.biometricNotAvailable
        }

        // Authenticate with biometrics
        try await biometricManager.authenticate(reason: reason)

        // Decrypt the image
        let decrypted = try await cryptoManager.decrypt(encryptedImage)

        return decrypted
    }

    // MARK: - Revoke

    /// Revoke access to an encrypted image permanently
    ///
    /// This deletes the encryption key from the Keychain, making the
    /// encrypted image permanently inaccessible. This operation is irreversible.
    ///
    /// - Parameter encryptedImage: Encrypted image to revoke
    /// - Throws: SecureBlurError if revocation fails
    public func revoke(_ encryptedImage: inout EncryptedImage) throws {
        try cryptoManager.revoke(&encryptedImage)
    }

    // MARK: - Component Access

    /// Access to blur engine for fine-grained control
    public var blur: BlurEngine {
        return blurEngine
    }

    /// Access to crypto manager for advanced encryption operations
    public var crypto: CryptoManager {
        return cryptoManager
    }

    /// Access to biometric manager for authentication control
    public var biometric: BiometricManager {
        return biometricManager
    }

    // MARK: - Utility

    /// Check if biometric authentication is available
    public var isBiometricAvailable: Bool {
        return biometricManager.isBiometricAvailable()
    }

    /// Get the type of biometric authentication available
    public var biometricType: BiometricManager.BiometricType {
        return biometricManager.biometricType()
    }

    /// Get human-readable name of biometric type
    public var biometricTypeName: String {
        return biometricManager.biometricTypeName()
    }
}

// MARK: - Convenience Extensions

extension SecureBlur {

    /// Quick blur-only operation (no encryption)
    /// - Parameters:
    ///   - image: Image to blur
    ///   - intensity: Blur intensity
    /// - Returns: Blurred image
    /// - Throws: SecureBlurError if blur fails
    public func blur(_ image: UIImage, intensity: BlurIntensity = .medium) throws -> UIImage {
        return try blurEngine.blur(image, configuration: intensity.configuration)
    }

    /// Quick blur-only operation asynchronously
    /// - Parameters:
    ///   - image: Image to blur
    ///   - intensity: Blur intensity
    ///   - completion: Completion handler
    public func blurAsync(
        _ image: UIImage,
        intensity: BlurIntensity = .medium,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        blurEngine.blurAsync(image, configuration: intensity.configuration, completion: completion)
    }

    /// Quick blur-only operation (async/await)
    /// - Parameters:
    ///   - image: Image to blur
    ///   - intensity: Blur intensity
    /// - Returns: Blurred image
    /// - Throws: SecureBlurError if blur fails
    @available(iOS 15.0, *)
    public func blur(_ image: UIImage, intensity: BlurIntensity = .medium) async throws -> UIImage {
        return try await blurEngine.blur(image, configuration: intensity.configuration)
    }
}
