//
//  BlurTestView.swift
//  SecureBlurDemo
//
//  Test harness for blur functionality
//

import SwiftUI
import PhotosUI
import SecureBlur

struct BlurTestView: View {

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var blurredImage: UIImage?
    @State private var blurIntensity: Float = BlurConfiguration.defaultRadius
    @State private var isProcessing = false
    @State private var processingTime: TimeInterval = 0
    @State private var showImagePicker = false
    @State private var showFullscreen = false
    @State private var errorMessage: String?

    // MARK: - Properties

    private let blurEngine: BlurEngine?

    // MARK: - Initialization

    init() {
        self.blurEngine = try? BlurEngine()
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image Selection
                    imageSelectionSection

                    if selectedImage != nil {
                        // Blur Controls
                        blurControlsSection

                        // Image Preview
                        imagePreviewSection

                        // Performance Metrics
                        metricsSection
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Blur Test Harness")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                FullscreenImageView(image: blurredImage, isPresented: $showFullscreen)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    applyBlur()
                }
            }
        }
    }

    // MARK: - View Components

    private var imageSelectionSection: some View {
        VStack(spacing: 12) {
            Button(action: { showImagePicker = true }) {
                Label("Select Image", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let image = selectedImage {
                let info = ImageProcessor.imageInfo(for: image)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image Info:")
                        .font(.caption.bold())
                    Text("Dimensions: \(info["pixelWidth"] as? Int ?? 0) x \(info["pixelHeight"] as? Int ?? 0)")
                        .font(.caption)
                    Text("Memory: \(info["memoryFormatted"] as? String ?? "N/A")")
                        .font(.caption)
                    Text("Memory Safe: \(info["isMemorySafe"] as? Bool ?? false ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundColor((info["isMemorySafe"] as? Bool ?? false) ? .green : .orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var blurControlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Blur Intensity")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", blurIntensity))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            Slider(
                value: $blurIntensity,
                in: BlurConfiguration.minRadius...BlurConfiguration.maxRadius,
                step: 1.0
            )
            .onChange(of: blurIntensity) { _ in
                applyBlur()
            }

            HStack(spacing: 12) {
                PresetButton(title: "Light", radius: 10.0, currentRadius: $blurIntensity)
                PresetButton(title: "Medium", radius: 20.0, currentRadius: $blurIntensity)
                PresetButton(title: "Heavy", radius: 40.0, currentRadius: $blurIntensity)
                PresetButton(title: "Max", radius: 100.0, currentRadius: $blurIntensity)
            }
        }
    }

    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)

            if isProcessing {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 300)
            } else if let blurred = blurredImage {
                Image(uiImage: blurred)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFullscreen = true
                        }
                    }
            } else if selectedImage != nil {
                Text("Processing...")
                    .frame(height: 300)
            }
        }
    }

    private var metricsSection: some View {
        VStack(spacing: 8) {
            Text("Performance")
                .font(.headline)

            HStack {
                Text("Processing Time:")
                    .font(.caption)
                Spacer()
                Text(String(format: "%.3f seconds", processingTime))
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Actions

    private func applyBlur() {
        guard let image = selectedImage, let engine = blurEngine else { return }

        isProcessing = true
        errorMessage = nil

        let startTime = Date()
        let configuration = BlurConfiguration(radius: blurIntensity)

        engine.blurAsync(image, configuration: configuration) { result in
            let endTime = Date()
            processingTime = endTime.timeIntervalSince(startTime)
            isProcessing = false

            switch result {
            case .success(let blurred):
                blurredImage = blurred
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let radius: Float
    @Binding var currentRadius: Float

    var body: some View {
        Button(action: { currentRadius = radius }) {
            Text(title)
                .font(.caption)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(currentRadius == radius ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(currentRadius == radius ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Fullscreen Image View

struct FullscreenImageView: View {
    let image: UIImage?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.scale.combined(with: .opacity))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isPresented = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BlurTestView()
}
