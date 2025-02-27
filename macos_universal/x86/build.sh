#!/bin/bash
HOST_NCORES=$(nproc 2>/dev/null || shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
cd build && cmake -jHOST_NCORES -DCMAKE_TOOLCHAIN_FILE=../../../external/monero-project/contrib/depends/x86_64-apple-darwin11/share/toolchain.cmake .. && make -jHOST_NCORES
