#!/bin/bash

BUILD_DIR=$(dirname "$0")/Frameworks
OUTPUT_DIR=$( mktemp -d )
set -x

# iOS
xcrun xcodebuild build -project SRTHaishinKit.xcodeproj -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES -scheme "SRTHaishinKit iOS" -destination 'generic/platform=iOS' -derivedDataPath "${OUTPUT_DIR}"
# Remove old xcframework
rm -rf $BUILD_DIR/SRTHaishinKit.xcframework

# Create xcframework
xcodebuild -create-xcframework \
-framework "${OUTPUT_DIR}/Build/Products/Release-iphoneos/SRTHaishinKit.framework" \
-output "${BUILD_DIR}/SRTHaishinKit.xcframework"

rm -rf $OUTPUT_DIR
