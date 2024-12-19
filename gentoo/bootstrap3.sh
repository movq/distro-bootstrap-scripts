#!/bin/sh

set -ex

MULTILIB=$1

LC_ALL=POSIX
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LC_ALL PATH

CHOST=x86_64-pc-linux-gnu

# Convenience variables
UNTAR="tar --no-same-owner -xf"

# Version numbers
GCC_VERSION=10.4.0
GLIBC_VERSION=2.28
IANA_ETC=20220207
TZDATA=2021e
ZLIB=1.2.12
BZIP2=1.0.8
XZ=5.2.5
ZSTD=1.5.2
FILE=5.41
READLINE=8.1.2
M4=1.4.19
BC=5.2.2
FLEX=2.6.4
TCL=8.6.12
EXPECT=5.45.4
BINUTILS=2.37
GMP=6.2.1
MPFR=4.1.0
MPC=1.2.1
ATTR=2.5.1
ACL=2.3.1
LIBCAP=2.63
SHADOW=4.11.1
PKG_CONFIG=0.29.2
NCURSES=6.3
SED=4.8
PSMISC=23.4
GETTEXT=0.21
BISON=3.8.2
GREP=3.7
BASH=5.1.16
LIBTOOL=2.4.6
GDBM=1.23
GPERF=3.1
EXPAT=2.4.6
INETUTILS=2.2
LESS=590
PERL=5.34.0
XML_PARSER=2.46
INTLTOOL=0.51.0
AUTOCONF=2.71
AUTOCONF_ARCHIVE=2022.02.11
AUTOMAKE=1.16.5
ELFUTILS=0.186
LIBFFI=3.4.2
OPENSSL=3.0.1
PYTHON=3.10.2
NINJA=1.10.2
MESON=0.61.1
COREUTILS=9.0
DIFFUTILS=3.8
GAWK=5.1.1
FINDUTILS=4.9.0
GROFF=1.22.4
GZIP=1.11
LIBPIPELINE=1.5.5
MAKE=4.3
PATCH=2.7.6
TAR=1.34
TEXINFO=6.8
VIM=8.2.4383
LIBTASN1=4.18.0
P11_KIT=0.24.1
MAKE_CA=1.10
WGET=1.21.2
PORTAGE=3.0.30
ELT_PATCHES=20211104
UTIL_LINUX=2.37.4
RSYNC=3.2.4
PAX_UTILS=1.3.4
GENTOO_FUNCTIONS=0.15

cd /usr/src
find . -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;

$UNTAR iana-etc-$IANA_ETC.tar.gz
cd iana-etc-$IANA_ETC
cp services protocols /etc
cd /usr/src
rm -rf iana-etc-$IANA_ETC

$UNTAR glibc-$GLIBC_VERSION.tar.xz
cd glibc-$GLIBC_VERSION
mkdir build; cd build
echo "rootsbindir=/sbin" > configparms

if [ $MULTILIB -eq 1]
then
    extra_flags="--enable-multi-arch"
else
    extra_flags=""
fi

../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=5.15                     \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             --libdir=/usr/lib64 \
             libc_cv_slibdir=/lib64 \
             libc_cv_complocaledir=/usr/lib/locale    \
             $extra_flags
make -j8
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i en_GB -f UTF-8 en_GB.UTF-8
cat > /etc/nsswitch.conf << "EOF"
passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
EOF
tar -xf ../../tzdata$TZDATA.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done
cp zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
ln -sfv /usr/share/zoneinfo/Europe/London /etc/localtime
cat > /etc/ld.so.conf << "EOF"
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -p /etc/ld.so.conf.d

if [ $MULTILIB -eq 1 ]
then
    cd ..
    rm -rf build
    mkdir build; cd build
    env CC="$CHOST-gcc -m32" CXX="$CHOST-g++ -m32" \
    ../configure --prefix=/usr                            \
                 --host=i686-pc-linux-gnu                 \
                 --build=$CHOST                           \
                 --disable-werror                         \
                 --enable-kernel=5.15                     \
                 --with-headers=/usr/include              \
                 --enable-multi-arch                      \
                 --libdir=/usr/lib \
                 libc_cv_slibdir=/lib \
                 libc_cv_complocaledir=/usr/lib/locale
    make -j8
    make DESTDIR=$PWD/DESTDIR install
    cp -av DESTDIR/lib/. $ROOT/lib
    cp -av DESTDIR/usr/lib/. $ROOT/usr/lib
    install -vm644 DESTDIR/usr/include/gnu/{lib-names,stubs}-32.h /usr/include/gnu/
fi
cd /usr/src
rm -rf glibc-$GLIBC_VERSION

$UNTAR zlib-$ZLIB.tar.xz
cd zlib-$ZLIB
./configure --prefix=/usr --libdir=/usr/lib64
make -j8
make install
rm -f /usr/lib64/libz.a
cd /usr/src
rm -rf zlib-$ZLIB

$UNTAR bzip2-$BZIP2.tar.gz
cd bzip2-$BZIP2
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -j8 -f Makefile-libbz2_so
make clean
make -j8
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib64
ln -sfv libbz2.so.$BZIP2 /usr/lib64/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib64/libbz2.a
rm -fv /usr/lib/libbz2.a
cd /usr/src
rm -rf bzip2-$BZIP2

$UNTAR xz-$XZ.tar.xz
cd xz-$XZ
./configure --prefix=/usr    \
            --docdir=/usr/share/doc/xz-$XZ \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf xz-$XZ

$UNTAR zstd-$ZSTD.tar.gz
cd zstd-$ZSTD
make -j8
make prefix=/usr libdir=/usr/lib64 install
rm /usr/lib64/libzstd.a
cd /usr/src
rm -rf zstd-$ZSTD

$UNTAR file-$FILE.tar.gz
cd file-$FILE
./configure --prefix=/usr --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf file-$FILE

$UNTAR readline-$READLINE.tar.gz
cd readline-$READLINE
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.1 \
            --libdir=/usr/lib64
make -j8 SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
cd /usr/src
rm -rf readline-$READLINE

$UNTAR m4-$M4.tar.xz
cd m4-$M4
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf m4-$M4

$UNTAR bc-$BC.tar.xz
cd bc-$BC
CC=gcc ./configure --prefix=/usr --libdir=/usr/lib64 -G -O3
make -j8
make install
cd /usr/src
rm -rf bc-$BC

$UNTAR flex-$FLEX.tar.gz
cd flex-$FLEX
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-$FLEX \
            --libdir=/usr/lib64
make -j8
make install
ln -sfv flex /usr/bin/lex
cd /usr/src
rm -rf flex-$FLEX

$UNTAR tcl$TCL-src.tar.gz
cd tcl$TCL
$UNTAR ../tcl$TCL-html.tar.gz --strip-components=1
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --enable-64bit \
            --libdir=/usr/lib64
make -j8
# what the fuck
sed -e "s|$SRCDIR/unix|/usr/lib64|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.3|/usr/lib64/tdbc1.1.3|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/library|/usr/lib64/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3|/usr/include|"            \
    -i pkgs/tdbc1.1.3/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.2|/usr/lib64/itcl4.2.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.2|/usr/include|"            \
    -i pkgs/itcl4.2.2/itclConfig.sh
unset SRCDIR
make install
chmod -v u+w /usr/lib64/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd /usr/src
rm -rf tcl$TCL

$UNTAR expect$EXPECT.tar.gz
cd expect$EXPECT
./configure --prefix=/usr           \
            --with-tcl=/usr/lib64   \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include \
            --libdir=/usr/lib64
make -j8
make install
ln -svf expect$EXPECT/libexpect$EXPECT.so /usr/lib64
cd /usr/src
rm -rf expect$EXPECT

# skip dejagnu

$UNTAR binutils-$BINUTILS.tar.xz
cd binutils-$BINUTILS
#patch -Np1 -i ../binutils-2.37-upstream_fix-1.patch
mkdir build; cd build
if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib"
else
    extra_flags="--disable-multilib"
fi
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib  \
             --build=$CHOST      \
             --target=$CHOST     \
             --host=$CHOST \
             --libdir=/usr/lib64 \
             $extra_flags
make -j8 tooldir=/usr
make tooldir=/usr install
rm -fv /usr/lib64/lib{bfd,ctf,ctf-nobfd,opcodes}.a
cd /usr/src
rm -rf binutils-$BINUTILS

$UNTAR gmp-$GMP.tar.xz
cd gmp-$GMP
./configure --prefix=/usr    \
            --enable-cxx     \
            --docdir=/usr/share/doc/gmp-$GMP \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf gmp-$GMP

$UNTAR mpfr-$MPFR.tar.xz
cd mpfr-$MPFR
./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-$MPFR \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf mpfr-$MPFR

$UNTAR mpc-$MPC.tar.gz
cd mpc-$MPC
./configure --prefix=/usr    \
            --docdir=/usr/share/doc/mpc-$MPC \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf mpc-$MPC

$UNTAR attr-$ATTR.tar.gz
cd attr-$ATTR
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-$ATTR \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf attr-$ATTR

$UNTAR acl-$ACL.tar.xz
cd acl-$ACL
./configure --prefix=/usr         \
            --docdir=/usr/share/doc/acl-$ACL \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf acl-$ACL

$UNTAR libcap-$LIBCAP.tar.xz
cd libcap-$LIBCAP
sed -i '/install -m.*STA/d' libcap/Makefile
make -j8 prefix=/usr lib=lib64
make prefix=/usr lib=lib64 install
chmod -v 755 /usr/lib64/lib{cap,psx}.so.$LIBCAP
cd /usr/src
rm -rf libcap-$LIBCAP

$UNTAR shadow-$SHADOW.tar.xz
cd shadow-$SHADOW
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
    -i etc/login.defs
sed -e "224s/rounds/min_rounds/" -i libmisc/salt.c
touch /usr/bin/passwd
./configure --sysconfdir=/etc \
            --with-group-name-max-length=32 \
            --libdir=/usr/lib64
make -j8
make exec_prefix=/usr install
mkdir -p /etc/default
useradd -D --gid 999
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
cd /usr/src
rm -rf shadow-$SHADOW

$UNTAR gcc-$GCC_VERSION.tar.xz
cd gcc-$GCC_VERSION
sed -e '/static.*SIGSTKSZ/d' \
    -e 's/return kAltStackSize/return SIGSTKSZ * 4/' \
    -i libsanitizer/sanitizer_common/sanitizer_posix_libcdep.cpp
mkdir build; cd build

if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib --with-multilib-list=m64,m32"
else
    extra_flags="--disable-multilib"
fi
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --disable-bootstrap      \
             --with-system-zlib       \
             --build=$CHOST           \
             --host=$CHOST            \
             --target=$CHOST          \
             $extra_flags
make -j8
make install
rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/$GCC_VERSION/include-fixed/bits/
ln -sfvr /usr/bin/cpp /usr/lib
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/$GCC_VERSION/liblto_plugin.so \
        /usr/lib64/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib64/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /usr/src
rm -rf gcc-$GCC_VERSION

$UNTAR pkg-config-$PKG_CONFIG.tar.gz
cd pkg-config-$PKG_CONFIG
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-$PKG_CONFIG \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf pkg-config-$PKG_CONFIG

$UNTAR ncurses-$NCURSES.tar.gz
cd ncurses-$NCURSES
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib64/pkgconfig \
            --enable-widec          \
            --libdir=/usr/lib64
make -j8
make install
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib64/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib64/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib64/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib64/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib64/libcursesw.so
ln -sfv libncurses.so      /usr/lib64/libcurses.so
rm -fv /usr/lib64/libncurses++w.a
cd /usr/src
rm -rf ncurses-$NCURSES

$UNTAR sed-$SED.tar.xz
cd sed-$SED
./configure --prefix=/usr --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf sed-$SED

$UNTAR psmisc-$PSMISC.tar.xz
cd psmisc-$PSMISC
./configure --prefix=/usr --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf psmisc-$PSMISC

$UNTAR gettext-$GETTEXT.tar.xz
cd gettext-$GETTEXT
./configure --prefix=/usr    \
            --docdir=/usr/share/doc/gettext-$GETTEXT \
            --libdir=/usr/lib64
make -j8
make install
chmod -v 0755 /usr/lib64/preloadable_libintl.so
cd /usr/src
rm -rf gettext-$GETTEXT

$UNTAR bison-$BISON.tar.xz
cd bison-$BISON
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-$BISON \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf bison-$BISON

$UNTAR grep-$GREP.tar.xz
cd grep-$GREP
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf grep-$GREP

$UNTAR bash-$BASH.tar.gz
cd bash-$BASH
./configure --prefix=/usr                      \
            --docdir=/usr/share/doc/bash-$BASH \
            --without-bash-malloc              \
            --with-installed-readline          \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf bash-$BASH

$UNTAR libtool-$LIBTOOL.tar.xz
cd libtool-$LIBTOOL
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
rm -fv /usr/lib64/libltdl.a
cd /usr/src
rm -rf libtool-$LIBTOOL

$UNTAR gdbm-$GDBM.tar.gz
cd gdbm-$GDBM
./configure --prefix=/usr    \
            --enable-libgdbm-compat \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf gdbm-$GDBM

$UNTAR gperf-$GPERF.tar.gz
cd gperf-$GPERF
./configure --prefix=/usr \
            --docdir=/usr/share/doc/gperf-$GPERF \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf gperf-$GPERF

$UNTAR expat-$EXPAT.tar.xz
cd expat-$EXPAT
./configure --prefix=/usr    \
            --docdir=/usr/share/doc/expat-$EXPAT \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf expat-$EXPAT

$UNTAR inetutils-$INETUTILS.tar.xz
cd inetutils-$INETUTILS
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers \
            --libdir=/usr/lib64
make -j8
make install
mv -v /usr/{,s}bin/ifconfig
cd /usr/src
rm -rf inetutils-$INETUTILS

$UNTAR less-$LESS.tar.gz
cd less-$LESS
./configure --prefix=/usr --sysconfdir=/etc \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf less-$LESS

$UNTAR perl-$PERL.tar.xz
cd perl-$PERL
patch -Np1 -i ../perl-$PERL-upstream_fixes-1.patch
export BUILD_ZLIB=False
export BUILD_BZIP2=0
PERL_MINOR=$(echo $PERL | awk -F '.' '{print $1"."$2}')
sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib64/perl5/$PERL_MINOR/core_perl      \
             -Darchlib=/usr/lib64/perl5/$PERL_MINOR/core_perl      \
             -Dsitelib=/usr/lib64/perl5/$PERL_MINOR/site_perl      \
             -Dsitearch=/usr/lib64/perl5/$PERL_MINOR/site_perl     \
             -Dvendorlib=/usr/lib64/perl5/$PERL_MINOR/vendor_perl  \
             -Dvendorarch=/usr/lib64/perl5/$PERL_MINOR/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads
make -j8
make install
unset BUILD_ZLIB
unset BUILD_BZIP2
cd /usr/src
rm -rf perl-$PERL

$UNTAR XML-Parser-$XML_PARSER.tar.gz
cd XML-Parser-$XML_PARSER
perl Makefile.PL
make -j8
make install
cd /usr/src
rm -rf XML-Parser-$XML_PARSER

$UNTAR intltool-$INTLTOOL.tar.gz
cd intltool-$INTLTOOL
# what the fuck
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf intltool-$INTLTOOL

$UNTAR autoconf-$AUTOCONF.tar.xz
cd autoconf-$AUTOCONF
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf autoconf-$AUTOCONF

$UNTAR autoconf-archive-$AUTOCONF_ARCHIVE.tar.xz
cd autoconf-archive-$AUTOCONF_ARCHIVE
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf autoconf-archive-$AUTOCONF_ARCHIVE

$UNTAR automake-$AUTOMAKE.tar.xz
cd automake-$AUTOMAKE
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.4 \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf automake-$AUTOMAKE

$UNTAR elfutils-$ELFUTILS.tar.bz2
cd elfutils-$ELFUTILS
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy \
            --libdir=/usr/lib64
make -j8
make -C libelf install
install -vm644 config/libelf.pc /usr/lib64/pkgconfig
rm /usr/lib64/libelf.a
cd /usr/src
rm -rf elfutils-$ELFUTILS

$UNTAR libffi-$LIBFFI.tar.gz
cd libffi-$LIBFFI
./configure --prefix=/usr          \
            --with-gcc-arch=native \
            --disable-exec-static-tramp \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf libffi-$LIBFFI

$UNTAR openssl-$OPENSSL.tar.gz
cd openssl-$OPENSSL
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib64          \
         shared                \
         zlib-dynamic
make -j8
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
cd /usr/src
rm -rf openssl-$OPENSSL

$UNTAR Python-$PYTHON.tar.xz
cd Python-$PYTHON
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --with-ensurepip=yes \
            --enable-optimizations \
            --libdir=/usr/lib64
make -j8
make install
mv -v /usr/lib64/python3*/* /usr/lib/python3*/
ln -s /usr/bin/python3 /usr/bin/python
cd /usr/src
rm -rf Python-$PYTHON

$UNTAR ninja-$NINJA.tar.gz
cd ninja-$NINJA
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd /usr/src
rm -rf ninja-$NINJA

$UNTAR meson-$MESON.tar.gz
cd meson-$MESON
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
cd /usr/src
rm -rf meson-$MESON

$UNTAR coreutils-$COREUTILS.tar.xz
cd coreutils-$COREUTILS
patch -Np1 -i ../coreutils-9.0-i18n-1.patch
patch -Np1 -i ../coreutils-9.0-chmod_fix-1.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime \
            --libdir=/usr/lib64
make -j8
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
cd /usr/src
rm -rf coreutils-$COREUTILS

$UNTAR diffutils-$DIFFUTILS.tar.xz
cd diffutils-$DIFFUTILS
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf diffutils-$DIFFUTILS

$UNTAR gawk-$GAWK.tar.xz
cd gawk-$GAWK
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf gawk-$GAWK

$UNTAR findutils-$FINDUTILS.tar.xz
cd findutils-$FINDUTILS
./configure --prefix=/usr --localstatedir=/var/lib/locate \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf findutils-$FINDUTILS

$UNTAR groff-$GROFF.tar.gz
cd groff-$GROFF
PAGE=A4 ./configure --prefix=/usr \
            --libdir=/usr/lib64
make
make install
cd /usr/src
rm -rf groff-$GROFF

$UNTAR gzip-$GZIP.tar.xz
cd gzip-$GZIP
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf gzip-$GZIP

$UNTAR libpipeline-$LIBPIPELINE.tar.gz
cd libpipeline-$LIBPIPELINE
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf libpipeline-$LIBPIPELINE

$UNTAR make-$MAKE.tar.gz
cd make-$MAKE
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf make-$MAKE

$UNTAR patch-$PATCH.tar.xz
cd patch-$PATCH
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf patch-$PATCH

$UNTAR tar-$TAR.tar.xz
cd tar-$TAR
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf tar-$TAR

$UNTAR texinfo-$TEXINFO.tar.xz
cd texinfo-$TEXINFO
./configure --prefix=/usr \
            --libdir=/usr/lib64
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
make -j8
make install
cd /usr/src
rm -rf texinfo-$TEXINFO

$UNTAR vim-$VIM.tar.gz
cd vim-$VIM
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
cd /usr/src
rm -rf vim-$VIM

$UNTAR libtasn1-$LIBTASN1.tar.gz
cd libtasn1-$LIBTASN1
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf libtasn1-$LIBTASN1

echo "nameserver 8.8.8.8" > /etc/resolv.conf
$UNTAR p11-kit-$P11_KIT.tar.xz
cd p11-kit-$P11_KIT
sed '20,$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Generate a new trust store
/usr/sbin/make-ca -r
EOF
mkdir meson-build; cd meson-build
meson --prefix=/usr       \
      --buildtype=release \
      --libdir=/usr/lib64 \
      -Dtrust_paths=/etc/pki/anchors
ninja -j8
ninja install
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib64/libnssckbi.so
cd /usr/src
rm -rf p11-kit-$P11_KIT

$UNTAR make-ca-$MAKE_CA.tar.xz
cd make-ca-$MAKE_CA
make install
install -vdm755 /etc/ssl/local
/usr/sbin/make-ca -g
cd /usr/src
rm -rf make-ca-$MAKE_CA

$UNTAR wget-$WGET.tar.gz
cd wget-$WGET
./configure --prefix=/usr --with-ssl=openssl \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf wget-$WGET

$UNTAR portage-$PORTAGE.tar.bz2
cd portage-$PORTAGE
python3 setup.py build
python3 setup.py install
cd /usr/src
rm -rf portage-$PORTAGE

$UNTAR elt-patches-$ELT_PATCHES.tar.xz
cd elt-patches-$ELT_PATCHES
make
make install
cd /usr/src
rm -rf elt-patches-$ELT_PATCHES

$UNTAR util-linux-$UTIL_LINUX.tar.xz
cd util-linux-$UTIL_LINUX
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib64    \
            --docdir=/usr/share/doc/util-linux-$UTIL_LINUX \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --without-python     \
            runstatedir=/run
make -j8
make install || true # fails in bwrap sandbox
cd /usr/src
rm -rf util-linux-$UTIL_LINUX

$UNTAR rsync-$RSYNC.tar.gz
cd rsync-$RSYNC
./configure --prefix=/usr --disable-xxhash --disable-lz4 \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf rsync-$RSYNC

$UNTAR pax-utils-$PAX_UTILS.tar.xz
cd pax-utils-$PAX_UTILS
./configure --prefix=/usr \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf pax-utils-$PAX_UTILS

$UNTAR gentoo-functions-$GENTOO_FUNCTIONS.tar.gz
cd $GENTOO_FUNCTIONS
make
make install
cd /usr/src
rm -rf $GENTOO_FUNCTIONS
