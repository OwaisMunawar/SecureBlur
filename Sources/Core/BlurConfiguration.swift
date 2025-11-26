//
//  BlurConfiguration.swift
//  SecureBlur
//
//  Configuration for blur operations
//

import Foundation

/// Configuration for blur intensity and behavior
public struct BlurConfiguration {

    // MARK: - Properties

    /// The blur radius (sigma) in pixels
    /// Valid range: 1.0 to 100.0
    /// Default: 20.0 (medium blur)
    public let radius: Float

    // MARK: - Constants

    /// Minimum allowed blur radius
    public static let minRadius: Float = 1.0

    /// Maximum allowed blur radius
    public static let maxRadius: Float = 100.0

    /// Default blur radius (medium blur)
    public static let defaultRadius: Float = 20.0

    // MARK: - Initialization

    /// Creates a blur configuration with specified radius
    /// - Parameter radius: The blur radius (1.0 to 100.0). Values outside this range will be clamped.
    public init(radius: Float = BlurConfiguration.defaultRadius) {
        self.radius = Self.clamp(radius, min: Self.minRadius, max: Self.maxRadius)
    }

    // MARK: - Presets

    /// Light blur preset (radius: 10.0)
    public static let light = BlurConfiguration(radius: 10.0)

    /// Medium blur preset (radius: 20.0)
    public static let medium = BlurConfiguration(radius: 20.0)

    /// Heavy blur preset (radius: 40.0)
    public static let heavy = BlurConfiguration(radius: 40.0)

    /// Maximum blur preset (radius: 100.0)
    public static let maximum = BlurConfiguration(radius: 100.0)

    // MARK: - Helpers

    /// Clamps a value between min and max
    private static func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - CustomStringConvertible

extension BlurConfiguration: CustomStringConvertible {
    public var description: String {
        return "BlurConfiguration(radius: \(radius))"
    }
}

// MARK: - Equatable

extension BlurConfiguration: Equatable {
    public static func == (lhs: BlurConfiguration, rhs: BlurConfiguration) -> Bool {
        return lhs.radius == rhs.radius
    }
}
