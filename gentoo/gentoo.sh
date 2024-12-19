#!/bin/bash

set -ex

#export CBUILD=x86_64-boot2-linux-gnu
export CHOST=x86_64-pc-linux-gnu
#export ROOT=/gentoo
#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$ROOT/tools/bin
export FEATURES="-sandbox"

EBUILD_PATH=/var/db/repos/gentoo
UNTAR="tar -xf"

GCC=11.3.0
BINUTILS=2.37
GLIBC=2.34

#mkdir -p $ROOT/tools/bin
#mkdir -p $ROOT/{bin,sbin,etc,lib,lib64,var,run}
#mkdir -p $ROOT/usr/{bin,sbin,lib,lib64}
#mkdir -p $ROOT/etc/portage/repos.conf
#mkdir -p $ROOT/var/db/repos/gentoo

mkdir -p /etc/portage/repos.conf
mkdir -p /var/db/repos/gentoo

cat << EOF > /etc/portage/make.conf
COMMON_FLAGS="-march=skylake -O2 -ftree-vectorize -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=skylake"
MAKEOPTS="-j8"

# NOTE: This stage was built with the bindist Use flag enabled
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"

# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C
L10N="en-GB"

GENTOO_MIRRORS="https://mirrors.gethosted.online/gentoo"
ACCEPT_LICENSE="-* @FREE"

CPU_FLAGS_X86="aes mmx mmxext sse sse2 sse3 sse4_1 sse4_2 ssse3 avx avx2 f16c fma3 pclmul popcnt rdrand"
VIDEO_CARDS="intel"
LLVM_TARGETS="X86 BPF"
LUA_SINGLE_TARGET="luajit"
LUA_TARGETS="luajit"

#USE="dbus fish-completion pulseaudio vaapi wayland -cups -gnome -qt -seccomp -sendmail -vala -X"

PORTAGE_NICENESS=19

#PORTAGE_BINHOST="http://192.168.1.175/"
#FEATURES="buildpkg"

CARGO_TERM_VERBOSE=false
CMAKE_VERBOSE=OFF
EOF

cat << EOF > /etc/portage/repos.conf/gentoo.conf
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
sync-type = git
sync-uri = https://github.com/gentoo-mirror/gentoo.git
auto-sync = yes
sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
sync-openpgp-keyserver = hkps://keys.gentoo.org
sync-openpgp-key-refresh-retry-count = 40
sync-openpgp-key-refresh-retry-overall-timeout = 1200
sync-openpgp-key-refresh-retry-delay-exp-base = 2
sync-openpgp-key-refresh-retry-delay-max = 60
sync-openpgp-key-refresh-retry-delay-mult = 4
sync-webrsync-verify-signature = yes
sync-git-verify-commit-signature = yes
EOF

ln -s ../../var/db/repos/gentoo/profiles/default/linux/amd64/17.1 /etc/portage/make.profile

#cp -a --reflink=always /var/db/repos/gentoo/. $ROOT/var/db/repos/gentoo
#cp -a /etc/portage/. $ROOT/etc/portage

#cd /usr/src
#$UNTAR binutils-$BINUTILS.tar.xz
#cd binutils-$BINUTILS
#mkdir build && cd build
#../configure --prefix=$ROOT/tools       \
#             --with-sysroot=$ROOT \
#             --build=$CBUILD \
#             --host=$CBUILD \
#             --target=$CHOST   \
#             --disable-nls       \
#             --disable-werror    \
#             --enable-multilib
#make -j8
#make install
#cd /usr/src
#rm -rf binutils-$BINUTILS
#
#cd /usr/src
#$UNTAR gcc-$GCC.tar.xz
#cd gcc-$GCC
#mkdir build && cd build
#mlist=m64,m32
#../configure                  \
#    --build=$CBUILD \
#    --host=$CBUILD \
#    --target=$CHOST                              \
#    --prefix=$ROOT/tools                            \
#    --with-glibc-version=2.34                      \
#    --with-sysroot=$ROOT                            \
#    --with-newlib                                  \
#    --without-headers                              \
#    --enable-initfini-array                        \
#    --disable-nls                                  \
#    --disable-shared                               \
#    --enable-multilib --with-multilib-list=$mlist  \
#    --disable-decimal-float                        \
#    --disable-threads                              \
#    --disable-libatomic                            \
#    --disable-libgomp                              \
#    --disable-libquadmath                          \
#    --disable-libssp                               \
#    --disable-libvtv                               \
#    --disable-libstdcxx                            \
#    --enable-languages=c,c++
#make -j8
#make install
#cd ..
#cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($CHOST-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
#cd /usr/src
#rm -rf gcc-$GCC
#
## symlink toolchain to /usr/bin
#ln -s $ROOT/tools/bin/* /usr/bin

echo "portage:x:250:250:portage:/var/tmp/portage:/bin/false" >> /etc/passwd
echo "portage::250:portage" >> /etc/group

ebuild $EBUILD_PATH/sys-kernel/linux-headers/linux-headers-5.15-r3.ebuild merge

#cd /usr/src
#$UNTAR glibc-$GLIBC.tar.xz
#cd glibc-$GLIBC
#mkdir build
#cd build
#echo "rootsbindir=/sbin" > configparms
#../configure                             \
#      --prefix=/usr                      \
#      --host=$CHOST                    \
#      --build=$CBUILD \
#      --enable-kernel=5.15                \
#      --with-headers=$ROOT/usr/include    \
#      --enable-multi-arch                \
#      --libdir=/usr/lib64 \
#      libc_cv_slibdir=/lib64 
#make -j8
#make DESTDIR=$ROOT install
#$ROOT/tools/libexec/gcc/$CHOST/$GCC/install-tools/mkheaders
#cd ..
#rm -rf build
#mkdir build && cd build
#echo "rootsbindir=/sbin" > configparms
#CC="$CHOST-gcc -m32" \
#CXX="$CHOST-g++ -m32" \
#../configure                             \
#      --prefix=/usr                      \
#      --host=i686-pc-linux-gnu           \
#      --build=$CBUILD                    \
#      --enable-kernel=5.15               \
#      --with-headers=$ROOT/usr/include    \
#      --enable-multi-arch                \
#      --libdir=/usr/lib                  \
#      --libexecdir=/usr/lib              \
#      libc_cv_slibdir=/lib
#make -j8
#make DESTDIR=$PWD/DESTDIR install
#cp -av DESTDIR/lib/. $ROOT/lib
#cp -av DESTDIR/usr/lib/. $ROOT/usr/lib
#install -vm644 DESTDIR/usr/include/gnu/{lib-names,stubs}-32.h \
#               $ROOT/usr/include/gnu/
#cd /usr/src
#rm -rf glibc-$GLIBC
#
#$UNTAR gcc-$GCC.tar.xz
#cd gcc-$GCC
#mkdir build && cd build
#../libstdc++-v3/configure           \
#    --host=$CHOST                 \
#    --build=$CBUILD                \
#    --prefix=/usr                   \
#    --enable-multilib               \
#    --disable-nls                   \
#    --disable-libstdcxx-pch         \
#    --with-gxx-include-dir=/tools/$CHOST/include/c++/$GCC
#make -j8
#make DESTDIR=$ROOT install
#cd ..
#rm -rf build
## glibc requires libgcc_s.so, so rebuild gcc without
## --disable-shared
#mkdir build && cd build
#mlist=m64,m32
#../configure                  \
#    --build=$CBUILD \
#    --host=$CBUILD \
#    --target=$CHOST                              \
#    --prefix=$ROOT/tools                            \
#    --with-glibc-version=2.34                      \
#    --with-sysroot=$ROOT                            \
#    --with-newlib                                  \
#    --without-headers                              \
#    --enable-initfini-array                        \
#    --disable-nls                                  \
#    --enable-multilib --with-multilib-list=$mlist  \
#    --disable-decimal-float                        \
#    --disable-threads                              \
#    --disable-libatomic                            \
#    --disable-libgomp                              \
#    --disable-libquadmath                          \
#    --disable-libssp                               \
#    --disable-libvtv                               \
#    --disable-libstdcxx                            \
#    --enable-languages=c,c++
#make -j8
#make install
#cd /usr/src
#rm -rf gcc-$GCC


ebuild $EBUILD_PATH/sys-apps/baselayout/baselayout-2.8.ebuild merge
ebuild $EBUILD_PATH/sys-libs/glibc/glibc-2.34-r13.ebuild digest
ebuild $EBUILD_PATH/sys-libs/glibc/glibc-2.34-r13.ebuild merge
ebuild $EBUILD_PATH/sys-devel/m4/m4-1.4.19.ebuild merge
ebuild $EBUILD_PATH/sys-libs/ncurses/ncurses-6.3_p20220423.ebuild merge
ebuild $EBUILD_PATH/sys-libs/readline/readline-8.1_p2.ebuild merge
ebuild $EBUILD_PATH/app-shells/bash/bash-5.1_p16.ebuild merge
ebuild $EBUILD_PATH/sys-apps/attr/attr-2.5.1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/acl/acl-2.3.1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/coreutils/coreutils-8.32-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/diffutils/diffutils-3.8.ebuild merge
ebuild $EBUILD_PATH/sys-libs/zlib/zlib-1.2.12-r2.ebuild merge
ebuild $EBUILD_PATH/app-arch/bzip2/bzip2-1.0.8-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/file/file-5.41.ebuild merge
ebuild $EBUILD_PATH/sys-apps/findutils/findutils-4.9.0.ebuild merge
ebuild $EBUILD_PATH/sys-apps/gawk/gawk-5.1.1-r2.ebuild merge
ebuild $EBUILD_PATH/dev-libs/libpcre/libpcre-8.45-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/grep/grep-3.7.ebuild merge
ebuild $EBUILD_PATH/app-arch/gzip/gzip-1.12.ebuild merge
ebuild $EBUILD_PATH/sys-devel/make/make-4.3.ebuild merge
ebuild $EBUILD_PATH/sys-devel/patch/patch-2.7.6-r4.ebuild merge
ebuild $EBUILD_PATH/sys-apps/sed/sed-4.8.ebuild merge
ebuild $EBUILD_PATH/app-arch/tar/tar-1.34.ebuild merge
ebuild $EBUILD_PATH/app-arch/xz-utils/xz-utils-5.2.5-r2.ebuild merge
ebuild $EBUILD_PATH/app-admin/eselect/eselect-1.4.20.ebuild merge
ebuild $EBUILD_PATH/app-misc/ca-certificates/ca-certificates-20210119.3.66.ebuild merge
ebuild $EBUILD_PATH/dev-libs/openssl/openssl-1.1.1q.ebuild merge
ebuild $EBUILD_PATH/net-misc/rsync/rsync-3.2.4-r3.ebuild merge
ebuild $EBUILD_PATH/net-misc/wget/wget-1.21.3-r1.ebuild merge
env LDFLAGS=-ltinfo ebuild $EBUILD_PATH/sys-libs/gdbm/gdbm-1.23.ebuild merge
ebuild $EBUILD_PATH/dev-lang/perl/perl-5.34.1-r3.ebuild merge
ebuild $EBUILD_PATH/sys-devel/autoconf/autoconf-2.71-r1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/autoconf-wrapper/autoconf-wrapper-20220130.ebuild merge
ebuild $EBUILD_PATH/sys-devel/autoconf-archive/autoconf-archive-2022.02.11.ebuild merge
ebuild $EBUILD_PATH/sys-devel/automake/automake-1.16.5.ebuild merge
ebuild $EBUILD_PATH/sys-devel/automake-wrapper/automake-wrapper-11-r1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/gnuconfig/gnuconfig-20220508.ebuild merge
ebuild $EBUILD_PATH/sys-devel/libtool/libtool-2.4.7.ebuild merge
ebuild $EBUILD_PATH/sys-apps/makedev/makedev-3.23.1-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/less/less-590.ebuild merge
ebuild $EBUILD_PATH/sys-apps/net-tools/net-tools-2.10.ebuild merge
ebuild $EBUILD_PATH/dev-libs/libffi/libffi-3.4.2-r1.ebuild merge
ebuild $EBUILD_PATH/dev-libs/expat/expat-2.4.8.ebuild merge
cat << EOF > /tmp/config.site
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
EOF
env CFLAGS="-I$ROOT/usr/lib64/libffi/include -I$ROOT/usr/include/ncursesw" \
    CONFIG_SITE=/tmp/config.site \
    ebuild $EBUILD_PATH/dev-lang/python/python-3.10.5.ebuild merge
ebuild $EBUILD_PATH/dev-lang/python-exec-conf/python-exec-conf-2.4.6.ebuild merge
ebuild $EBUILD_PATH/dev-lang/python-exec/python-exec-2.4.9.ebuild merge
ebuild $EBUILD_PATH/sys-apps/portage/portage-3.0.30-r3.ebuild merge
ebuild $EBUILD_PATH/sys-libs/pam/pam-1.5.1_p20210622-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/shadow/shadow-4.11.1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/binutils-config/binutils-config-5.4.1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/binutils/binutils-2.37_p1-r2.ebuild merge
ebuild $EBUILD_PATH/sys-devel/flex/flex-2.6.4-r1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/bison/bison-3.8.2.ebuild merge
ebuild $EBUILD_PATH/dev-libs/gmp/gmp-6.2.1-r2.ebuild merge
ebuild $EBUILD_PATH/dev-libs/mpfr/mpfr-4.1.0_p13-r1.ebuild merge
ebuild $EBUILD_PATH/dev-libs/mpc/mpc-1.2.1.ebuild merge
ebuild $EBUILD_PATH/sys-devel/gcc-config/gcc-config-2.5-r1.ebuild merge
env USE=-fortran ebuild $EBUILD_PATH/sys-devel/gcc/gcc-11.3.0.ebuild merge
ebuild $EBUILD_PATH/sys-devel/gettext/gettext-0.21-r3.ebuild merge
ebuild $EBUILD_PATH/dev-util/pkgconf/pkgconf-1.8.0-r1.ebuild merge
ebuild $EBUILD_PATH/sys-apps/which/which-2.21.ebuild merge
ebuild $EBUILD_PATH/sys-apps/gentoo-functions/gentoo-functions-0.15.ebuild merge
env LDFLAGS=-ltinfo ebuild $EBUILD_PATH/sys-apps/util-linux/util-linux-2.37.4.ebuild merge
ebuild $EBUILD_PATH/app-portage/elt-patches/elt-patches-20211104.ebuild merge
