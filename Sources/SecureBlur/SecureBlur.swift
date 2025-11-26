//
//  SecureBlur.swift
//  SecureBlur
//
//  Main entry point for SecureBlur SDK
//

import Foundation
import UIKit

/// SecureBlur SDK for secure image blurring with biometric-gated decryption
public final class SecureBlur {

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Returns the SDK version
    public static var version: String {
        return "1.0.0"
    }
}
