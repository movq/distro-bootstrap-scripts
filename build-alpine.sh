#!/bin/bash

set -x
set -e

doas apk add --initdb
abuild-keygen -a
doas mkdir -p /etc/apk/keys
doas cp /home/mike/.abuild/*.pub /etc/apk/keys
echo /home/mike/packages/main | doas tee /etc/apk/repositories

cd /home/mike/aports/main/musl
abuild
doas apk add musl musl-dev musl-utils

cd /home/mike/aports/main/binutils
BOOTSTRAP=1 abuild
doas apk add binutils

cd /home/mike/aports/main/bzip2
abuild

cd /home/mike/aports/main/pkgconf
abuild
doas apk add bzip2 bzip2-dev

cd /home/mike/aports/main/perl
abuild
doas apk add perl perl-dev

cd /home/mike/aports/main/m4
abuild

cd /home/mike/aports/main/autoconf
abuild
doas apk add autoconf

cd /home/mike/aports/main/automake
abuild
doas apk add automake

cd /home/mike/aports/main/help2man
abuild
doas apk add help2man

cd /home/mike/aports/main/libtool
abuild
doas apk add libtool

cd /home/mike/aports/main/gmp
abuild
doas apk add gmp-dev

cd /home/mike/aports/main/mpfr4
abuild
doas apk add mpfr-dev

cd /home/mike/aports/main/mpc1
abuild
doas apk add mpc1-dev

cd /home/mike/aports/main/gcc
LANG_ADA=false LANG_D=false LANG_OBJC=false LANG_GO=false LANG_FORTRAN=false abuild
doas apk add gcc g++

cd /home/mike/aports/main/mpdecimal
abuild
doas apk add mpdecimal-dev

cd /home/mike/aports/main/file
abuild

cd /home/mike/aports/main/make
abuild

cd /home/mike/aports/main/fortify-headers
abuild

cd /home/mike/aports/main/patch
abuild

cd /home/mike/aports/main/build-base
abuild
doas apk add build-base

cd /home/mike/aports/main/scdoc
abuild
doas apk add scdoc

cd /home/mike/aports/main/expat
abuild
doas apk add expat-dev

cd /home/mike/aports/main/gdbm
abuild
doas apk add gdbm-dev

cd /home/mike/aports/main/attr
abuild
doas apk add attr

cd /home/mike/aports/main/openssl
abuild # fails
#rm -rf pkg/openssl-dev pkg/openssl-dbg pkg/openssl-doc pkg/openssl-libs-static pkg/openssl-misc
#mkdir pkg/libcrypto3
#abuild rootpkg # wtf?
#cd /home/mike/packages/main/x86_64
#apk index -o APKINDEX.tar.gz *.apk

cd /home/mike/aports/main/python3
abuild
doas apk add python3 python3-dev openssl

cd /home/mike/aports/main/py3-installer
abuild

cd /home/mike/aports/main/py3-gpep517
abuild
doas apk add py3-gpep517

cd /home/mike/aports/main/py3-flit-core
abuild
doas apk add py3-flit-core

cd /home/mike/aports/main/py3-packaging
abuild

cd /home/mike/aports/main/py3-parsing
abuild

cd /home/mike/aports/main/py3-setuptools
abuild
doas apk add py3-setuptools

cd /home/mike/aports/main/samurai
abuild

cd /home/mike/aports/main/linenoise
abuild
doas apk add linenoise-dev

cd /home/mike/aports/main/lua5.3
abuild
doas apk add lua5.3-dev

cd /home/mike/aports/main/lua5.1
abuild
doas apk add lua5.1-dev

cd /home/mike/aports/main/lua5.2
abuild
doas apk add lua5.2-dev

cd /home/mike/aports/main/chrpath
abuild
doas apk add chrpath

cd /home/mike/aports/main/readline
abuild
doas apk add readline-dev

cd /home/mike/aports/main/lua5.4
abuild
doas apk add lua5.4-dev

cd /home/mike/aports/main/zlib
abuild
doas apk add zlib-dev

cd /home/mike/aports/main/lua-lzlib
abuild
doas apk add lua5.3-lzlib

cd /home/mike/aports/main/ca-certificates
abuild

cd /home/mike/aports/main/apk-tools
abuild
doas apk add apk-tools

cd /home/mike/aports/main/libcap
abuild

cd /home/mike/aports/main/lzip
abuild

cd /home/mike/aports/main/perl-module-build
abuild
doas apk add perl-module-build

cd /home/mike/aports/main/perl-pod-parser
abuild
doas apk add perl-pod-parser

cd /home/mike/aports/main/libunistring
abuild
doas apk add libunistring-dev

cd /home/mike/aports/main/libxml2
abuild

cd /home/mike/aports/main/gettext-tiny
abuild
doas apk add gettext-tiny

cd /home/mike/aports/main/xz
abuild
doas apk add libxml2-dev

cd /home/mike/aports/main/gettext
doas apk add musl-libintl
doas apk del musl-libintl
abuild
doas apk del gettext-tiny
doas apk add gettext

cd /home/mike/aports/main/docbook-xsl
abuild

cd /home/mike/aports/main/docbook-xml
abuild

cd /home/mike/aports/main/libxslt
abuild

cd /home/mike/aports/main/skalibs
abuild
doas apk add skalibs-dev skalibs-static

cd /home/mike/aports/main/utmps
abuild
doas apk add utmps-dev utmps-static

cd /home/mike/aports/main/busybox
abuild

doas apk add docbook-xsl

cd /home/mike/aports/main/perl-extutils-cchecker
abuild
doas apk add perl-extutils-cchecker

cd /home/mike/aports/main/perl-class-inspector
abuild
cd /home/mike/aports/main/perl-file-sharedir
abuild
doas apk add perl-file-sharedir

cd /home/mike/aports/main/perl-xs-parse-keyword
abuild
doas apk add perl-xs-parse-keyword

cd /home/mike/aports/main/perl-syntax-keyword-try
abuild

cd /home/mike/aports/main/po4a
abuild
doas apk add po4a

cd /home/mike/aports/main/fakeroot
abuild
doas apk add fakeroot

cd /home/mike/aports/main/tar
abuild
doas apk add tar

cd /home/mike/aports/main/meson
abuild

cd /home/mike/aports/main/flex
abuild
doas apk add flex

cd /home/mike/aports/main/bison
abuild
doas apk add bison

cd /home/mike/aports/main/abuild
abuild

doas apk add abuild-meson

cd /home/mike/aports/main/bsd-compat-headers
abuild

cd /home/mike/aports/main/linux-headers
abuild

cd /home/mike/aports/main/alpine-baselayout
abuild

cd /home/mike/aports/main/ifupdown-ng
ABUILD_BOOTSTRAP=1 abuild

doas apk add ifupdown-any bsd-compat-headers libcap-dev linux-headers

cd /home/mike/aports/main/openrc
abuild
doas apk add openrc

cd /home/mike/aports/main/alpine-conf
ABUILD_BOOTSTRAP=1 abuild

cd /home/mike/aports/main/mdev-conf
ABUILD_BOOTSTRAP=1 abuild

doas apk add alpine-baselayout alpine-conf busybox-mdev-openrc busybox-openrc busybox-suid

cd /home/mike/aports/main/alpine-base
abuild
doas apk add alpine-base

cd /home/mike/aports/main/ncurses
abuild -r
doas apk add ncurses-dev

cd /home/mike/aports/main/bash
abuild -r

cd /home/mike/aports/py3-wheel
abuild

cd /home/mike/aports/py3-elftools
abuild -r

cd /home/mike/aports/main/pax-utils
abuild -r
doas apk add pax-utils
