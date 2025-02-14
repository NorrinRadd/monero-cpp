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
    mv build/release ../../external-libs/arm64/monero-project/

    # monero-cpp
    cd ../../
    # TODO: Fix the variabes on the next 3 lines.
    mkdir -p build/$CURRENT_ARCH &&
    cd build/$CURRENT_ARCH &&
    cmake -DARCH=$ARCH ../.. &&
    cmake --build . &&
    make -j$HOST_NCORES .

elif [ $CUR_OS == "Darwin" ]; then

    # Add the ability to build the opposite ARCH here. 

    # Build current architecture only.
    # monero-project
    make release-static -j$HOST_NCORES || exit 1
    cd ../..

    # monero-cpp
    VERSION="${CURRENT_ARCH}-apple-${CUR_OS}"
    mkdir -p build && 
    cd build && 
    cmake -D MON_VERSION=$VERSION .. && 
    cmake --build . && 
    make -j$HOST_NCORES .

else
    # Running on Linux
    # "OS" will be used as if it is called "WRAPPER"

    rm -rf build
    BUILD_BOTH_ARCHS=0
    OS=""
    VENDOR=""

    if [ "${TARGET}" == "darwin" ]; then
        OS="darwin"
        VENDOR="apple"
        if [ -z "${ARCH}" ]; then
            BUILD_BOTH_ARCHS=1
        fi
    elif [ "${TARGET}" == "MSYS" ] || [ "${TARGET}" == "MINGW64_NT" ]; then
        OS="mingw32"
        VENDOR="w64"
    else
        OS="gnu"
        VENDOR="apple"
    fi

    CPU=""
    if [ -z "${ARCH}" ]; then
        CPU=$CURRENT_ARCH 
    else
        CPU="${ARCH}"
    fi

    if [ BUILD_BOTH_ARCHS ]; then
        # The target is darwin.

        if [ -z $SKIP_MD ]; then
        # build monero-arm64.
        # Make dependencies
        CUR_VERSION="arm64-apple-darwin" 
        ARM64_TOOLCHAIN="contrib/depends/${CUR_VERSION}/share/toolchain.cmake"
        cd contrib/depends
        make HOST=$CUR_VERSION -j$HOST_NCORES
        cd ../..

        # build monero-project
        rm -rf build
        mkdir -p build/release && cd build/release
        cmake -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../$ARM64_TOOLCHAIN ../.. && make -j$HOST_NCORES
        mkdir -p ../../../../external-libs/$CUR_VERSION/monero-project/
        cd ../.. && mv build/release ../../external-libs/$CUR_VERSION/monero-project/
    
        # build monero-x64_64.
        # Make dependencies
        CUR_VERSION="x86_64-apple-darwin" 
        X86_64_TOOLCHAIN="contrib/depends/${CUR_VERSION}/share/toolchain.cmake"
        cd contrib/depends
        make HOST=$CUR_VERSION -j$HOST_NCORES
        cd ../..

        # build monerod
        mkdir -p build/release && cd build/release
        cmake -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../$X86_64_TOOLCHAIN ../.. && make -j$HOST_NCORES
        mkdir -p ../../../../external-libs/$CUR_VERSION/monero-project/
        cd ../.. && mv build/release ../../external-libs/$CUR_VERSION/monero-project/
        
        fi

        # Build monero-cpp x86_64
        cd ../../
        mkdir -p build/x86_64-apple-darwin/release
        mkdir -p build/arm64-apple-darwin/release
        
        cd build/x86_64-apple-darwin/release && 
        cmake -D MON_VERSION=x86_64-apple-darwin -D CMAKE_TOOLCHAIN_FILE=../../../external/monero-project/$X86_64_TOOLCHAIN ../../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
        
        # Build monero-cpp arm64
        cd ../../arm64-apple-darwin/release && 
        cmake -D MON_VERSION=arm64-apple-darwin -D CMAKE_TOOLCHAIN_FILE=../../../external/monero-project/$ARM64_TOOLCHAIN ../../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
        
        # lipo the two builds together
        cd ../../..
        /usr/lib/llvm-18/bin/llvm-lipo -create -output build/libmonero-cpp-apple-darwin.a build/x86_64-apple-darwin/release/libmonero-cpp-x86_64-apple-darwin.a build/arm64-apple-darwin/release/libmonero-cpp-arm64-apple-darwin.a

    else
        # Building 1 architecture.

        # "OS" is used as if it is named "WRAPPER"
        VERSION="${CPU}-${VENDOR}-${OS}"

        # Make dependencies.
        cd contrib/depends
        make HOST=$VERSION -j$HOST_NCORES
        cd ../..

        # Build monero-project
        mkdir -p build/release && cd build/release
        cmake -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../contrib/depends/$VERSION/share/toolchain.cmake ../.. && make -j$HOST_NCORES
        mkdir -p ../../../../external-libs/monero-$VERSION/
        cd ../.. && mv build/release ../../external-libs/monero-$VERSION/

        # Build monero-cpp
        mkdir -p ../../build/$VERSION && cd ../../build/$VERSION &&
        cmake -D MON_VERSION=$VERSION ../.. && 
        cmake --build . && 
        make -j$HOST_NCORES .
    fi
fi


