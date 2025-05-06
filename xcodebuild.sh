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
  build
