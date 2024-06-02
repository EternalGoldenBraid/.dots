#!/bin/bash

set -e

add_resume_hook() {

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

# Set root password
echo "Set root password..."
passwd
