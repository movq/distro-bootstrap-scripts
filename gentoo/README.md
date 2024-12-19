# Bootstrap Scripts

Hacky scripts for bootstrapping Gentoo via
[live-bootstrap](https://github.com/fosslinux/live-bootstrap).

## 1. Run live-booststrap.

```
cp -r --reflink=always ~/src/sysa_distfiles sysa/distfiles
cp -r --reflink=always ~/src/sysc_distfiles sysc/distfiles
cp -r sysa/stage0-posix/src/* .
cp sysa/after.kaem after.kaem
bwrap --unshare-net --unshare-user --uid 0 --gid 0 --cap-add CAP_SYS_CHROOT --clearenv --setenv PATH /usr/bin --bind . / --dir /dev --dev-bind /dev/null /dev/null --dev-bind /dev/zero /dev/zero --dev-bind /dev/random /dev/random --dev-bind /dev/urandom /dev/urandom --dir /sysc_image/dev --dev-bind /dev/null /sysc_image/dev/null --dev-bind /dev/zero /sysc_image/dev/zero --dev-bind /dev/random /sysc_image/dev/random --dev-bind /dev/urandom /sysc_image/dev/urandom --proc /sysc_image/proc --bind /sys /sysc_image/sys --tmpfs /sysc_image/tmp bootstrap-seeds/POSIX/x86/kaem-optional-seed
```

## 2. run LFS bootstrap with GCC 10.4.0, GLIBC 2.28 and Binutils 2.37

GCC 10 is the last release that can be built with the GCC 4 provided
by live-bootstrap.

glibc 2.28 is the last release that doesn't require Python (wtf?) to
build.

Copy `bootstrap1.sh` into `sysc_image`. Shell into it using bwrap:
```
bwrap --bind ~/sysc_image/ / --dev-bind /dev /dev --dev-bind /proc /proc --dev-bind /sys /sys --bind ~/src/tarballs /usr/src --uid 0 --gid 0 --clearenv --setenv PATH /usr/bin:/usr/sbin --setenv PS1 "\w # " --setenv TERM xterm-256color /bin/bash --login
```
Run bootstrap1.sh. Wait.

Move `/sysc_image/target` to `~/boot1`
Copy `bootstrap2.sh` and `bootstrap3.sh` into `~/boot1`.
bwrap into it again and run both scripts.

re-run this process but with GCC 11.3.0, glibc 2.34 and binutils 2.37, and change
CHOST/CBUILD boot1->boot2

Ideally we'd just upgrade glibc/gcc in-place, but I can't figure out how to
do this without glibc causing everything to segfault.

## 3. Fetch portage tree and apply hacks

* `python-any-r1.eclass`: python_setup() return 0 immediately
* `autotools.eclass` line 535 if [[ true ]] ; then
* `glibc.ebuild` 32-bit test: 749 STAT=0

## 4. run gentoo.sh

This time, we need to use chroot, so do a sudo chown -R 0:0 `~/boot2`.

This script just builds a cross-compiler then uses `ebuild` to manually merge
a bunch of fundamental packages (derived from LFS initial package list +
packages.build in gentoo profile via a painstaking manual process of trying
each package and resolving dependency issues).

Chroot into new system. Python ctypes isn't linked to libffi for some reason,
and so we need:

```
export LD_PRELOAD=/usr/lib64/libffi.so.8.1.0

```

Binutils symlinks are missing and binutils-config doesn't work, so:

Remerge glibc (limits.h seems fucked)
Merge python.
