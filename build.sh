#!/usr/bin/env bash

set -e

TAPI_REPOSITORY=1100.0.11
TAPI_VERSION=11.0.0 # ?!

pushd "${0%/*}" &>/dev/null
source tools/tools.sh

rm -rf build
mkdir build

pushd build &>/dev/null

CMAKE_EXTRA_ARGS=""
CMAKE_GENERATOR=""
HOST_TRIPLE=""

case "$OSTYPE" in
  darwin*)  CMAKE_GENERATOR=-G"Xcode" ;;
  linux*)   CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  bsd*)     CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  msys*)
            if [ "$(getconf LONG_BIT)" == "64" ]; then
              HOST_TRIPLE=x86_64-pc-mingw64
            else
              HOST_TRIPLE=x86_64-pc-mingw32
            fi
            CMAKE_GENERATOR=-G"MSYS Makefiles"
  ;;
esac

if [ "$(which ninja)" != "" ]; then
  CMAKE_GENERATOR=-G"Ninja"
  NINJA=1
fi

if [ -z "$INSTALLPREFIX" ]; then
  INSTALLPREFIX="./localinstall/"
fi

INCLUDE_FIX=""
INCLUDE_FIX+="-I $PWD/../src/llvm/projects/clang/include "
INCLUDE_FIX+="-I $PWD/projects/clang/include "
INCLUDE_FIX+="-Wno-error=deprecated-copy "
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
INCLUDE_FIX+="-Wno-error=range-loop-construct "
INCLUDE_FIX+="-Wno-error=unused-function "
INCLUDE_FIX+="-Wno-error=switch "
INCLUDE_FIX+="-Wno-error=return-type "
INCLUDE_FIX+="-Wno-error=unused-variable "
INCLUDE_FIX+="-Wno-error=uninitialized "
INCLUDE_FIX+="-Wno-error=deprecated-copy "
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
INCLUDE_FIX+="-Wno-error=range-loop-construct "
# INCLUDE_FIX+="_GNU_SOURCE=1"

echo -n $INSTALLPREFIX > INSTALLPREFIX

cmake ../src/llvm \
 -DCMAKE_C_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_CXX_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_C_COMPILER=clang \
 -DCMAKE_CXX_COMPILER=clang++ \
 -DLLVM_INCLUDE_TESTS=OFF \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -DTAPI_REPOSITORY_STRING=$TAPI_REPOSITORY \
 -DTAPI_FULL_VERSION=$TAPI_VERSION \
 -DLLVM_INFERRED_HOST_TRIPLE=$HOST_TRIPLE \
 -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
 -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;PowerPC;X86" \
 "$CMAKE_GENERATOR" \
 $CMAKE_EXTRA_ARGS

echo ""
echo "## Building clangBasic ##"
echo ""

cmake --build . --target clangBasic

echo ""
echo "## Building libtapi ##"
echo ""

cmake --build . --target libtapi

echo ""
echo "## Installing libtapi ##"
echo ""

cmake --build . --target install-libtapi
cmake --build . --target install-tapi-headers

popd &>/dev/null
popd &>/dev/null
