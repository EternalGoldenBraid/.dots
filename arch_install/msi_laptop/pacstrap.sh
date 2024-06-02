#!/bin/bash

# Check /mnt is mounted
if ! mount | grep -q /mnt; then
    echo "Error: /mnt is not mounted."
    exit 1
fi

# microcode="amd-ucode"
microcode="intel-ucode"
# Pacstrap defaults
pacstrap -K /mnt base base-devel linux linux-firmware $microcode \
    sway swaylock swayidle waybar wofi \
    networkmanager network-manager-applet nm-connection-editor \
    neovim vim vifm \
    obsidian

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "Pacstrap complete. Run arch-chroot /mnt to continue installation."
