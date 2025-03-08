#!/bin/bash

CURRENT_ARCH=`uname -m`
CUR_OS=`uname -s`

cd ./external/monero-project/ || exit 1
git submodule update --init --force || exit 1
HOST_NCORES=$(nproc 2>/dev/null || shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
if [[ $CUR_OS == "MINGW64_NT"* || $CUR_OS == "MSYS"* ]]; then
    # monero-project 
    bit=$(getconf LONG_BIT)
    mkdir -p build/release
    if [ "$bit" == "64" ]; then
        make release-static-win64 -j$HOST_NCORES || exit 1
    else
        make release-static-win32 -j$HOST_NCORES || exit 1
    fi
    mv build/release ../../external-libs/$CURRENT_ARCH/monero-project/

    # monero-cpp
    cd ../../
    mkdir -p build/$CURRENT_ARCH &&
    cd build/$CURRENT_ARCH &&
    cmake -DTARGET=$CUR_OS -DMON_VERSION=$CURRENT_ARCH ../.. &&
    cmake --build . &&
    make -j$HOST_NCORES .
    VERSION="${CURRENT_ARCH}-W${bit}-${CUR_OS}"
    mv libmonero-cpp* libmonero-cpp-$VERSION.dylib
    cp libmonero-cpp* ../..

elif [ $CUR_OS == "Darwin" ]; then

    VERSION="${CURRENT_ARCH}-apple-${CUR_OS}"

    # Build current architecture only.
    # monero-project
    printf "\nBuilding native release static version of monero-project for ${CURRENT_ARCH}\n"
    make release-static -j$HOST_NCORES || exit 1
    rm -rf ../../external-libs/$VERSION/monero-project
    mkdir -p ../../external-libs/$VERSION/monero-project/ &&
    mv build/release ../../external-libs/$VERSION/monero-project/
    cd ../..

    # monero-cpp
    printf "\nBuilding native Monero-cpp for ${CURRENT_ARCH}\n"
    rm -rf build/$CURRENT_ARCH/release && 
    mkdir -p build/$CURRENT_ARCH/release && 
    cd build/$CURRENT_ARCH/release && 
    cmake -DTARGET=Darwin -D MON_VERSION=$VERSION ../../.. && 
    cmake --build . && 
    make -j$HOST_NCORES .
    mv libmonero-cpp* libmonero-cpp-$VERSION.dylib
    cp libmonero-cpp* ../..

else
    # Running on Linux
    # "OS" will be used as if it is called "WRAPPER"

    rm -rf build
    BUILD_BOTH_ARCHS=0
    OS=""
    VENDOR=""

    if [ "${TARGET}" == "darwin" ]; then
        OS="darwin11"
        SYSTEM_NAME="Darwin"
        VENDOR="apple"
        if [ -z "${ARCH}" ]; then
            BUILD_BOTH_ARCHS=1
        fi
    elif [ "${TARGET}" == "MSYS" ] || [ "${TARGET}" == "MINGW64_NT" ]; then
        SYSTEM_NAME="Windows"
        OS="mingw32"
        VENDOR="w64"
    else
        SYSTEM_NAME="Linux"
        OS="gnu"
        VENDOR="linux"
    fi

    CPU=""
    if [ -n "${ARCH}" ]; then
        CPU="${ARCH}"
    else
        CPU=$CURRENT_ARCH 
    fi

    if [ $BUILD_BOTH_ARCHS == 1 ]; then
        # The target is darwin.
        printf "\nBuilding both Darwin architectures as a fat library\n"

        ARM64_TOOLCHAIN="contrib/depends/aarch64-apple-darwin11/share/toolchain.cmake"
        X86_64_TOOLCHAIN="contrib/depends/x86_64-apple-darwin11/share/toolchain.cmake"

        if [ -z $SKIP_MP ]; then
            printf "\nBuilding compilation dependencies for aarch64 Darwin\n"
            CUR_VERSION="aarch64-apple-darwin11" 
            cd contrib/depends &&
            make HOST=$CUR_VERSION -j$HOST_NCORES &&
            echo \
            "set(FRAMEWORK_DIR \"contrib/depends/$CUR_VERSION/native/SDK/System/Library/Frameworks\")" \
            >> ../../$ARM64_TOOLCHAIN &&
            cd ../..

            # build monero-project
            printf "\nBuilding monero-project for aarch64 Darwin\n"
            rm -rf build &&
            mkdir -p build/release && cd build/release &&
            cmake -j$HOST_NCORES -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../$ARM64_TOOLCHAIN ../.. && make -j$HOST_NCORES &&
            rm -rf ../../../../external-libs/$CUR_VERSION/monero-project
            mkdir -p ../../../../external-libs/$CUR_VERSION/monero-project/ &&
            cd ../.. && mv build/release ../../external-libs/$CUR_VERSION/monero-project/
    
            # build monero-x64_64
            # Make dependencies
            printf "\nBuilding compilation dependencies for x86_64 Darwin\n"
            CUR_VERSION="x86_64-apple-darwin11" 
            cd contrib/depends &&
            make HOST=$CUR_VERSION -j$HOST_NCORES &&
            echo \
            "set(FRAMEWORK_DIR \"contrib/depends/$CUR_VERSION/native/SDK/System/Library/Frameworks\")" \
            >> ../../$X86_64_TOOLCHAIN &&
            cd ../..

            # build monero-project
            printf "\nBuilding monero-project for x86_64 Darwin\n"
            mkdir -p build/release && cd build/release &&
            cmake -j$HOST_NCORES -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../$X86_64_TOOLCHAIN ../.. &&
            make -j$HOST_NCORES &&
            rm -rf ../../../../external-libs/$CUR_VERSION/monero-project
            mkdir -p ../../../../external-libs/$CUR_VERSION/monero-project/
            cd ../.. && mv build/release ../../external-libs/$CUR_VERSION/monero-project/
        fi

        # Build monero-cpp x86_64
        printf "\nBuilding x86_64 monero-cpp for Darwin\n"
        cd ../../ &&
        rm -rf build/x86_64-apple-darwin11/release &&
        rm -rf build/aarch64-apple-darwin11/release &&
        rm -rf build/darwin &&
        mkdir -p build/x86_64-apple-darwin11/release &&
        mkdir -p build/aarch64-apple-darwin11/release &&
        mkdir -p build/darwin/release
        
        cd build/x86_64-apple-darwin11/release && 
        cmake -j$HOST_NCORES -DTARGET=Darwin -D MON_VERSION=x86_64-apple-darwin11 -D CMAKE_TOOLCHAIN_FILE=../../../external/monero-project/$X86_64_TOOLCHAIN ../../.. &&
        make -j$HOST_NCORES
        
        # Build monero-cpp arm64
        printf "\nBuilding aarch64 monero-cpp for Darwin\n"
        cd ../../aarch64-apple-darwin11/release && 
        cmake -j$HOST_NCORES -DTARGET=Darwin -D MON_VERSION=aarch64-apple-darwin11 -D CMAKE_TOOLCHAIN_FILE=../../../external/monero-project/$ARM64_TOOLCHAIN ../../.. &&
        make -j$HOST_NCORES
        
        # lipo the two builds together
        cd ../../..
        ./external/monero-project/contrib/depends/${CURRENT_ARCH}-apple-darwin11/native/bin/${CURRENT_ARCH}-apple-darwin11-lipo -create -output build/darwin/release/libmonero-cpp.dylib build/x86_64-apple-darwin11/release/libmonero-cpp.dylib build/aarch64-apple-darwin11/release/libmonero-cpp.dylib

    else
        # Building 1 architecture for any platform

        # "OS" is used as if it is named "WRAPPER"
        VERSION="${CPU}-${VENDOR}-${OS}" && 
        printf "\nBuilding for ${VERSION}\n"

        # Make dependencies.
        if [ -z $SKIP_MP ]; then
            printf "\nBuilding compilation dependencies\n"
            cd contrib/depends &&
            make HOST=$VERSION -j$HOST_NCORES &&
            if [ $OS == "darwin11" ]; then
                echo \
                "set(FRAMEWORK_DIR \"contrib/depends/$VERSION/native/SDK/System/Library/Frameworks\")" \
                >> $VERSION/share/toolchain.cmake
            fi
            cd ../..

            # Build monero-project
            printf "\nBuilding monero-project for ${VERSION}\n"
            mkdir -p build/release && cd build/release &&
            cmake -j$HOST_NCORES -D STATIC=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=../../contrib/depends/$VERSION/share/toolchain.cmake ../.. &&
            make -j$HOST_NCORES &&
            rm -rf ../../../../external-libs/$VERSION/monero-project
            mkdir -p ../../../../external-libs/$VERSION/monero-project/ &&
            cd ../.. && mv build/release ../../external-libs/$VERSION/monero-project/
        fi

        # Build monero-cpp
        printf "\nBuilding monero-cpp for ${VERSION}\n"
        rm -rf ../../build/$VERSION/release &&
        mkdir -p ../../build/$VERSION/release && 
        cd ../../build/$VERSION/release &&
        cmake -j$HOST_NCORES -DTARGET=$SYSTEM_NAME -D MON_VERSION=$VERSION -D CMAKE_TOOLCHAIN_FILE=../../../external/monero-project/contrib/depends/$VERSION/share/toolchain.cmake ../../.. && 
        # cmake -j$HOST_NCORES -D MON_VERSION=$VERSION ../../.. && 
        make -j$HOST_NCORES
        mv libmonero-cpp* libmonero-cpp-$VERSION.dylib
        cp libmonero-cpp* ../..
    fi 
fi

