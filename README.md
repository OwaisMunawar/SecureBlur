# SecureBlur

A lightweight iOS SDK that provides secure image blurring and biometric-gated decryption on-device.

## Overview

SecureBlur is designed for iOS applications that need to:
- Apply GPU-accelerated Gaussian blur to images
- Encrypt sensitive image data using Secure Enclave
- Require biometric authentication (Face ID/Touch ID) to decrypt and reveal images
- Securely revoke access to encrypted images

## Features

- **GPU-based Gaussian Blur**: High-performance image blurring using Metal Performance Shaders
- **Secure Enclave Integration**: Non-exportable encryption keys stored in device Secure Enclave
- **Biometric Authentication**: Face ID / Touch ID gated decryption (no passcode fallback)
- **AES-GCM Encryption**: Industry-standard encryption for image data
- **Revoke Functionality**: Securely invalidate keys and encrypted data
- **Clean API**: Minimal, developer-friendly public interface

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Device with Face ID or Touch ID capability

## Project Structure

```
SecureBlur/
├── Sources/
│   └── SecureBlur/
│       ├── Core/              # Blur engine and configuration
│       ├── Security/          # Crypto, keychain, biometrics
│       ├── Metal/             # Metal shaders (if needed)
│       ├── Models/            # Data models and errors
│       └── Utils/             # Helper utilities
├── Tests/
│   └── SecureBlurTests/       # Unit tests
├── Demo/
│   └── SecureBlurDemo/        # Example app
└── Package.swift              # Swift Package configuration
```

## Development Roadmap

### Milestone 1: Blur Core
- Metal/MPS Gaussian blur implementation
- Configurable blur intensity
- 4K image support with memory optimization

### Milestone 2: Crypto + Biometrics + Revoke
- Secure Enclave key generation
- AES-GCM encryption/decryption
- Face ID/Touch ID integration
- Key and ciphertext revocation

### Milestone 3: Demo App + Packaging
- Complete SwiftUI demo app
- .xcframework packaging
- CI/CD with GitHub Actions
- Comprehensive documentation

## Getting Started

### Installation

This project is currently in development. Once complete, it will be available as a Swift Package.

### Building

1. Clone the repository:
```bash
git clone <repository-url>
cd SecureBlur
```

2. Open in Xcode:
```bash
open Package.swift
```

3. Build the framework:
```bash
swift build
```

### Running Tests

```bash
swift test
```

## License

TBD

## Author

Owais Munawar - iOS Developer