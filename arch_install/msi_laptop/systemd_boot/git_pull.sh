#!/bin/bash

pushd ~/.dots
git stash; git pull; 
umount \
    /dev/nvme0n1p1 \
    /dev/nvme0n1p3 \
    /dev/nvme0n1p2

ln -s ~/.dots/arch_install/msi_laptop/systemd_boot/*.sh ~/.
popd
