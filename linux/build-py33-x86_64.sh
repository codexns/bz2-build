#!/bin/bash

PYTHON_VERSION=3.3.5

set -e

# Figure out what directory this script is in
SCRIPT="$0"
if [[ $(readlink $SCRIPT) != "" ]]; then
    SCRIPT=$(dirname $SCRIPT)/$(readlink $SCRIPT)
fi
if [[ $0 = ${0%/*} ]]; then
    SCRIPT=$(pwd)/$0
fi
LINUX_DIR=$(cd ${SCRIPT%/*} && pwd -P)

if [[ $(uname -m) != 'x86_64' ]]; then
    echo "Unable to cross-compile Python and this machine is running the arch $(uname -m), not x86_64"
    exit 1
fi

DEPS_DIR="${LINUX_DIR}/deps"
BUILD_DIR="${LINUX_DIR}/py33-x86_64"
STAGING_DIR="$BUILD_DIR/staging"
BIN_DIR="$STAGING_DIR/bin"
OUT_DIR="$BUILD_DIR/../../out/py33_linux_x64"

export LDFLAGS="-Wl,-rpath='\$\$ORIGIN/' -Wl,-rpath=${STAGING_DIR}/lib -L${STAGING_DIR}/lib -L/usr/lib/x86_64-linux-gnu"
export CPPFLAGS="-I${STAGING_DIR}/include"

mkdir -p $DEPS_DIR
mkdir -p $BUILD_DIR
mkdir -p $STAGING_DIR
mkdir -p $OUT_DIR

PYTHON_DIR="${DEPS_DIR}/Python-$PYTHON_VERSION"
PYTHON_BUILD_DIR="${BUILD_DIR}/Python-$PYTHON_VERSION"

WGET_ERROR=0

download() {
    if (( ! $WGET_ERROR )); then
        # Ignore error with wget
        set +e
        wget "$1"
        # If wget is too old to support SNI
        if (( $? == 5 )); then
            WGET_ERROR=1
        fi
        set -e
    fi
    if (( $WGET_ERROR )); then
        curl -O "$1"
    fi
}

cd $LINUX_DIR

if [[ ! -e $PYTHON_DIR ]]; then
    cd $DEPS_DIR
    download "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz"
    tar xvfz Python-$PYTHON_VERSION.tgz
    rm Python-$PYTHON_VERSION.tgz
    cd $LINUX_DIR
fi

if [[ -e $PYTHON_BUILD_DIR ]]; then
    rm -R $PYTHON_BUILD_DIR
fi
cp -R $PYTHON_DIR $BUILD_DIR

cd $PYTHON_BUILD_DIR

./configure --prefix=$STAGING_DIR
make
make install

cp build/lib.linux-x86_64-3.3/_bz2.cpython-33m.so $OUT_DIR/

cd $LINUX_DIR
