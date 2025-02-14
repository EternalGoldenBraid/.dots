#!/bin/bash

set -e

add_resume_hook() {
    ### Add resume hook to mkinitcpio configuration 
    ### for suspend-to-disk support

    # Ensure the script is run as root
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 
       exit 1
    fi
    
    # Backup the original configuration file
    cp $CONFIG_FILE $BACKUP_FILE
    
    # Insert 'resume' after 'filesystems' in the HOOKS line
    sed -i "/^HOOKS=/ s/\(filesystems\)/\1 resume/" $CONFIG_FILE
    
    # Check if the change was successful
    if grep -q "resume" $CONFIG_FILE; then
        echo "Resume hook added successfully."
    else
        echo "Failed to add resume hook."
        exit 1
    fi
    
    # Regenerate initramfs
    mkinitcpio -P
    echo "Initramfs regenerated."
}

### Add resume hook to mkinitcpio configuration for suspend-to-disk support

# Path to mkinitcpio configuration
CONFIG_FILE="/etc/mkinitcpio.conf"
BACKUP_FILE="/etc/mkinitcpio.conf.backup"
hostname="forest-wizard"
is_swapfile=true # Should match pre_chroot script

if [ "$is_swapfile" = true ]; then
    add_resume_hook
else
    echo "No swapfile detected. Not adding resume hook."
fi

# Set the timezone
echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
hwclock --systohc

# Generate locales
echo "Generating locales..."
echo "fi_FI.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Set hostname
echo "Setting hostname..."
echo $hostname > /etc/hostname

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

# Set root password
echo "Set root password..."
passwd

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
HOME=/home/$USER_NAME
DOT_DIR=${HOME}/.dotfiles

# Create a new user
echo "Creating user $USER_NAME..."
mkdir -p /home/$USER_NAME
useradd -m -G wheel -s /bin/bash $USER_NAME

# Add the new user to the sudoers file via visudo
echo "Adding $USER_NAME to the sudoers file..."
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers

# Set password for the new user
echo "Set password for $USER_NAME..."
passwd $USER_NAME

git clone https://github.com/EternalGoldenBraid/.dots ${DOT_DIR}
mv $HOME/.dots $HOME/.dotfiles
