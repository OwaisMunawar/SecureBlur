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

/// High-performance GPU-based Gaussian blur engine
public final class BlurEngine {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    // MARK: - Initialization

    /// Creates a new blur engine
    /// - Throws: SecureSecureBlurError.metalNotSupported if Metal is not available
    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw SecureSecureBlurError.metalNotSupported
        }

        guard let commandQueue = device.makeCommandQueue() else {
            throw SecureBlurError.metalNotSupported
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
    /// - Throws: SecureBlurError if the operation fails
    public func blur(_ image: UIImage, configuration: BlurConfiguration = .medium) throws -> UIImage {
        // Convert UIImage to CIImage
        guard let inputCIImage = CIImage(image: image) else {
            throw SecureBlurError.imageConversionFailed
        }

        // Apply Gaussian blur using Core Image (which uses Metal under the hood)
        let blurredCIImage = inputCIImage.applyingGaussianBlur(sigma: Double(configuration.radius))

        // Render to UIImage
        guard let cgImage = ciContext.createCGImage(blurredCIImage, from: blurredCIImage.extent) else {
            throw SecureBlurError.blurOperationFailed
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
                    completion(.failure(SecureBlurError.blurOperationFailed))
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
    /// - Throws: SecureBlurError if the operation fails
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
