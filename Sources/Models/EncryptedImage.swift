//
//  EncryptedImage.swift
//  SecureBlur
//
//  Model for encrypted image data with metadata
//

import Foundation

public struct EncryptedImage: Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier for this encrypted image
    public let id: UUID

    /// AES-GCM encrypted image data
    public let ciphertext: Data

    /// Initialization vector (nonce) for AES-GCM
    public let iv: Data

    /// Authentication tag from AES-GCM
    public let tag: Data

    /// Keychain identifier for the encryption key
    public let keyIdentifier: String

    /// Timestamp when the image was encrypted
    public let timestamp: Date

    /// Original image dimensions (before encryption)
    public let dimensions: ImageDimensions

    /// Whether access has been revoked
    public internal(set) var isRevoked: Bool

    // MARK: - Nested Types

    public struct ImageDimensions: Codable, Equatable {
        public let width: Int
        public let height: Int

        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        ciphertext: Data,
        iv: Data,
        tag: Data,
        keyIdentifier: String,
        timestamp: Date = Date(),
        dimensions: ImageDimensions,
        isRevoked: Bool = false
    ) {
        self.id = id
        self.ciphertext = ciphertext
        self.iv = iv
        self.tag = tag
        self.keyIdentifier = keyIdentifier
        self.timestamp = timestamp
        self.dimensions = dimensions
        self.isRevoked = isRevoked
    }

    // MARK: - Revocation

    /// Mark this encrypted image as revoked
    public mutating func revoke() {
        isRevoked = true
    }

    // MARK: - Computed Properties

    /// Size of encrypted data in bytes
    public var encryptedSize: Int {
        return ciphertext.count + iv.count + tag.count
    }

    /// Human-readable size of encrypted data
    public var encryptedSizeFormatted: String {
        let bytes = encryptedSize
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - CustomStringConvertible

extension EncryptedImage: CustomStringConvertible {
    public var description: String {
        return """
        EncryptedImage(
            id: \(id),
            size: \(encryptedSizeFormatted),
            dimensions: \(dimensions.width)x\(dimensions.height),
            keyIdentifier: \(keyIdentifier),
            timestamp: \(timestamp),
            revoked: \(isRevoked)
        )
        """
    }
}
