#!/bin/sh
LFS=$PWD/rootfs

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
cp /etc/resolv.conf $LFS/etc/resolv.conf

env -i PATH=/usr/bin TERM=xterm-256color HOME=/root /usr/sbin/chroot $LFS /bin/bash

umount $LFS/run
umount $LFS/sys
umount $LFS/proc
umount $LFS/dev/pts
umount $LFS/dev
