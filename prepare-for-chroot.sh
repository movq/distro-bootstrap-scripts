#!/bin/bash

echo permit nopass mike as root > rootfs/etc/doas.conf
cp /etc/ssl/certs/ca-certificates.crt ./rootfs/etc/ssl/certs
ln -s certs/ca-certificates.crt rootfs/etc/ssl/cert.pem
mkdir -p ./rootfs/home/mike
mkdir -p ./rootfs/var/cache/distfiles
sudo chown -R root:root rootfs
sudo chown mike:mike rootfs/home/mike rootfs/var/cache/distfiles
sudo chmod u+s rootfs/usr/bin/busybox
sudo chmod u+s rootfs/usr/bin/doas
sudo chmod go-w rootfs/etc/doas.conf
git clone https://git.movq.org/mike/aports.git -b bootstrap rootfs/home/mike/aports
