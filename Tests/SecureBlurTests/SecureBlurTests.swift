import Testing
import UIKit
@testable import SecureBlur

// MARK: - BlurConfiguration Tests

@Suite("BlurConfiguration Tests")
struct BlurConfigurationTests {

    @Test("Default blur configuration")
    func testDefaultConfiguration() {
        let config = BlurConfiguration()
        #expect(config.radius == BlurConfiguration.defaultRadius)
    }

    @Test("Custom blur radius")
    func testCustomRadius() {
        let config = BlurConfiguration(radius: 30.0)
        #expect(config.radius == 30.0)
    }

    @Test("Blur radius clamping - minimum")
    func testRadiusClampingMin() {
        let config = BlurConfiguration(radius: -10.0)
        #expect(config.radius == BlurConfiguration.minRadius)
    }

    @Test("Blur radius clamping - maximum")
    func testRadiusClampingMax() {
        let config = BlurConfiguration(radius: 200.0)
        #expect(config.radius == BlurConfiguration.maxRadius)
    }

    @Test("Blur presets")
    func testPresets() {
        #expect(BlurConfiguration.light.radius == 10.0)
        #expect(BlurConfiguration.medium.radius == 20.0)
        #expect(BlurConfiguration.heavy.radius == 40.0)
        #expect(BlurConfiguration.maximum.radius == 100.0)
    }

    @Test("Configuration equality")
    func testEquality() {
        let config1 = BlurConfiguration(radius: 25.0)
        let config2 = BlurConfiguration(radius: 25.0)
        let config3 = BlurConfiguration(radius: 30.0)

        #expect(config1 == config2)
        #expect(config1 != config3)
    }
}

// MARK: - BlurEngine Tests

@Suite("BlurEngine Tests")
struct BlurEngineTests {

    @Test("BlurEngine initialization")
    func testInitialization() throws {
        let engine = try BlurEngine()
        #expect(engine != nil)
    }

    @Test("Blur operation with test image")
    func testBlurOperation() throws {
        let engine = try BlurEngine()
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))

        let blurred = try engine.blur(testImage, configuration: .medium)

        #expect(blurred.size == testImage.size)
        #expect(blurred.scale == testImage.scale)
    }

    @Test("Blur with different configurations")
    func testDifferentConfigurations() throws {
        let engine = try BlurEngine()
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))

        let lightBlur = try engine.blur(testImage, configuration: .light)
        let heavyBlur = try engine.blur(testImage, configuration: .heavy)

        #expect(lightBlur.size == testImage.size)
        #expect(heavyBlur.size == testImage.size)
    }

    @Test("Async blur operation")
    func testAsyncBlur() async throws {
        let engine = try BlurEngine()
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))

        let blurred = try await engine.blur(testImage, configuration: .medium)

        #expect(blurred.size == testImage.size)
    }

    // Helper: Create a test image
    private func createTestImage(size: CGSize, color: UIColor = .blue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - ImageProcessor Tests

@Suite("ImageProcessor Tests")
struct ImageProcessorTests {

    @Test("Image optimization - no downsampling needed")
    func testOptimizeSmallImage() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let optimized = ImageProcessor.optimize(testImage)

        #expect(optimized.size == testImage.size)
    }

    @Test("Image optimization - downsampling needed")
    func testOptimizeLargeImage() {
        let testImage = createTestImage(size: CGSize(width: 5000, height: 4000))
        let optimized = ImageProcessor.optimize(testImage, maxDimension: 2000)

        let maxDimension = max(optimized.size.width, optimized.size.height)
        #expect(maxDimension <= 2000)
    }

    @Test("Image downsampling")
    func testDownsampling() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let downsampled = ImageProcessor.downsample(testImage, to: CGSize(width: 500, height: 500))

        #expect(downsampled.size.width == 500)
        #expect(downsampled.size.height == 500)
    }

    @Test("Memory safety check")
    func testMemorySafetyCheck() {
        let smallImage = createTestImage(size: CGSize(width: 100, height: 100))
        let largeImage = createTestImage(size: CGSize(width: 5000, height: 5000))

        #expect(ImageProcessor.isMemorySafe(smallImage) == true)
        #expect(ImageProcessor.isMemorySafe(largeImage) == false)
    }

    @Test("Estimated memory usage")
    func testEstimatedMemoryUsage() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let memory = ImageProcessor.estimatedMemoryUsage(for: testImage)

        // 1000 x 1000 x 4 bytes (RGBA) = 4,000,000 bytes
        #expect(memory == 4_000_000)
    }

    @Test("Image info dictionary")
    func testImageInfo() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let info = ImageProcessor.imageInfo(for: testImage)

        #expect(info["pixelWidth"] as? Int == 1000)
        #expect(info["pixelHeight"] as? Int == 1000)
        #expect(info["estimatedMemory"] as? Int == 4_000_000)
        #expect(info["isMemorySafe"] as? Bool == true)
    }

    @Test("Memory size formatting")
    func testMemorySizeFormatting() {
        let formatted1 = ImageProcessor.formatMemorySize(1024)
        let formatted2 = ImageProcessor.formatMemorySize(1_048_576)
        let formatted3 = ImageProcessor.formatMemorySize(50_000_000)

        #expect(formatted1.contains("KB"))
        #expect(formatted2.contains("MB"))
        #expect(formatted3.contains("MB"))
    }

    // Helper: Create a test image
    private func createTestImage(size: CGSize, color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
