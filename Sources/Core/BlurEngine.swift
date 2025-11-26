//
//  BlurEngine.swift
//  SecureBlur
//
//  GPU-accelerated Gaussian blur using Metal Performance Shaders
//

import Foundation
import UIKit
import Metal
import MetalPerformanceShaders
import CoreImage

/// Errors that can occur during blur operations
public enum BlurError: Error, LocalizedError {
    case metalNotSupported
    case imageConversionFailed
    case textureCreationFailed
    case blurOperationFailed

    public var errorDescription: String? {
        switch self {
        case .metalNotSupported:
            return "Metal is not supported on this device"
        case .imageConversionFailed:
            return "Failed to convert image to required format"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .blurOperationFailed:
            return "Blur operation failed"
        }
    }
}

/// High-performance GPU-based Gaussian blur engine
public final class BlurEngine {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    // MARK: - Initialization

    /// Creates a new blur engine
    /// - Throws: BlurError.metalNotSupported if Metal is not available
    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw BlurError.metalNotSupported
        }

        guard let commandQueue = device.makeCommandQueue() else {
            throw BlurError.metalNotSupported
        }

        self.device = device
        self.commandQueue = commandQueue
        self.ciContext = CIContext(mtlDevice: device)
    }

    // MARK: - Public API

    /// Applies Gaussian blur to an image using GPU acceleration
    /// - Parameters:
    ///   - image: The input image to blur
    ///   - configuration: The blur configuration (default: medium)
    /// - Returns: The blurred image
    /// - Throws: BlurError if the operation fails
    public func blur(_ image: UIImage, configuration: BlurConfiguration = .medium) throws -> UIImage {
        // Convert UIImage to CIImage
        guard let inputCIImage = CIImage(image: image) else {
            throw BlurError.imageConversionFailed
        }

        // Apply Gaussian blur using Core Image (which uses Metal under the hood)
        let blurredCIImage = inputCIImage.applyingGaussianBlur(sigma: Double(configuration.radius))

        // Render to UIImage
        guard let cgImage = ciContext.createCGImage(blurredCIImage, from: blurredCIImage.extent) else {
            throw BlurError.blurOperationFailed
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Applies Gaussian blur asynchronously on a background queue
    /// - Parameters:
    ///   - image: The input image to blur
    ///   - configuration: The blur configuration (default: medium)
    ///   - completion: Completion handler called with the result
    public func blurAsync(
        _ image: UIImage,
        configuration: BlurConfiguration = .medium,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(BlurError.blurOperationFailed))
                }
                return
            }

            do {
                let blurred = try self.blur(image, configuration: configuration)
                DispatchQueue.main.async {
                    completion(.success(blurred))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Applies Gaussian blur asynchronously (async/await version)
    /// - Parameters:
    ///   - image: The input image to blur
    ///   - configuration: The blur configuration (default: medium)
    /// - Returns: The blurred image
    /// - Throws: BlurError if the operation fails
    @available(iOS 15.0, *)
    public func blur(_ image: UIImage, configuration: BlurConfiguration = .medium) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            blurAsync(image, configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - CIImage Blur Extension

private extension CIImage {
    func applyingGaussianBlur(sigma: Double) -> CIImage {
        let parameters: [String: Any] = [
            kCIInputRadiusKey: sigma,
            kCIInputImageKey: self
        ]

        guard let filter = CIFilter(name: "CIGaussianBlur", parameters: parameters),
              let output = filter.outputImage else {
            return self
        }

        return output
    }
}
