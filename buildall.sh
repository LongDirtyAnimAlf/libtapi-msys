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
  cygwin*)  CMAKE_GENERATOR=-G"Unix Makefiles" ;;
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
# INCLUDE_FIX+="-Wno-error=deprecated-copy "
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
# INCLUDE_FIX+="-Wno-error=range-loop-construct "
INCLUDE_FIX+="-Wno-error=unused-function "
INCLUDE_FIX+="-Wno-error=switch "
INCLUDE_FIX+="-Wno-error=return-type "
INCLUDE_FIX+="-Wno-error=unused-variable "
INCLUDE_FIX+="-Wno-error=uninitialized "
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
# INCLUDE_FIX+="_GNU_SOURCE=1"

echo -n $INSTALLPREFIX > INSTALLPREFIX

cmake ../src/llvm \
 -DCMAKE_C_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_CXX_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_C_COMPILER=clang \
 -DCMAKE_CXX_COMPILER=clang++ \
 -DLLVM_INCLUDE_TESTS=OFF \
 -DLLVM_INCLUDE_TOOLS=ON \
 -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON \
 -DLLVM_INSTALL_CCTOOLS_SYMLINKS=ON \
 -DLLVM_ENABLE_TERMINFO=OFF \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -DTAPI_REPOSITORY_STRING=$TAPI_REPOSITORY \
 -DTAPI_FULL_VERSION=$TAPI_VERSION \
 -DLLVM_INFERRED_HOST_TRIPLE=$HOST_TRIPLE \
 -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
 -DLLVM_TOOLCHAIN_TOOLS="llvm-ar;llvm-ranlib;llvm-objdump;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-addr2line" \
 -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;PowerPC;X86" \
 "$CMAKE_GENERATOR" \
 $CMAKE_EXTRA_ARGS

# echo ""
# echo "## Building llvm-tools ##"
# echo ""

# cmake --build . --target dsymutil -- -j 4
# cmake --build . --target llvm-ar -- -j 4
# cmake --build . --target llvm-nm -- -j 4
# cmake --build . --target llvm-objcopy -- -j 4
# cmake --build . --target llvm-objdump -- -j 4
# cmake --build . --target llvm-strip -- -j 4

echo ""
echo "## Building clang ##"
echo ""

cmake --build . --target clang -j 4


# echo ""
# echo "## Building clangBasic ##"
# echo ""

# cmake --build . --target clangBasic -j 4

echo ""
echo "## Building libtapi ##"
echo ""

cmake --build . --target libtapi -j 4

echo ""
echo "## Installing all ##"
echo ""

cmake --build . --target install-libtapi
cmake --build . --target install-tapi-headers
cmake --build . --target install-llvm-ar
cmake --build . --target install-clang
cmake --build . --target install-dsymutil
cmake --build . --target install-llvm-ar
cmake --build . --target install-llvm-nm
cmake --build . --target install-llvm-objcopy
cmake --build . --target install-llvm-objdump
cmake --build . --target install-llvm-strip

popd &>/dev/null
popd &>/dev/null
