#!/bin/bash

# Set project details
SCHEME="Little Fingers"
PROJECT="Little Fingers.xcodeproj"
CONFIGURATION="Release"
BUILD_DIR="build"

# Build the app
xcodebuild \
  -scheme "$SCHEME" \
  -project "$PROJECT" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$BUILD_DIR" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build