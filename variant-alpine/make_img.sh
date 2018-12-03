#!/bin/bash

if [ "$(id -u)" -ne "0" ]; then
    echo "This needs to be run as root"
    exit 1
fi

if command -v parted 2>&1 1>/dev/null; [ "$?" -ne "0" ]; then
  echo "'parted' package needs to be installed. If you're on Debian-based system, you can install it with:"
  echo "	sudo apt install -y parted"
  exit 1
fi

# Creates a zipped & partitioned image file for burning onto SD cards
# 256MB bootable FAT32L partition with official Alpine linux and lncm box
# Make sure "parted", "dosfstools" and "zip" are installed

if ! [ -d lncm-workdir ]; then
  mkdir lncm-workdir
fi
cd lncm-workdir
ALP=alpine-rpi-3.8.1-armhf.tar.gz
BOX=lncm-box-v0.2.1.tar.gz
IMG=lncm-box-v0.2.1.img
MNT=/mnt/lncm
# Check if already downloaded. Don't download again
if ! [ -f $ALP ]; then
  wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/${ALP}
fi
if ! [ -f $BOX ]; then
  wget https://github.com/lncm/pi-factory/releases/download/v0.2.1/${BOX}
fi
dd if=/dev/zero of=$IMG bs=1M count=256
DEV=$(losetup -f --show $IMG)
parted -s $DEV mklabel msdos mkpart p fat32 2048s 100% set 1 boot on
parted -s $DEV print
mkfs.vfat ${DEV}p1 -IF 32
if ! [ -d $MNT ]; then
  mkdir $MNT
fi
mount ${DEV}p1 $MNT
tar -xzf $ALP -C ${MNT}/ --no-same-owner
tar -xzf $BOX -C ${MNT}/ --no-same-owner
sync
umount $MNT
losetup -d ${DEV}
zip -r ${IMG}.zip $IMG
