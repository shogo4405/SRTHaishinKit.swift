#!/bin/bash

if which $(pwd)/srt >/dev/null; then
  echo ""
else
  git clone "git://github.com/Haivision/srt.git"
  pushd srt
  git checkout refs/tags/v1.4.1
  popd
fi

export IPHONEOS_DEPLOYMENT_TARGET=8.0
SDKVERSION=$(xcrun --sdk iphoneos --show-sdk-version)

srt() {
  IOS_OPENSSL=$(pwd)/OpenSSL-for-iPhone/bin/$1${SDKVERSION}-$3.sdk

  mkdir -p ./build/iOS/$3
  pushd ./build/iOS/$3
  ../../../srt/configure --cmake-prefix-path=$IOS_OPENSSL --ios-platform=$2 --ios-arch=$3 --cmake-toolchain-file=scripts/iOS.cmake --USE_OPENSSL_PC=off
  make
  install_name_tool -id "@executable_path/Frameworks/libsrt.1.4.1.dylib" libsrt.1.4.1.dylib
  popd
}

# compile
#srt iPhoneSimulator SIMULATOR i386
srt iPhoneSimulator SIMULATOR64 x86_64
#srt iPhoneOS OS armv7
#srt iPhoneOS OS armv7s
srt iPhoneOS OS arm64

# lipo
lipo -output libsrt-iOS.a -create ./build/iOS/x86_64/libsrt.a ./build/iOS/arm64/libsrt.a

