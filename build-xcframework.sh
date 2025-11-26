#!/bin/bash

# SecureBlur XCFramework Build Script
# Builds universal XCFramework for iOS devices and simulators

set -e  # Exit on error

# Configuration
FRAMEWORK_NAME="SecureBlur"
SCHEME_NAME="SecureBlur"
OUTPUT_DIR="build"
XCFRAMEWORK_PATH="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# Derived data paths
DERIVED_DATA_PATH="${OUTPUT_DIR}/DerivedData"
ARCHIVE_PATH_IOS="${OUTPUT_DIR}/archives/ios.xcarchive"
ARCHIVE_PATH_SIMULATOR="${OUTPUT_DIR}/archives/ios-simulator.xcarchive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SecureBlur XCFramework Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Clean previous build
echo -e "${BLUE}Cleaning previous build...${NC}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/archives"

# Build for iOS devices (arm64)
echo -e "${BLUE}Building for iOS devices (arm64)...${NC}"
xcodebuild archive \
    -scheme "${SCHEME_NAME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${ARCHIVE_PATH_IOS}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | xcbeautify || cat

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build for iOS devices${NC}"
    exit 1
fi

# Build for iOS Simulator (arm64 + x86_64)
echo -e "${BLUE}Building for iOS Simulator (arm64, x86_64)...${NC}"
xcodebuild archive \
    -scheme "${SCHEME_NAME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${ARCHIVE_PATH_SIMULATOR}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | xcbeautify || cat

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build for iOS Simulator${NC}"
    exit 1
fi

# Create XCFramework
echo -e "${BLUE}Creating XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "${ARCHIVE_PATH_IOS}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${ARCHIVE_PATH_SIMULATOR}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${XCFRAMEWORK_PATH}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create XCFramework${NC}"
    exit 1
fi

# Verify the XCFramework
echo -e "${BLUE}Verifying XCFramework...${NC}"
if [ ! -d "${XCFRAMEWORK_PATH}" ]; then
    echo -e "${RED}XCFramework not found at ${XCFRAMEWORK_PATH}${NC}"
    exit 1
fi

# Display info
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "XCFramework location: ${XCFRAMEWORK_PATH}"
echo ""
echo "Supported platforms:"
echo "  - iOS devices (arm64)"
echo "  - iOS Simulator (arm64, x86_64)"
echo ""

# Show size
XCFRAMEWORK_SIZE=$(du -sh "${XCFRAMEWORK_PATH}" | cut -f1)
echo -e "Size: ${XCFRAMEWORK_SIZE}"
echo ""

# Show architectures
echo "Architectures:"
find "${XCFRAMEWORK_PATH}" -name "${FRAMEWORK_NAME}" -type f | while read framework_binary; do
    echo "  $(file "$framework_binary" | sed 's/.*://')"
done
echo ""

# Create zip for distribution
echo -e "${BLUE}Creating distribution zip...${NC}"
cd "${OUTPUT_DIR}"
zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework" > /dev/null
cd ..

ZIP_SIZE=$(du -sh "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip" | cut -f1)
echo -e "${GREEN}Distribution zip created: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip (${ZIP_SIZE})${NC}"
echo ""

echo -e "${GREEN}Done!${NC}"
