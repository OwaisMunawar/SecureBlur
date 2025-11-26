//
//  BiometricManager.swift
//  SecureBlur
//
//  Face ID and Touch ID biometric authentication
//

import Foundation
import LocalAuthentication

public final class BiometricManager {
    // MARK: - Types

    public enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
    }

    // MARK: - Properties

    private let context: LAContext

    // MARK: - Initialization

    public init() {
        self.context = LAContext()
    }

    // MARK: - Biometric Availability

    /// Check if biometric authentication is available
    /// - Returns: True if biometrics are available and enrolled
    public func isBiometricAvailable() -> Bool {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return available
    }

    /// Get the type of biometric authentication available
    /// - Returns: BiometricType enum value
    public func biometricType() -> BiometricType {
        guard isBiometricAvailable() else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            if #available(iOS 17.0, *) {
                return .opticID
            }
            return .none
        @unknown default:
            return .none
        }
    }

    // MARK: - Authentication

    /// Authenticate user with biometrics
    /// - Parameters:
    ///   - reason: Reason for authentication to display to user
    ///   - completion: Completion handler with result
    public func authenticate(
        reason: String = "Authenticate to access encrypted image",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Check if biometrics are available
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                completion(.failure(mapLAError(error)))
            } else {
                completion(.failure(SecureBlurError.biometricNotAvailable))
            }
            return
        }

        // Perform authentication
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let error = error {
                    completion(.failure(self.mapLAError(error as NSError)))
                } else {
                    completion(.failure(SecureBlurError.biometricAuthenticationFailed))
                }
            }
        }
    }

    // MARK: - Async/Await (iOS 15+)

    @available(iOS 15.0, *)
    public func authenticate(reason: String = "Authenticate to access encrypted image") async throws {
        return try await withCheckedThrowingContinuation { continuation in
            authenticate(reason: reason) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Error Mapping

    private func mapLAError(_ error: NSError) -> Error {
        guard let laError = LAError.Code(rawValue: error.code) else {
            return SecureBlurError.unknownError(error)
        }

        switch laError {
        case .authenticationFailed:
            return SecureBlurError.biometricAuthenticationFailed

        case .userCancel:
            return SecureBlurError.userCancelled

        case .userFallback:
            return SecureBlurError.userCancelled

        case .biometryNotAvailable:
            return SecureBlurError.biometricNotAvailable

        case .biometryNotEnrolled:
            return SecureBlurError.biometricNotEnrolled

        case .biometryLockout:
            return SecureBlurError.biometricLockout

        case .appCancel:
            return SecureBlurError.operationCancelled

        case .invalidContext:
            return SecureBlurError.biometricAuthenticationFailed

        case .notInteractive:
            return SecureBlurError.biometricAuthenticationFailed

        case .passcodeNotSet:
            return SecureBlurError.biometricNotAvailable

        case .systemCancel:
            return SecureBlurError.operationCancelled

        case .watchNotAvailable:
            return SecureBlurError.biometricNotAvailable

        case .biometryDisconnected:
            return SecureBlurError.biometricNotAvailable

        @unknown default:
            return SecureBlurError.unknownError(error)
        }
    }

    // MARK: - Utility

    /// Get human-readable name for current biometric type
    /// - Returns: Name of biometric type
    public func biometricTypeName() -> String {
        switch biometricType() {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }

    /// Invalidate the current authentication context
    /// Call this to force reauthentication on next attempt
    public func invalidate() {
        context.invalidate()
    }
}
