#!/bin/bash

# SkaleKit Flutter Plugin - Native SDK Setup Script
# This script copies the native SDK files to the correct locations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKALEKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Setting up native SDKs for SkaleKit Flutter plugin..."

# iOS - Copy xcframework
IOS_SOURCE="$SKALEKIT_ROOT/ios/SkaleKit/Distribution/SkaleKit.xcframework"
IOS_DEST="$SCRIPT_DIR/ios/Frameworks"

if [ -d "$IOS_SOURCE" ]; then
    echo "Copying iOS xcframework..."
    mkdir -p "$IOS_DEST"
    rm -rf "$IOS_DEST/SkaleKit.xcframework"
    cp -R "$IOS_SOURCE" "$IOS_DEST/"
    echo "iOS xcframework copied successfully!"
else
    echo "Warning: iOS xcframework not found at $IOS_SOURCE"
fi

# Android - Copy AAR
ANDROID_SOURCE="$SKALEKIT_ROOT/android/SkaleKitAndroid/releases/skalekit-1.0.0.aar"
ANDROID_DEST="$SCRIPT_DIR/android/libs"

if [ -f "$ANDROID_SOURCE" ]; then
    echo "Copying Android AAR..."
    mkdir -p "$ANDROID_DEST"
    cp "$ANDROID_SOURCE" "$ANDROID_DEST/"
    echo "Android AAR copied successfully!"
else
    echo "Warning: Android AAR not found at $ANDROID_SOURCE"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Note: Make sure the native SDKs are in the following locations:"
echo "  - iOS: ios/Frameworks/SkaleKit.xcframework"
echo "  - Android: android/libs/skalekit-1.0.0.aar"
