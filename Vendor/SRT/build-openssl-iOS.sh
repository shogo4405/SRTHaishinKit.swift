#!/bin/bash

SDKVERSION=$(xcrun --sdk iphoneos --show-sdk-version)

if which $(pwd)/OpenSSL-for-iPhone >/dev/null; then
  echo ""
else
  git clone "git@github.com:x2on/OpenSSL-for-iPhone.git"
fi

pushd OpenSSL-for-iPhone
./build-libssl.sh --archs="x86_64 i386 arm64 armv7s armv7"
popd
