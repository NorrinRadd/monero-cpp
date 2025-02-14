#!/bin/bash

CURRENT_ARCH=`uname -m`
CUR_OS=`uname -s`

cd ./external/monero-project/ || exit 1
mkdir build/release
git submodule update --init --force || exit 1
HOST_NCORES=$(nproc 2>/dev/null || shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
if [[ $CUR_OS == "MINGW64_NT"* || $CUR_OS == "MSYS"* ]]; then
    # monero-project 
    bit=$(getconf LONG_BIT)
    if [ "$bit" == "64" ]; then
        make release-static-win64 -j$HOST_NCORES || exit 1
    else
        make release-static-win32 -j$HOST_NCORES || exit 1
    fi
    mv build/release ../../external-libs/aarch64/monero-project/

    # monero-cpp
    cd ../../
    # TODO: Fix the variabes on the next 3 lines.
    mkdir -p build/$CURRENT_ARCH &&
    cd build/$CURRENT_ARCH &&
    cmake -DARCH=$ARCH ../.. &&
    cmake --build . &&
    make -j$HOST_NCORES .

# Should linux be able to build a Windows build? 
elif [ $CUR_OS == "Darwin" ]; then
    # Build current architecture only.
    # monero-project
    make release-static -j$HOST_NCORES || exit 1
    cd ../..

    # monero-cpp
    VERSION="$CURRENT_ARCH-apple-$CUR_OS-macho"
    mkdir -p build && 
    cd build && 
    cmake -D MON_VERSION=$VERSION .. && 
    cmake --build . && 
    make -j$HOST_NCORES .

elif [ $CURRENT_ARCH == "${ARCH}" ] || [ -z "${ARCH}" ]; then
    # Running on Linux. Building current architecture only.

    # monero-project
    make release-static -j$HOST_NCORES || exit 1
    cd ../..

    # monero-cpp
    VERSION="$CURRENT_ARCH-linux-gnu"
    mkdir -p build && 
    cd build && 
    cmake -D MON_VERSION=$VERSION .. && 
    cmake --build . && 
    make -j$HOST_NCORES .
else
    # Running on Linux
    # pwd == monero-project
    rm -rf build/release/*
    if [ $CURRENT_ARCH == "${ARCH}" ] && [ -z "${TARGET}" ]; then
        VERSION="${ARCH}-$CUR_OS-gnu"
        # build monero-project, current arch only
        make release-static -j$HOST_NCORES || exit 1
        mkdir -p ../../external-libs/monero-$VERSION/
        mv build/release ../../external-libs/monero-$VERSION/

        # Build monero-cpp
        mkdir -p ../../build/$VERSION && cd ../../build/$VERSION &&
        cmake -D MON_VERSION=$VERSION ../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .

    elif [ "${TARGET}" == "Darwin" ]; then 
        # Build both monero-project

        # build monero-aarch64.
        # Make dependencies
        cd contrib/depends
        make HOST=aarch64-apple-darwin-macho -j$HOST_NCORES
        cd ../..

        mkdir -p build/release && cd build/release
        cmake -DCMAKE_TOOLCHAIN=../../contrib/depends/aarch64-apple-darwin-macho ../.. && make -j$HOST_NCORES
        mkdir -p ../../../../external-libs/monero-aarch64-apple-darwin-macho/
        cd ../.. && mv build/release ../../external-libs/monero-aarch64-apple-darwin-macho/
    
        # build monero-x64_64.
        # Make dependencies
        git reset --hard HEAD
        git clean -f
        cd contrib/depends
        make HOST=x86_64-apple-darwin-macho -j$HOST_NCORES
        cd ../..

        mkdir -p build/release && cd build/release
        cmake -DCMAKE_TOOLCHAIN=../../contrib/depends/x86_64-apple-darwin-macho ../.. && make -j$HOST_NCORES
        mkdir -p ../../external-libs/monero-x86_64-apple-darwin-macho/
        cd ../.. && mv build/release/ ../../external-libs/monero-x86-64-apple-darwin-macho/

        # Build monero-cpp
        cd ../../
        mkdir -p build/x86_64-apple-darwin-macho
        mkdir -p build/aarch64-apple-darwin-macho
        
        # x86_64
        cd build/x86_64-apple-darwin-macho && 
        cmake -D MON_VERSION=x86_64-apple-darwin-macho ../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
        
        # aarch64
        cd ../aarch64-apple-darwin-macho && 
        cmake -D MON_VERSION=aarch64-apple-darwin-macho ../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
        
        # lipo the two builds together
        cd ../..
        /usr/lib/llvm-18/bin/llvm-lipo -create -output build/libmonero-cpp-apple-darwin-macho.a build/x86_64-apple-darwin-macho/libmonero-cpp-x86_64-apple-darwin-macho.a build/aarch64-apple-darwin-macho/libmonero-cpp-aarch64-apple-darwin-macho.a
    else
        # An opposite arch was specified. Build it.
        VERSION="${ARCH}-$CUR_OS-gnu"

        # Make dependencies.
        cd contrib/depends
        make HOST=$VERSION -j$HOST_NCORES
        cd ../..

        # Build monero-project
        mkdir -p build/release && cd build/release
        cmake -DCMAKE_TOOLCHAIN=../../contrib/depends/$VERSION ../.. && make -j$HOST_NCORES
        mkdir -p ../../../../external-libs/monero-$VERSION/
        cd ../.. && mv build/release ../../external-libs/monero-$VERSION/

        # Build monero-cpp
        mkdir -p ../../build/$VERSION && cd ../../build/$VERSION &&
        cmake -D MON_VERSION=$VERSION ../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
    fi
fi


