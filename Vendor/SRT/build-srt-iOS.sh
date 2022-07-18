#!/bin/bash

if which $(pwd)/srt >/dev/null; then
  echo ""
else
  git clone git@github.com:Haivision/srt.git
  pushd srt
  git checkout refs/tags/v1.4.1
  popd
fi

export IPHONEOS_DEPLOYMENT_TARGET=9.0
SDKVERSION=$(xcrun --sdk iphoneos --show-sdk-version)

srt() {
  IOS_OPENSSL=$(pwd)/OpenSSL/$1

  mkdir -p ./build/$2/$3
  pushd ./build/$2/$3
  ../../../srt/configure --cmake-prefix-path=$IOS_OPENSSL --ios-platform=$2 --ios-arch=$3 --cmake-toolchain-file=scripts/iOS.cmake --USE_OPENSSL_PC=off
  make
  install_name_tool -id "@executable_path/Frameworks/libsrt.1.4.1.dylib" libsrt.1.4.1.dylib
  popd
}

# compile
srt iphonesimulator SIMULATOR i386
srt iphonesimulator SIMULATOR64 x86_64
srt iphonesimulator SIMULATOR64 arm64
srt iphoneos OS armv7
srt iphoneos OS armv7s
srt iphoneos OS arm64

mkdir ./build/simulator
lipo -create ./build/SIMULATOR/i386/libsrt.a ./build/SIMULATOR64/arm64/libsrt.a ./build/SIMULATOR64/x86_64/libsrt.a -output ./build/simulator/libsrt.a
mkdir ./build/device
lipo -create ./build/OS/arm64/libsrt.a ./build/OS/armv7/libsrt.a ./build/OS/armv7s/libsrt.a -output ./build/device/libsrt.a

# make libsrt.xcframework
xcodebuild -create-xcframework \
    -library ./build/device/libsrt.a -headers Includes \
    -library ./build/simulator/libsrt.a -headers Includes \
    -output libsrt.xcframework

