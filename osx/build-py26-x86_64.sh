#!/bin/bash

PYTHON_VERSION=2.6.9

set -e

# Figure out what directory this script is in
SCRIPT="$0"
if [[ $(readlink $SCRIPT) != "" ]]; then
    SCRIPT=$(dirname $SCRIPT)/$(readlink $SCRIPT)
fi
if [[ $0 = ${0%/*} ]]; then
    SCRIPT=$(pwd)/$0
fi
OSX_DIR=$(cd ${SCRIPT%/*} && pwd -P)

DEPS_DIR="${OSX_DIR}/deps"
BUILD_DIR="${OSX_DIR}/py26-x86_64"
STAGING_DIR="$BUILD_DIR/staging"
BIN_DIR="$STAGING_DIR/bin"
OUT_DIR="$BUILD_DIR/../../out/py26_osx_x64"

export CPPFLAGS="-I${STAGING_DIR}/include"
# The macosx-version-min flags remove the dependency on libgcc_s.1.dylib
export CFLAGS="-arch x86_64 -mmacosx-version-min=10.6"
export LDFLAGS="-Wl,-rpath -Wl,@loader_path -Wl,-rpath -Wl,${STAGING_DIR}/lib -arch x86_64 -mmacosx-version-min=10.6 -L${STAGING_DIR}/lib"

mkdir -p $DEPS_DIR
mkdir -p $BUILD_DIR
mkdir -p $STAGING_DIR

PYTHON_DIR="${DEPS_DIR}/Python-$PYTHON_VERSION"
PYTHON_BUILD_DIR="${BUILD_DIR}/Python-$PYTHON_VERSION"


cd $OSX_DIR


if [[ ! -e $PYTHON_DIR ]]; then
    cd $DEPS_DIR
    curl -O --location "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz"
    tar xvfz Python-$PYTHON_VERSION.tgz
    rm Python-$PYTHON_VERSION.tgz
    cd ..
fi

if [[ -e $PYTHON_BUILD_DIR ]]; then
    rm -R $PYTHON_BUILD_DIR
fi
cp -R $PYTHON_DIR $BUILD_DIR

cd $PYTHON_BUILD_DIR

./configure --prefix=$STAGING_DIR
make
make install

cp ./build/lib.macosx-10.4-x86_64-2.6/bz2.so $OUT_DIR/

cd $OSX_DIR
