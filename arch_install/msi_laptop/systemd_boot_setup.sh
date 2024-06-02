#!/bin/bash
set -e

echo "Installing systemd-boot..."
bootctl --path=/boot install

echo "Configuring loader entries..."
# Create loader.conf
cat <<EOF > /boot/loader/loader.conf
default arch.conf
timeout 4
console-mode max
editor no
EOF

# Create arch.conf
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2) resume=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2) resume_offset=$(filefrag -v /swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}') rw
EOF

echo "Systemd-boot installation complete."
