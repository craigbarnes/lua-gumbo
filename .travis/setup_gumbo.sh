#!/bin/bash
#
# A script for setting up gumbo parser for travis-ci testing.
# 

GUMBO_VERSION=0.9.2

# bail out on any error
set -e

cd "$TRAVIS_BUILD_DIR"

wget \
    https://googletest.googlecode.com/files/gtest-1.6.0.zip
unzip \
    gtest-1.6.0.zip

wget \
    "https://github.com/google/gumbo-parser/archive/v${GUMBO_VERSION}.tar.gz" \
    -O gumbo-parser-${GUMBO_VERSION}.tar.gz
gunzip \
    -c gumbo-parser-${GUMBO_VERSION}.tar.gz \
| tar \
    xvf -

cd gumbo-parser-${GUMBO_VERSION}
ln -s ../gtest-1.6.0 gtest

./autogen.sh
./configure \
  --prefix=/usr

make
make check
sudo make install
