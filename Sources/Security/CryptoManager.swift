//
//  CryptoManager.swift
//  SecureBlur
//
//  AES-GCM encryption and decryption for image data
//

import Foundation
import UIKit
import CryptoKit

public final class CryptoManager {
    // MARK: - Properties

    private let keychainManager: KeychainManager

    // MARK: - Initialization

    /// Initialize CryptoManager with KeychainManager
    /// - Parameter keychainManager: Manager for key storage (optional, creates default if nil)
    public init(keychainManager: KeychainManager = KeychainManager()) {
        self.keychainManager = keychainManager
    }

    // MARK: - Encryption

    /// Encrypt an image using AES-GCM
    /// - Parameters:
    ///   - image: Image to encrypt
    ///   - keyIdentifier: Unique identifier for the encryption key (optional, generates new key if nil)
    /// - Returns: EncryptedImage containing ciphertext and metadata
    /// - Throws: SecureBlurError if encryption fails
    public func encrypt(_ image: UIImage, keyIdentifier: String? = nil) throws -> EncryptedImage {
        // Convert image to data
        guard let imageData = image.pngData() else {
            throw SecureBlurError.imageConversionFailed
        }

        // Generate or retrieve encryption key
        let identifier = keyIdentifier ?? UUID().uuidString
        let key: SymmetricKey

        if keychainManager.keyExists(identifier: identifier) {
            key = try keychainManager.retrieveKey(identifier: identifier)
        } else {
            key = try keychainManager.generateKey(identifier: identifier)
        }

        // Generate random nonce (IV)
        let nonce = try AES.GCM.Nonce()

        // Encrypt data using AES-GCM
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.seal(imageData, using: key, nonce: nonce)
        } catch {
            throw SecureBlurError.encryptionFailed
        }

        // Extract ciphertext and tag
        guard let ciphertext = sealedBox.ciphertext.withUnsafeBytes({ Data($0) }) as Data?,
              let tag = sealedBox.tag.withUnsafeBytes({ Data($0) }) as Data? else {
            throw SecureBlurError.encryptionFailed
        }

        // Get image dimensions
        let dimensions = EncryptedImage.ImageDimensions(
            width: Int(image.size.width * image.scale),
            height: Int(image.size.height * image.scale)
        )

        // Create EncryptedImage
        let encryptedImage = EncryptedImage(
            ciphertext: ciphertext,
            iv: Data(nonce),
            tag: tag,
            keyIdentifier: identifier,
            dimensions: dimensions
        )

        return encryptedImage
    }

    /// Async encryption for large images
    /// - Parameters:
    ///   - image: Image to encrypt
    ///   - keyIdentifier: Unique identifier for the encryption key
    ///   - completion: Completion handler with result
    public func encryptAsync(
        _ image: UIImage,
        keyIdentifier: String? = nil,
        completion: @escaping (Result<EncryptedImage, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let encrypted = try self.encrypt(image, keyIdentifier: keyIdentifier)
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

    // MARK: - Decryption

    /// Decrypt an encrypted image using AES-GCM
    /// - Parameter encryptedImage: Encrypted image to decrypt
    /// - Returns: Decrypted UIImage
    /// - Throws: SecureBlurError if decryption fails
    public func decrypt(_ encryptedImage: EncryptedImage) throws -> UIImage {
        // Check if revoked
        guard !encryptedImage.isRevoked else {
            throw SecureBlurError.alreadyRevoked
        }

        // Retrieve encryption key
        let key = try keychainManager.retrieveKey(identifier: encryptedImage.keyIdentifier)

        // Reconstruct nonce
        guard let nonce = try? AES.GCM.Nonce(data: encryptedImage.iv) else {
            throw SecureBlurError.invalidEncryptedData
        }

        // Reconstruct sealed box
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: encryptedImage.ciphertext,
                tag: encryptedImage.tag
            )
        } catch {
            throw SecureBlurError.invalidCiphertext
        }

        // Decrypt data
        let decryptedData: Data
        do {
            decryptedData = try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw SecureBlurError.decryptionFailed
        }

        // Convert data to image
        guard let image = UIImage(data: decryptedData) else {
            throw SecureBlurError.imageConversionFailed
        }

        return image
    }

    /// Async decryption for large images
    /// - Parameters:
    ///   - encryptedImage: Encrypted image to decrypt
    ///   - completion: Completion handler with result
    public func decryptAsync(
        _ encryptedImage: EncryptedImage,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = try self.decrypt(encryptedImage)
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Async/Await (iOS 15+)

    @available(iOS 15.0, *)
    public func encrypt(_ image: UIImage, keyIdentifier: String? = nil) async throws -> EncryptedImage {
        return try await withCheckedThrowingContinuation { continuation in
            encryptAsync(image, keyIdentifier: keyIdentifier) { result in
                continuation.resume(with: result)
            }
        }
    }

    @available(iOS 15.0, *)
    public func decrypt(_ encryptedImage: EncryptedImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            decryptAsync(encryptedImage) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Revoke

    /// Revoke access to an encrypted image by deleting its key
    /// - Parameter encryptedImage: Encrypted image to revoke
    /// - Throws: SecureBlurError if revocation fails
    public func revoke(_ encryptedImage: inout EncryptedImage) throws {
        guard !encryptedImage.isRevoked else {
            throw SecureBlurError.alreadyRevoked
        }

        // Delete the encryption key from Keychain
        do {
            try keychainManager.deleteKey(identifier: encryptedImage.keyIdentifier)
        } catch {
            throw SecureBlurError.revokeFailed
        }

        // Mark as revoked
        encryptedImage.revoke()
    }
}
