#!/bin/bash

if which $(pwd)/OpenSSL-for-iPhone >/dev/null; then
  echo ""
else
  git clone "git@github.com:x2on/OpenSSL-for-iPhone.git"
fi

pushd OpenSSL-for-iPhone
./build-libssl.sh
popd
