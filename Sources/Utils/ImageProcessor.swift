//
//  ImageProcessor.swift
//  SecureBlur
//
//  Utilities for efficient image processing, including 4K image support
//

import Foundation
import UIKit
import CoreGraphics

/// Utilities for image processing and optimization
public final class ImageProcessor {

    // MARK: - Constants

    /// Maximum dimension for 4K images (3840 x 2160)
    public static let max4KDimension: CGFloat = 3840

    /// Memory threshold for downsampling (50MB)
    private static let memorySafeThreshold: Int = 50 * 1024 * 1024

    // MARK: - Image Optimization

    /// Optimizes an image for processing by downsampling if necessary
    /// - Parameters:
    ///   - image: The input image
    ///   - maxDimension: Maximum dimension (default: 4K)
    /// - Returns: Optimized image
    public static func optimize(_ image: UIImage, maxDimension: CGFloat = max4KDimension) -> UIImage {
        let size = image.size
        let scale = image.scale

        // Calculate actual pixel dimensions
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale

        // Check if downsam

pling is needed
        guard pixelWidth > maxDimension || pixelHeight > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = pixelWidth / pixelHeight
        var newWidth: CGFloat
        var newHeight: CGFloat

        if aspectRatio > 1 {
            // Landscape
            newWidth = maxDimension
            newHeight = maxDimension / aspectRatio
        } else {
            // Portrait or square
            newHeight = maxDimension
            newWidth = maxDimension * aspectRatio
        }

        // Downsample the image
        return downsample(image, to: CGSize(width: newWidth, height: newHeight))
    }

    /// Downsamples an image to a target size efficiently
    /// - Parameters:
    ///   - image: The input image
    ///   - targetSize: The target size in pixels
    /// - Returns: Downsampled image
    public static func downsample(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        let downsampled = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return downsampled
    }

    /// Checks if an image exceeds the memory-safe threshold
    /// - Parameter image: The image to check
    /// - Returns: True if the image is memory-safe
    public static func isMemorySafe(_ image: UIImage) -> Bool {
        let size = image.size
        let scale = image.scale
        let bytesPerPixel = 4 // RGBA

        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        let estimatedMemory = width * height * bytesPerPixel

        return estimatedMemory <= memorySafeThreshold
    }

    /// Gets the memory footprint estimate for an image
    /// - Parameter image: The image to analyze
    /// - Returns: Estimated memory usage in bytes
    public static func estimatedMemoryUsage(for image: UIImage) -> Int {
        let size = image.size
        let scale = image.scale
        let bytesPerPixel = 4 // RGBA

        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        return width * height * bytesPerPixel
    }

    /// Formats byte size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string (e.g., "12.5 MB")
    public static func formatMemorySize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Image Information

    /// Gets detailed information about an image
    /// - Parameter image: The image to analyze
    /// - Returns: Dictionary with image info
    public static func imageInfo(for image: UIImage) -> [String: Any] {
        let size = image.size
        let scale = image.scale
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)
        let memory = estimatedMemoryUsage(for: image)

        return [
            "size": size,
            "scale": scale,
            "pixelWidth": pixelWidth,
            "pixelHeight": pixelHeight,
            "estimatedMemory": memory,
            "memoryFormatted": formatMemorySize(memory),
            "isMemorySafe": isMemorySafe(image)
        ]
    }
}
