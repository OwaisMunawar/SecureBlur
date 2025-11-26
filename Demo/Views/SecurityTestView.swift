//
//  SecurityTestView.swift
//  SecureBlurDemo
//
//  Test harness for encryption, decryption, and revoke functionality
//

import SwiftUI
import PhotosUI
import SecureBlur

struct SecurityTestView: View {

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var blurredImage: UIImage?
    @State private var encryptedImage: EncryptedImage?
    @State private var decryptedImage: UIImage?

    @State private var blurIntensity: Float = BlurConfiguration.defaultRadius
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var showFullscreen = false
    @State private var fullscreenImage: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var processingTime: TimeInterval = 0

    // MARK: - Properties

    private let blurEngine: BlurEngine?
    private let cryptoManager: CryptoManager
    private let biometricManager: BiometricManager

    // MARK: - Initialization

    init() {
        self.blurEngine = try? BlurEngine()
        self.cryptoManager = CryptoManager()
        self.biometricManager = BiometricManager()
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

                        // Blur Preview
                        if let blurred = blurredImage {
                            imagePreviewSection(image: blurred, title: "Blurred Image")
                        }

                        // Security Operations
                        securityOperationsSection

                        // Encrypted Image Info
                        if let encrypted = encryptedImage {
                            encryptedImageInfoSection(encrypted: encrypted)
                        }

                        // Decrypted Image Preview
                        if let decrypted = decryptedImage {
                            imagePreviewSection(image: decrypted, title: "Decrypted Image")
                        }

                        // Performance Metrics
                        if processingTime > 0 {
                            metricsSection
                        }
                    }

                    // Messages
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let success = successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Security Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                if let image = fullscreenImage {
                    FullscreenImageView(image: image, isPresented: $showFullscreen)
                }
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    resetState()
                    applyBlur()
                }
            }
        }
    }

    // MARK: - View Components

    private var imageSelectionSection: some View {
        Button(action: { showImagePicker = true }) {
            Label("Select Image", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
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

    private func imagePreviewSection(image: UIImage, title: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            if isProcessing {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 300)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .onTapGesture {
                        fullscreenImage = image
                        showFullscreen = true
                    }
            }
        }
    }

    private var securityOperationsSection: some View {
        VStack(spacing: 12) {
            Text("Security Operations")
                .font(.headline)

            HStack(spacing: 12) {
                Button(action: encryptImage) {
                    Label("Encrypt", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(encryptedImage == nil ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(blurredImage == nil || encryptedImage != nil)

                Button(action: decryptImage) {
                    Label("Decrypt", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(encryptedImage != nil && decryptedImage == nil ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(encryptedImage == nil || decryptedImage != nil)
            }

            Button(action: revokeAccess) {
                Label("Revoke Access", systemImage: "xmark.shield.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(encryptedImage != nil && !(encryptedImage?.isRevoked ?? true) ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(encryptedImage == nil || (encryptedImage?.isRevoked ?? true))
        }
    }

    private func encryptedImageInfoSection(encrypted: EncryptedImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Encrypted Image Info")
                .font(.headline)

            Group {
                HStack {
                    Text("ID:")
                        .font(.caption.bold())
                    Text(encrypted.id.uuidString.prefix(8) + "...")
                        .font(.caption)
                }

                HStack {
                    Text("Size:")
                        .font(.caption.bold())
                    Text(encrypted.encryptedSizeFormatted)
                        .font(.caption)
                }

                HStack {
                    Text("Dimensions:")
                        .font(.caption.bold())
                    Text("\(encrypted.dimensions.width) × \(encrypted.dimensions.height)")
                        .font(.caption)
                }

                HStack {
                    Text("Status:")
                        .font(.caption.bold())
                    Text(encrypted.isRevoked ? "REVOKED" : "Active")
                        .font(.caption)
                        .foregroundColor(encrypted.isRevoked ? .red : .green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
        successMessage = nil

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

    private func encryptImage() {
        guard let image = blurredImage else { return }

        isProcessing = true
        errorMessage = nil
        successMessage = nil

        let startTime = Date()

        cryptoManager.encryptAsync(image) { result in
            let endTime = Date()
            processingTime = endTime.timeIntervalSince(startTime)
            isProcessing = false

            switch result {
            case .success(let encrypted):
                encryptedImage = encrypted
                successMessage = "Image encrypted successfully"
            case .failure(let error):
                errorMessage = "Encryption failed: \(error.localizedDescription)"
            }
        }
    }

    private func decryptImage() {
        guard var encrypted = encryptedImage else { return }

        // Check biometric availability
        guard biometricManager.isBiometricAvailable() else {
            errorMessage = "Biometric authentication not available"
            return
        }

        isProcessing = true
        errorMessage = nil
        successMessage = nil

        // Authenticate with biometrics
        biometricManager.authenticate(reason: "Authenticate to decrypt image") { authResult in
            switch authResult {
            case .success:
                // Proceed with decryption
                let startTime = Date()

                cryptoManager.decryptAsync(encrypted) { decryptResult in
                    let endTime = Date()
                    processingTime = endTime.timeIntervalSince(startTime)
                    isProcessing = false

                    switch decryptResult {
                    case .success(let decrypted):
                        decryptedImage = decrypted
                        successMessage = "Image decrypted successfully"
                    case .failure(let error):
                        errorMessage = "Decryption failed: \(error.localizedDescription)"
                    }
                }

            case .failure(let error):
                isProcessing = false
                errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
    }

    private func revokeAccess() {
        guard var encrypted = encryptedImage else { return }

        isProcessing = true
        errorMessage = nil
        successMessage = nil

        do {
            try cryptoManager.revoke(&encrypted)
            encryptedImage = encrypted
            successMessage = "Access revoked successfully"
            isProcessing = false
        } catch {
            isProcessing = false
            errorMessage = "Revoke failed: \(error.localizedDescription)"
        }
    }

    private func resetState() {
        blurredImage = nil
        encryptedImage = nil
        decryptedImage = nil
        errorMessage = nil
        successMessage = nil
        processingTime = 0
    }
}

// MARK: - Preview

#Preview {
    SecurityTestView()
}
