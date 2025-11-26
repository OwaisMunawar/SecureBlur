//
//  SecureBlurError.swift
//  SecureBlur
//
//  Comprehensive error handling for SecureBlur operations
//

import Foundation

public enum SecureBlurError: Error {
    // Blur errors
    case metalNotSupported
    case imageConversionFailed
    case textureCreationFailed
    case blurOperationFailed

    // Crypto errors
    case encryptionFailed
    case decryptionFailed
    case invalidCiphertext
    case invalidEncryptedData
    case keyGenerationFailed
    case keyNotFound

    // Keychain errors
    case keychainReadFailed
    case keychainWriteFailed
    case keychainDeleteFailed
    case keychainDuplicateItem
    case secureEnclaveNotAvailable

    // Biometric errors
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricAuthenticationFailed
    case biometricLockout
    case userCancelled

    // Revoke errors
    case alreadyRevoked
    case revokeFailed

    // General errors
    case invalidInput
    case operationCancelled
    case unknownError(Error)
}

extension SecureBlurError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        // Blur errors
        case .metalNotSupported:
            return "Metal GPU acceleration is not supported on this device"
        case .imageConversionFailed:
            return "Failed to convert image format"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .blurOperationFailed:
            return "Blur operation failed"

        // Crypto errors
        case .encryptionFailed:
            return "Failed to encrypt image data"
        case .decryptionFailed:
            return "Failed to decrypt image data"
        case .invalidCiphertext:
            return "Invalid or corrupted ciphertext"
        case .invalidEncryptedData:
            return "Invalid encrypted data format"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .keyNotFound:
            return "Encryption key not found in Keychain"

        // Keychain errors
        case .keychainReadFailed:
            return "Failed to read from Keychain"
        case .keychainWriteFailed:
            return "Failed to write to Keychain"
        case .keychainDeleteFailed:
            return "Failed to delete from Keychain"
        case .keychainDuplicateItem:
            return "Item already exists in Keychain"
        case .secureEnclaveNotAvailable:
            return "Secure Enclave is not available on this device"

        // Biometric errors
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .biometricNotEnrolled:
            return "No biometric credentials enrolled on this device"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .biometricLockout:
            return "Biometric authentication locked due to too many failed attempts"
        case .userCancelled:
            return "User cancelled the operation"

        // Revoke errors
        case .alreadyRevoked:
            return "Access has already been revoked"
        case .revokeFailed:
            return "Failed to revoke access"

        // General errors
        case .invalidInput:
            return "Invalid input provided"
        case .operationCancelled:
            return "Operation was cancelled"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
