#!/bin/sh

set -ex

MULTILIB=$1

# Environment
set +h
umask 022
LC_ALL=POSIX
CHOST=x86_64-boot1-linux-gnu
PATH=/usr/bin:/usr/sbin:/bin:/sbin:
export LC_ALL CHOST PATH CONFIG_SITE

# Convenience variables
UNTAR="tar --no-same-owner -xf"

# Version numbers
GCC_VERSION=10.4.0
GLIBC_VERSION=2.28
BASH=5.1.16
GETTEXT=0.21
BISON=3.8.2
PERL=5.34.0
PYTHON=3.10.2
TEXINFO=6.8

# Directory structure
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
portage:x:250:250:portage:/var/tmp/portage:/bin/false
EOF

cat > /etc/group << "EOF"
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
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
portage::250:portage
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

cd /usr/src
find . -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;

# for some reason, there are strange errors from getcwd
# when building various packages which goes away with a bash rebuild.
$UNTAR bash-$BASH.tar.gz
cd bash-$BASH
./configure --prefix=/usr                   \
            --without-bash-malloc \
            --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf bash-$BASH

# libstdc++ pass 2
$UNTAR gcc-$GCC_VERSION.tar.xz
cd gcc-$GCC_VERSION
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir build; cd build

if [ $MULTILIB -eq 1 ]
then
    extra_flags="--enable-multilib"
else
    extra_flags="--disable-multilib"
fi

../libstdc++-v3/configure            \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
    --prefix=/usr                    \
    --disable-nls                    \
    --build=$CHOST \
    --host=$CHOST \
    --disable-libstdcxx-pch \
    --libdir=/usr/lib64              \
    $extra_flags
make -j8
make install
cd /usr/src
rm -rf gcc-$GCC_VERSION

# gettext
$UNTAR gettext-$GETTEXT.tar.xz
cd gettext-$GETTEXT
./configure --disable-shared --libdir=/usr/lib64
make -j8
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd /usr/src
rm -rf gettext-$GETTEXT

# bison
$UNTAR bison-$BISON.tar.xz
cd bison-$BISON
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-$BISON \
    --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf bison-$BISON

# perl
$UNTAR perl-$PERL.tar.xz
cd perl-$PERL
PERL_MINOR=$(echo $PERL | awk -F '.' '{print $1"."$2}')
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib64/perl5/$PERL_MINOR/core_perl     \
             -Darchlib=/usr/lib64/perl5/$PERL_MINOR/core_perl     \
             -Dsitelib=/usr/lib64/perl5/$PERL_MINOR/site_perl     \
             -Dsitearch=/usr/lib64/perl5/$PERL_MINOR/site_perl    \
             -Dvendorlib=/usr/lib64/perl5/$PERL_MINOR/vendor_perl \
             -Dvendorarch=/usr/lib64/perl5/$PERL_MINOR/vendor_perl
make -j8
make install
cd /usr/src
rm -rf perl-$PERL

# python
$UNTAR Python-$PYTHON.tar.xz
cd Python-$PYTHON
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip \
            --libdir=/usr/lib64
make -j8
make install
mv -v /usr/lib64/python3*/* /usr/lib/python3*
cd /usr/src
rm -rf Python-$PYTHON

# texinfo
$UNTAR texinfo-$TEXINFO.tar.xz
cd texinfo-$TEXINFO
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/usr --libdir=/usr/lib64
make -j8
make install
cd /usr/src
rm -rf texinfo-$TEXINFO

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,lib64,libexec} -name \*.la -delete
rm -rf /tools
