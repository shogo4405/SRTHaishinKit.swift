#!/bin/bash

if which $(pwd)/OpenSSL >/dev/null; then
  echo ""
else
  git clone git@github.com:krzyzanowskim/OpenSSL.git
fi

pushd OpenSSL
make	
popd	


