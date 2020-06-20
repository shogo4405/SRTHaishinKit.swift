#!/bin/bash

SDKVERSION=$(xcrun --sdk iphoneos --show-sdk-version)

if which $(pwd)/OpenSSL-for-iPhone >/dev/null; then
  echo ""
else
  git clone "git://github.com/x2on/OpenSSL-for-iPhone.git"
fi

pushd OpenSSL-for-iPhone
./build-libssl.sh --targets="ios-sim-cross-x86_64 ios64-cross-arm64"
popd
