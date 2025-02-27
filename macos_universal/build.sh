#!/bin/bash
HOST_NCORES=$(nproc 2>/dev/null || shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
cd .. && 
cd external/monero-project &&
make -jHOST_NCORES depends target=aarch64-apple-darwin11 &&
make -jHOST_NCORES depends target=x86_64-apple-darwin11 &&
cd ../../macos_universal/universal &&
./combine_and_build_all.sh
