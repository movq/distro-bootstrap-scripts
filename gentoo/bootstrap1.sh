#!/bin/sh

set -ex

# Environment
set +h
umask 022
ROOT=/target
LC_ALL=POSIX
CHOST=x86_64-boot1-linux-gnu
CBUILD=i386-unknown-linux-musl
PATH=/usr/bin:/usr/sbin:/bin:/sbin
PATH=$ROOT/tools/bin:$PATH
CONFIG_SITE=$ROOT/usr/share/config.site
export ROOT LC_ALL CHOST PATH CONFIG_SITE

MULTILIB=$1

# Convenience variables
UNTAR="tar --no-same-owner -xf"

# Version numbers
GCC=10.4.0
GLIBC=2.28
GAWK=5.1.1
SED=4.8
BINUTILS=2.37
MPFR=4.1.0
GMP=6.2.1
MPC=1.2.1
KERNEL=5.16.9
M4=1.4.19
NCURSES=6.3
BASH=5.1.16
COREUTILS=9.0
DIFFUTILS=3.8
FILE=5.41
FINDUTILS=4.9.0
GREP=3.7
GZIP=1.11
MAKE=4.3
PATCH=2.7.6
TAR=1.34
XZ=5.2.5

# Create directory layout
mkdir -pv $ROOT/{etc,var} $ROOT/usr/{bin,lib64,lib,sbin}
mkdir -pv $ROOT/{bin,sbin,lib,lib64}

cd /usr/src
find . -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;

# Update gawk (it's too old in live-bootstrap)
$UNTAR gawk-$GAWK.tar.xz
cd gawk-$GAWK
./configure --prefix=/usr --disable-shared
make -j8
make install
cd /usr/src
rm -rf gawk-$GAWK

# Update sed (it's too old in live-bootstrap)
$UNTAR sed-$SED.tar.xz
cd sed-$SED
./configure --prefix=/usr --disable-shared
make -j8
make install
cd /usr/src
rm -rf sed-$SED

# Binutils - Pass 1
$UNTAR binutils-$BINUTILS.tar.xz
cd binutils-$BINUTILS
mkdir build; cd build
if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib"
else
    extra_flags="--disable-multilib"
fi

../configure --prefix=$ROOT/tools \
             --with-sysroot=$ROOT \
             --target=$CHOST   \
             --build=$CBUILD \
             --host=$CBUILD \
             --disable-nls       \
             --disable-werror    \
             --disable-shared    \
             --disable-plugins   \
             --disable-lto \
             $extra_flags
make -j8
make install
cd /usr/src
rm -rf binutils-$BINUTILS

# GCC - Pass 1
$UNTAR gcc-$GCC.tar.xz
cd gcc-$GCC
$UNTAR ../mpfr-$MPFR.tar.xz
$UNTAR ../gmp-$GMP.tar.xz
$UNTAR ../mpc-$MPC.tar.gz
mv mpfr* mpfr
mv gmp* gmp
mv mpc* mpc
mkdir build; cd build

if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib --with-multilib-list=m64,m32"
else
    extra_flags="--disable-multilib"
fi

../configure                                       \
    --build=$CBUILD \
    --host=$CBUILD \
    --target=$CHOST                              \
    --prefix=$ROOT/tools                           \
    --with-glibc-version=$GLIBC                    \
    --with-sysroot=$ROOT                           \
    --with-newlib                                  \
    --without-headers                              \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++                       \
    --disable-lto                                  \
    --disable-plugin                               \
    $extra_flags
make -j8
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($CHOST-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
cd /usr/src
rm -rf gcc-$GCC

# Linux API headers
$UNTAR linux-$KERNEL.tar.xz
cd linux-$KERNEL
make mrproper
make headers
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $ROOT/usr
cd /usr/src
rm -rf linux-$KERNEL

# glibc
$UNTAR glibc-$GLIBC.tar.xz
cd glibc-$GLIBC
mkdir build; cd build
echo "rootsbindir=/sbin" > configparms
if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multi-arch"
else
    extra_flags=""
fi
../configure                             \
      --prefix=/usr                      \
      --host=$CHOST                      \
      --build=$CBUILD                    \
      --enable-kernel=5.15               \
      --with-headers=$ROOT/usr/include   \
      --disable-werror                   \
      --libdir=/usr/lib64                \
      $extra_flags                       \
      libc_cv_slibdir=/lib64
make -j8
# Nasty hack, because for some reason the documentation generation is
# fucked when running in live-bootstrap.
make DESTDIR=$ROOT MAKEINFO=/bin/true INSTALL_INFO=/bin/true install || true
touch manual/libc.info
make DESTDIR=$ROOT MAKEINFO=/bin/true INSTALL_INFO=/bin/true install
$ROOT/tools/libexec/gcc/$CHOST/$GCC/install-tools/mkheaders

if [ $MULTILIB -eq 1 ]
then
    cd ..
    rm -rf build
    mkdir build; cd build
    echo "rootsbindir=/sbin" > configparms
    CC="$CHOST-gcc -m32" CXX="$CHOST-g++ -m32" \
          ../configure                       \
          --prefix=/usr                      \
          --host=i686-pc-linux-gnu           \
          --build=$CBUILD                    \
          --enable-kernel=5.15               \
          --with-headers=$ROOT/usr/include   \
          --enable-multi-arch                \
          --disable-werror                   \
          --libdir=/usr/lib                  \
          --libexecdir=/usr/lib                  \
          libc_cv_slibdir=/lib
    make -j8
    make DESTDIR=$PWD/DESTDIR MAKEINFO=/bin/true INSTALL_INFO=/bin/true install || true
    touch manual/libc.info
    make DESTDIR=$PWD/DESTDIR MAKEINFO=/bin/true INSTALL_INFO=/bin/true install
    cp -av DESTDIR/lib/. $ROOT/lib
    cp -av DESTDIR/usr/lib/. $ROOT/usr/lib
    install -vm644 DESTDIR/usr/include/gnu/{lib-names,stubs}-32.h \
                   $ROOT/usr/include/gnu/
fi

cd /usr/src
rm -rf glibc-$GLIBC

# libstdc++
$UNTAR gcc-$GCC.tar.xz
cd gcc-$GCC
mkdir build; cd build

if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib"
else
    extra_flags="--disable-multilib"
fi

../libstdc++-v3/configure           \
    --host=$CHOST                 \
    --build=$CBUILD                  \
    --prefix=/usr                   \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$CHOST/include/c++/$GCC \
    --libdir=/usr/lib64             \
    $extra_flags
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf gcc-$GCC

# m4
$UNTAR m4-$M4.tar.xz
cd m4-$M4
./configure --prefix=/usr   \
            --host=$CHOST \
            --build=$CBUILD \
    --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf m4-$M4

# ncurses
$UNTAR ncurses-$NCURSES.tar.gz
cd ncurses-$NCURSES
sed -i s/mawk// configure
mkdir build; cd build
../configure
make -j8 -C include
make -j8 -C progs tic
cd ..
./configure --prefix=/usr                \
            --host=$CHOST              \
            --build=$CBUILD               \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --enable-widec               \
            --disable-stripping \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $ROOT/usr/lib64/libncurses.so
cd /usr/src
rm -rf ncurses-$NCURSES

# bash
$UNTAR bash-$BASH.tar.gz
cd bash-$BASH
./configure --prefix=/usr                   \
            --build=$CBUILD                  \
            --host=$CHOST                 \
            --without-bash-malloc \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
ln -sv /usr/bin/bash $ROOT/bin/bash
ln -sv bash $ROOT/bin/sh
cd /usr/src
rm -rf bash-$BASH

# coreutils
$UNTAR coreutils-$COREUTILS.tar.xz
cd coreutils-$COREUTILS
./configure --prefix=/usr                     \
            --host=$CHOST                   \
            --build=$CBUILD                    \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
mv -v $ROOT/usr/bin/chroot               $ROOT/usr/sbin
mkdir -pv $ROOT/usr/share/man/man8
mv -v $ROOT/usr/share/man/man1/chroot.1  $ROOT/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                     $ROOT/usr/share/man/man8/chroot.8
cd /usr/src
rm -rf coreutils-$COREUTILS

# diffutils
$UNTAR diffutils-$DIFFUTILS.tar.xz
cd diffutils-$DIFFUTILS
./configure --prefix=/usr \
            --host=$CHOST \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf diffutils-$DIFFUTILS

# file
$UNTAR file-$FILE.tar.gz
cd file-$FILE
mkdir build
cd build
env CFLAGS="-std=gnu99" ../configure --disable-bzlib      \
             --disable-libseccomp \
             --disable-xzlib      \
             --disable-zlib       \
             --disable-shared     \
             --libdir=/usr/lib64
make -j8
cd ..
./configure --prefix=/usr \
            --host=$CHOST \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8 FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$ROOT install
cd /usr/src
rm -rf file-$FILE

# findutils
$UNTAR findutils-$FINDUTILS.tar.xz
cd findutils-$FINDUTILS
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$CHOST                 \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf findutils-$FINDUTILS

# gawk
$UNTAR gawk-$GAWK.tar.xz
cd gawk-$GAWK
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$CHOST \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf gawk-$GAWK

# grep
$UNTAR grep-$GREP.tar.xz
cd grep-$GREP
./configure --prefix=/usr   \
            --host=$CHOST \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf grep-$GREP

# gzip
$UNTAR gzip-$GZIP.tar.xz
cd gzip-$GZIP
./configure --prefix=/usr \
            --host=$CHOST \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf gzip-$GZIP

# make
$UNTAR make-$MAKE.tar.gz
cd make-$MAKE
./configure --prefix=/usr   \
            --without-guile \
            --host=$CHOST \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf make-$MAKE

# patch
$UNTAR patch-$PATCH.tar.xz
cd patch-$PATCH
./configure --prefix=/usr   \
            --host=$CHOST \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf patch-$PATCH

# sed
$UNTAR sed-$SED.tar.xz
cd sed-$SED
./configure --prefix=/usr   \
            --host=$CHOST \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf sed-$SED

# tar
$UNTAR tar-$TAR.tar.xz
cd tar-$TAR
./configure --prefix=/usr                     \
            --host=$CHOST                   \
            --build=$CBUILD \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf tar-$TAR

# xz
$UNTAR xz-$XZ.tar.xz
cd xz-$XZ
./configure --prefix=/usr                     \
            --host=$CHOST                   \
            --build=$CBUILD                    \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-$XZ \
            --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
cd /usr/src
rm -rf xz-$XZ

# binutils - pass 2
$UNTAR binutils-$BINUTILS.tar.xz
cd binutils-$BINUTILS
# Binutils ships an outdated libtool copy in the tarball. It lacks with-sysroot
# support so the produced binaries will be mistakenly linked to libraries from
# the host.
sed '6009s/$add_dir//' -i ltmain.sh
mkdir build; cd build
../configure                   \
    --prefix=/usr              \
    --build=$CBUILD             \
    --host=$CHOST            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd \
    --libdir=/usr/lib64
make -j8
make DESTDIR=$ROOT install
install -vm755 libctf/.libs/libctf.so.0.0.0 $ROOT/usr/lib64
cd /usr/src
rm -rf binutils-$BINUTILS

# GCC - pass 2
$UNTAR gcc-$GCC.tar.xz
cd gcc-$GCC
$UNTAR ../mpfr-$MPFR.tar.xz
$UNTAR ../gmp-$GMP.tar.xz
$UNTAR ../mpc-$MPC.tar.gz
mv mpfr* mpfr
mv gmp* gmp
mv mpc* mpc
mkdir build; cd build
mkdir -pv $CHOST/libgcc
ln -s ../../../libgcc/gthr-posix.h $CHOST/libgcc/gthr-default.h

if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib --with-multilib-list=m64,m32"
else
    extra_flags="--disable-multilib"
fi

../configure                                       \
    --build=$CBUILD                                 \
    --host=$CHOST                                \
    --prefix=/usr                                  \
    CC_FOR_TARGET=$CHOST-gcc                     \
    --with-build-sysroot=$ROOT                      \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-decimal-float                        \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++                       \
    $extra_flags
make -j8
make DESTDIR=$ROOT install
ln -sv gcc $ROOT/usr/bin/cc
cd /usr/src
rm -rf $GCC
