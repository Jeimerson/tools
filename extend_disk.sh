#!/bin/bash

if [ -f /etc/debian_version ]; then
    OS_ACTUAL=$(lsb_release -i | cut -f2)
    VER=$(lsb_release -r | cut -f2)

elif [ -f /etc/centos-release ]; then
    OS_ACTUAL=Centos
fi

if [ "$OS_ACTUAL" = Debian  ] ; then
    apt install parted lvm2 -y
fi

if [ -e /dev/sda2 ]; then
    sda=3
else
    sda=2
fi

if  [ "$VER" = "16.04" ]; then
    parted /dev/sda --script mkpart primary "$(parted /dev/sda print | grep -E "lvm" | awk '{print $3}') 100%"
else
    parted /dev/sda --script mkpart primary "$(parted /dev/sda print | grep -E "lvm|extended" | awk '{print $3}') 100%"
fi

pvscan --cache
partprobe
vg=$(vgs --noheadings | awk '{print $1}')
pvcreate /dev/sda$sda
vgextend "$vg" /dev/sda$sda
lvextend /dev/"$vg"/root /dev/sda$sda


if [ -f /etc/debian_version ]; then
    resize2fs /dev/"$vg"/root

elif [ "$OS_ACTUAL" = Centos  ] ; then
    xfs_growfs /dev/"$vg"/root
    
fi
