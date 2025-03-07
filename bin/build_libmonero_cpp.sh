#!/bin/sh

# build monero-project dependencies
cd ./external/monero-project/ || exit 1
git submodule update --init --force || exit 1
HOST_NCORES=$(nproc 2>/dev/null || shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
if [[ $(uname -s) == "MINGW64_NT"* || $(uname -s) == "MSYS"* ]]; then
    bit=$(getconf LONG_BIT)
    if [ "$bit" == "64" ]; then
        make release-static-win64 -j$HOST_NCORES || exit 1
    else
        make release-static-win32 -j$HOST_NCORES || exit 1
    fi
else
    # OS is not windows
    make release-static -j$HOST_NCORES || exit 1
fi
cd ../../

# build libmonero-cpp shared library
mkdir -p build && 
cd build && 
cmake .. && 
cmake --build . && 
make .