#!/bin/bash

set -xe

LFS=$PWD/rootfs
LFS_TGT=x86_64-alpine-linux-musl
PROJECT_ROOT=$PWD

export PATH=$PROJECT_ROOT/toolchain/usr/bin:$PATH

export CFLAGS="-march=x86-64 -pipe -O2"
export CXXFLAGS=$CFLAGS
export MAKEFLAGS=-j12

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib}

for i in bin lib; do
  ln -sv usr/$i $LFS/$i
done

ln -sv bin $LFS/sbin
ln -sv bin $LFS/usr/sbin

mkdir -pv $LFS/{dev,dev/pts,proc,sys,run}
mkdir -pv $LFS/{boot,home,mnt,opt,srv}
mkdir -pv $LFS/etc/{opt,sysconfig}
mkdir -pv $LFS/lib/firmware
mkdir -pv $LFS/media/{floppy,cdrom}
mkdir -pv $LFS/usr/{,local/}{include,src}
mkdir -pv $LFS/usr/lib/locale
mkdir -pv $LFS/usr/local/{bin,lib,sbin}
mkdir -pv $LFS/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv $LFS/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv $LFS/usr/{,local/}share/man/man{1..8}
mkdir -pv $LFS/var/{cache,local,log,mail,opt,spool}
mkdir -pv $LFS/var/lib/{color,misc,locate}

ln -sfv /run $LFS/var/run
ln -sfv /run/lock $LFS/var/lock

install -dv -m 0750 $LFS/root
install -dv -m 1777 $LFS/tmp $LFS/var/tmp

ln -sv /proc/self/mounts $LFS/etc/mtab

cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
mike:x:1000:1000:Mike:/home/mike:/bin/bash
EOF

cat > $LFS/etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
mike:x:1000:
abuild:x:1001:mike
EOF

# Cross toolchain
mkdir work
cd work
tar -xf $PROJECT_ROOT/distfiles/binutils-2.43.tar.zst
cd binutils-2.43
mkdir build
cd build
../configure --prefix=$PROJECT_ROOT/toolchain/usr \
	--with-sysroot=$LFS \
	--target=$LFS_TGT \
	--disable-nls \
	--enable-gprofng=no \
	--disable-werror
make
make -j1 install
cd $PROJECT_ROOT/work
rm -rf binutils-2.43

tar -xf $PROJECT_ROOT/distfiles/gcc-14.2.0.tar.xz
cd gcc-14.2.0
patch -p1 -i $PROJECT_ROOT/distfiles/0022-x86_64-disable-multilib-support.patch
mkdir build
cd build
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$PROJECT_ROOT/toolchain/usr       \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
make
make -j1 install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
cd $PROJECT_ROOT/work
rm -rf gcc-14.2.0

tar -xf $PROJECT_ROOT/distfiles/linux-6.6.64.tar.xz
cd linux-6.6.64
make -j1 mrproper
make -j1 headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
cd $PROJECT_ROOT/work
rm -rf linux-6.6.64

tar -xf $PROJECT_ROOT/distfiles/musl-1.2.5.tar.gz
cd musl-1.2.5
export LDFLAGS="$LDFLAGS -Wl,-soname,libc.musl-x86_64.so.1"
./configure CROSS_COMPILE=$LFS_TGT- --prefix=/usr --target=$LFS_TGT
make
make -j1 install DESTDIR=$LFS
unset LDFLAGS
mv -f $LFS/usr/lib/libc.so $LFS/usr/lib/ld-musl-x86_64.so.1
ln -sf ld-musl-x86_64.so.1 $LFS/usr/lib/libc.musl-x86_64.so.1
ln -sf ld-musl-x86_64.so.1 $LFS/usr/lib/libc.so
$LFS_TGT-gcc $CFLAGS $PROJECT_ROOT/distfiles/getent.c -o getent
cp getent $LFS/usr/bin
cd $PROJECT_ROOT/work
rm -rf musl-1.2.5

tar -xf $PROJECT_ROOT/distfiles/gcc-14.2.0.tar.xz
cd gcc-14.2.0
patch -p1 -i $PROJECT_ROOT/distfiles/0022-x86_64-disable-multilib-support.patch
mkdir build
cd build
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$PROJECT_ROOT/toolchain/usr       \
    --with-sysroot=$LFS       \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-multilib        \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libsanitizer    \
    --disable-libssp          \
    --disable-libvtv          \
    --enable-languages=c,c++
make
make -j1 install
cp -r $PROJECT_ROOT/toolchain/usr/$LFS_TGT/{lib,include} $LFS/usr
cd $PROJECT_ROOT/work
rm -rf gcc-14.2.0


tar -xf $PROJECT_ROOT/distfiles/m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf m4-1.4.19

tar -xf $PROJECT_ROOT/distfiles/ncurses-6.5.tar.gz
cd ncurses-6.5
mkdir build
cd build
../configure AWK=gawk
make -C include
make -C progs tic
cd ..
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk
make
make -j1 DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
ln -sv libncursesw.so $LFS/usr/lib/libtinfo.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
cd $PROJECT_ROOT/work
rm -rf ncurses-6.5

tar -xf $PROJECT_ROOT/distfiles/bash-5.2.37.tar.gz
cd bash-5.2.37
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make -j1 DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd $PROJECT_ROOT/work
rm -rf bash-5.2.37

tar -xf $PROJECT_ROOT/distfiles/coreutils-9.5.tar.xz
cd coreutils-9.5
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf coreutils-9.5

tar -xf $PROJECT_ROOT/distfiles/diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf diffutils-3.10

tar -xf $PROJECT_ROOT/distfiles/file-5.46.tar.gz
cd file-5.46
mkdir build
cd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
cd ..
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make -j1 DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd $PROJECT_ROOT/work
rm -rf file-5.46

tar -xf $PROJECT_ROOT/distfiles/findutils-4.10.0.tar.xz
cd findutils-4.10.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf findutils-4.10.0

tar -xf $PROJECT_ROOT/distfiles/gawk-5.3.1.tar.xz
cd gawk-5.3.1
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf gawk-5.3.1

tar -xf $PROJECT_ROOT/distfiles/grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf grep-3.11

tar -xf $PROJECT_ROOT/distfiles/gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr --host=$LFS_TGT
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf gzip-1.13

tar -xf $PROJECT_ROOT/distfiles/make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf make-4.4.1

tar -xf $PROJECT_ROOT/distfiles/patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf patch-2.7.6

tar -xf $PROJECT_ROOT/distfiles/sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf sed-4.9

tar -xf $PROJECT_ROOT/distfiles/tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf tar-1.35

tar -xf $PROJECT_ROOT/distfiles/xz-5.6.3.tar.xz
cd xz-5.6.3
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.3
make
make -j1 DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd $PROJECT_ROOT/work
rm -rf xz-5.6.3

tar -xf $PROJECT_ROOT/distfiles/binutils-2.43.1.tar.xz
cd binutils-2.43.1
sed '6009s/$add_dir//' -i ltmain.sh
mkdir build
cd build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu \
    --disable-multilib
make
make -j1 DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd $PROJECT_ROOT/work
rm -rf binutils-2.43.1

tar -xf $PROJECT_ROOT/distfiles/gcc-14.2.0.tar.xz
cd gcc-14.2.0
tar -xf $PROJECT_ROOT/distfiles/mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf $PROJECT_ROOT/distfiles/gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf $PROJECT_ROOT/distfiles/mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
patch -p1 -i $PROJECT_ROOT/distfiles/0022-x86_64-disable-multilib-support.patch
mkdir -v build
cd       build
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make
make -j1 DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
cd $PROJECT_ROOT/work
rm -rf gcc-14.2.0

tar -xf $PROJECT_ROOT/distfiles/pkgconf-2.3.0.tar.xz
cd pkgconf-2.3.0
./configure --prefix=/usr --host=$LFS_TGT
make
make -j1 DESTDIR=$LFS install
ln -s pkgconf $LFS/usr/bin/pkg-config
cd $PROJECT_ROOT/work
rm -rf pkgconf-2.3.0

tar -xf $PROJECT_ROOT/distfiles/zlib-1.3.1.tar.gz
cd zlib-1.3.1
CC=$LFS_TGT-gcc ./configure --prefix=/usr
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf zlib-1.3.1

tar -xf $PROJECT_ROOT/distfiles/openssl-3.3.2.tar.gz
cd openssl-3.3.2
./config --prefix=/usr         \
	 --cross-compile-prefix=$LFS_TGT- \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf openssl-3.3.2

tar -xf $PROJECT_ROOT/distfiles/util-linux-2.40.2.tar.xz
cd util-linux-2.40.2
./configure --prefix=/usr --host=$LFS_TGT --libdir=/usr/lib     \
	    --runstatedir=/run    \
	    --disable-chfn-chsh   \
	    --disable-login       \
	    --disable-nologin     \
	    --disable-su          \
	    --disable-setpriv     \
	    --disable-runuser     \
	    --disable-pylibmount  \
	    --disable-static      \
	    --disable-liblastlog2 \
	    --without-python      \
		--without-systemd \
	    --docdir=/usr/share/doc/util-linux-2.40.2
make
mkdir tmp-path
ln -s /usr/bin/true tmp-path/chgrp
ln -s /usr/bin/true tmp-path/chown
PATH=$PWD/tmp-path:$PATH make -j1 install DESTDIR=$LFS
cd $PROJECT_ROOT/work
rm -rf util-linux-2.40.2

tar -xf $PROJECT_ROOT/distfiles/shadow-4.16.0.tar.xz
cd shadow-4.16.0
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
touch $LFS/usr/bin/passwd
./configure --host=$LFS_TGT --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
make
make -j1 install DESTDIR=$LFS
cd $PROJECT_ROOT/work
rm -rf shadow-4.16.0

tar -xf $PROJECT_ROOT/distfiles/busybox-1.37.0.tar.bz2
cd busybox-1.37.0
make defconfig
sed -i '/CONFIG_TC/s/.*/CONFIG_TC=n/' .config
yes '' | make oldconfig
make CROSS_COMPILE=$LFS_TGT-
cp busybox $LFS/usr/bin
ln -s busybox $LFS/usr/bin/adduser
ln -s busybox $LFS/usr/bin/addgroup
ln -s busybox $LFS/usr/bin/bc
ln -s busybox $LFS/usr/bin/getfattr
ln -s busybox $LFS/usr/bin/vi
ln -s busybox $LFS/usr/bin/ash
ln -s busybox $LFS/usr/bin/unzip
ln -s busybox $LFS/usr/bin/zip
ln -s busybox $LFS/usr/bin/bzip2
ln -s busybox $LFS/usr/bin/wget
cd $PROJECT_ROOT/work
rm -rf busybox-1.37.0

tar -xf $PROJECT_ROOT/distfiles/Linux-PAM-1.6.1.tar.xz
cd Linux-PAM-1.6.1
./configure --prefix=/usr --libdir=/usr/lib --host=$LFS_TGT --disable-logind
make
make -j1 install DESTDIR=$LFS
cd $PROJECT_ROOT/work
rm -rf Linux-PAM-1.6.1

tar -xf $PROJECT_ROOT/distfiles/libcap-2.73.tar.xz
cd libcap-2.73
make BUILD_CC=gcc CROSS_COMPILE=x86_64-alpine-linux-musl- LIBDIR=/usr/lib
make -j1 install DESTDIR=$LFS LIBDIR=/usr/lib
cd $PROJECT_ROOT/work
rm -rf libcap-2.73

tar -xf $PROJECT_ROOT/distfiles/fakeroot_1.36.orig.tar.gz
cd fakeroot-1.36
patch -p1 -i $PROJECT_ROOT/distfiles/fakeroot-no64.patch
patch -p1 -i $PROJECT_ROOT/distfiles/xstatjunk.patch
./bootstrap
sed -i '/\(linux-gnu\*\)/s/.*/\(linux-musl\)/' configure
./configure --prefix=/usr --libdir=/usr/lib --host=$LFS_TGT CFLAGS="$CFLAGS -DLIBFAKEROOT_DEBUGGING=1"
make
make -j1 DESTDIR=$LFS  install
cd $PROJECT_ROOT/work
rm -rf fakeroot-1.36

tar -xf $PROJECT_ROOT/distfiles/pax-utils-1.3.8.tar.xz
cd pax-utils-1.3.8
touch config.h
$LFS_TGT-gcc $CFLAGS -D_GNU_SOURCE scanelf.c paxelf.c paxinc.c paxldso.c xfuncs.c security.c -o scanelf
cp scanelf $LFS/usr/bin
cd $PROJECT_ROOT/work
rm -rf pax-utils-1.3.8

tar -xf $PROJECT_ROOT/distfiles/opendoas-6.8.2.tar.gz
cd OpenDoas-6.8.2
CC=$LFS_TGT-gcc ./configure --host=$LFS_TGT --without-pam --prefix=/usr
CC=$LFS_TGT-gcc make
fakeroot make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf OpenDoas-6.8.2

tar -xf $PROJECT_ROOT/distfiles/apk-tools-v2.14.6.tar.gz
cd apk-tools-v2.14.6
make CROSS_COMPILE=x86_64-alpine-linux-musl- LUA=no
make -j1 CROSS_COMPILE=x86_64-alpine-linux-musl- LUA=no DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf apk-tools-v2.14.6

git clone https://git.movq.org/mike/abuild -b bootstrap
cd abuild
make CC=$LFS_TGT-gcc
make -j1 DESTDIR=$LFS install
cd $PROJECT_ROOT/work
rm -rf abuild
