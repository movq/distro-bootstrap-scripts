#!/bin/bash
set -ex

mrustc_commit=994ddf817a554c48ae03840c8aaf82fb99ab5d27

if ! command -v cmake; then
    echo "CMake is required (for LLVM)."
    exit 1
fi

#if ! [ -f llvm-project-17.0.6.src/build/bin/llvm-config ]; then
if ! [ -f llvm-17.0.6.src/build/bin/llvm-config ]; then
    tar -xf /var/cache/distfiles/llvm-project-17.0.6.src.tar.xz
    cd llvm-project-17.0.6.src
    mkdir build
    cd build
    cmake ../llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_TESTS=OFF
    make
fi
if ! [ -f llvm-project-18.1.8.src/build/bin/llvm-config ]; then
    tar -xf /var/cache/distfiles/llvm-project-18.1.8.src.tar.xz
    cd llvm-project-18.1.8.src
    mkdir build
    cd build
    cmake ../llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_TESTS=OFF
    make
fi

# initial bootstrap using mrustc
if ! [ -f mrustc-$mrustc_commit/run_rustc/output-1.74.0/prefix/bin/cargo ]; then
    cd ~
    tar -xf /var/cache/distfiles/mrustc-994ddf817a5.tar.gz
    cd mrustc-$mrustc_commit
    ln /var/cache/distfiles/rustc-1.74.0-src.tar.xz .
    sed -i 's/tar\.gz/tar\.xz/g' minicargo.mk
    sed -i '/^LLVM_CONFIG/s/.*/LLVM_CONFIG := \/home\/mike\/llvm-17.0.6.src\/build\/bin\/llvm-config/g' minicargo.mk
    sed -i '/^LLVM_CONFIG/s/.*/LLVM_CONFIG := \/home\/mike\/llvm-17.0.6.src\/build\/bin\/llvm-config/g' run_rustc/Makefile
    export RUSTC_VERSION=1.74.0 MRUSTC_TARGET_VER=1.74 OUTDIR_SUF=-1.74.0 RUSTC_TARGET=x86_64-unknown-linux-musl MAKEFLAGS="-j$(nproc)" PARLEVEL=$(nproc)
    make
    make -C tools/minicargo
    make -f minicargo.mk RUSTCSRC
    cd rustc-1.74.0-src
    patch -p1 -i /var/cache/distfiles/rustc-1.74.0-musl-dynamic.patch
    cd ..
    make -f minicargo.mk LIBS
    RUSTC_INSTALL_BINDIR=bin make -f minicargo.mk output-1.74.0/rustc
    LIBGIT2_SYS_USE_PKG_CONFIG=1 make -f minicargo.mk output-1.74.0/cargo
    make -C run_rustc
fi

#export RUSTC=$HOME/mrustc-$mrustc_commit/run_rustc/output-1.74.0/prefix/bin/rustc
#export CARGO=$HOME/mrustc-$mrustc_commit/run_rustc/output-1.74.0/prefix/bin/cargo

export RUSTC=$HOME/rustc-1.81.0-src/build/x86_64-unknown-linux-musl/stage1/bin/rustc
export CARGO=$HOME/rustc-1.81.0-src/build/stage1-cargo/release/cargo

# Why can't they just write the compiler in more conservative version of rust???
last=''
#for ver in 1.74.1 1.75.0 1.76.0 1.77.2 1.78.0 1.79.0 1.80.1 1.81.0 1.82.0 1.83.0; do
for ver in 1.82.0 1.83.0; do
    minor=$(echo $ver | cut -d'.' -f2)
    if [ $minor -ge 81 ]; then
        llvm_root=/home/mike/llvm-project-18.1.8.src/build
    else
        llvm_root=/home/mike/llvm-17.0.6.src/build
        #llvm_root=/home/mike/llvm-project-17.0.6.src/build
    fi
    cd ~
    tar -xf /var/cache/distfiles/rustc-$ver-src.tar.xz
    cd rustc-$ver-src
    ./configure --build=x86_64-unknown-linux-musl\
            --host=x86_64-unknown-linux-musl\
            --target=x86_64-unknown-linux-musl\
            --enable-local-rust\
            --llvm-root=$llvm_root\
            --disable-docs\
            --enable-locked-deps\
            --enable-vendor\
            --set='rust.musl-root=/usr'\
            --set='target.x86_64-unknown-linux-musl.cc=cc'\
            --set='target.x86_64-unknown-linux-musl.cxx=c++'\
            --set='target.x86_64-unknown-linux-musl.ar=ar'\
            --set='target.x86_64-unknown-linux-musl.linker=cc'\
            --set='target.x86_64-unknown-linux-musl.crt-static=false'\
            --set="build.cargo=${CARGO}"\
            --set "build.rustc=${RUSTC}"\
            --set="rust.lld=false"\
            --tools=''\
            --release-channel="stable"
    # Build just stage 1, then build cargo manually, to save time rebuilding the whole compiler a second time (stage 2)
    ./x.py build --stage 1 library/std library/proc_macro
    RUSTC=$PWD/build/x86_64-unknown-linux-musl/stage1/bin/rustc
    ${CARGO} build --release --frozen --offline --manifest-path src/tools/cargo/Cargo.toml --target-dir build/stage1-cargo
    CARGO=$PWD/build/stage1-cargo/release/cargo
    rm -rf $last
    last=$PWD
done
