#!/bin/bash
# Usage ./dev-setup.sh
# hpfs build environment setup script.

set -e # exit on error

sudo apt-get update
sudo apt-get install -y build-essential

workdir=~/hpfs-setup

mkdir $workdir
pushd $workdir > /dev/null 2>&1

# CMAKE
cmake=cmake-3.16.0-rc3-Linux-x86_64
wget https://github.com/Kitware/CMake/releases/download/v3.16.0-rc3/$cmake.tar.gz
tar -zxvf $cmake.tar.gz
sudo cp -r $cmake/bin/* /usr/local/bin/
sudo cp -r $cmake/share/* /usr/local/share/
rm $cmake.tar.gz && rm -r $cmake

# libfuse
sudo apt-get install -y meson ninja-build pkg-config
wget https://github.com/libfuse/libfuse/archive/fuse-3.8.0.tar.gz
tar -zxvf fuse-3.8.0.tar.gz
pushd libfuse-fuse-3.8.0 > /dev/null 2>&1
mkdir build
pushd build > /dev/null 2>&1
meson -Dexamples=false .. && ninja
sudo ninja install
popd > /dev/null 2>&1
popd > /dev/null 2>&1
rm fuse-3.8.0.tar.gz && sudo rm -r libfuse-fuse-3.8.0

# Blake3 (pinned release, linked statically)
blake3=1.8.7
blake3_sha256=c6782a28842b1c0478524ac06a4f2ede784038ee298d6e2162c0b089c4306a3c
wget https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/$blake3.tar.gz
echo "$blake3_sha256  $blake3.tar.gz" | sha256sum -c -
tar -zxvf $blake3.tar.gz
pushd BLAKE3-$blake3/c > /dev/null 2>&1
gcc -c -fPIC -O3 blake3.c blake3_dispatch.c blake3_portable.c \
    blake3_sse2_x86-64_unix.S blake3_sse41_x86-64_unix.S blake3_avx2_x86-64_unix.S \
    blake3_avx512_x86-64_unix.S
ar rcs libblake3.a *.o
sudo cp blake3.h /usr/local/include/
sudo cp libblake3.a /usr/local/lib/
popd > /dev/null 2>&1
rm $blake3.tar.gz && rm -r BLAKE3-$blake3

# Plog
wget https://github.com/SergiusTheBest/plog/archive/1.1.5.tar.gz
tar -zxvf 1.1.5.tar.gz
pushd plog-1.1.5 > /dev/null 2>&1
sudo cp -r include/plog /usr/local/include/
popd > /dev/null 2>&1
rm 1.1.5.tar.gz && rm -r plog-1.1.5

# CLI11
wget https://github.com/CLIUtils/CLI11/archive/refs/tags/v2.0.0.tar.gz
tar -zxvf v2.0.0.tar.gz
pushd CLI11-2.0.0 > /dev/null 2>&1
mkdir build
pushd build > /dev/null 2>&1
cmake ..
sudo make install/fast
popd > /dev/null 2>&1
popd > /dev/null 2>&1
rm v2.0.0.tar.gz && sudo rm -r CLI11-2.0.0

# Update linker library cache.
sudo ldconfig

# Pop workdir
popd > /dev/null 2>&1
rm -r $workdir

# Build hpfs
cmake .
make