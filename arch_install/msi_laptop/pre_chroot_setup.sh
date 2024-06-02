#!/bin/bash

### Create, format and mount partitions

# Script to create and format partitions on a specified device using parted
swap_size=12G
create_swapfile=true
# root_size=30G

cpu_manufacturer=intel
# cpu_manufacturer=amd

# Exit on any error
set -e

# Check if the device parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi
# Device to partition
DEVICE=$1

# Validate the device
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device."
    exit 1
fi

# Unmount any mounted partitions of the device
for PART in $(ls ${DEVICE}* 2>/dev/null); do
    if mount | grep -q ${PART}; then
        echo "Unmounting $PART..."
        umount ${PART}
    fi
done

# Create partition table
echo "Creating new GPT partition table on $DEVICE..."
parted -s $DEVICE mklabel gpt

# Create partitions
echo "Creating partitions..."
parted -s $DEVICE -- mkpart primary fat32 1MiB 513MiB
parted -s $DEVICE -- set 1 esp on
parted -s $DEVICE -- mkpart primary ext4 513MiB 1025MiB
parted -s $DEVICE -- mkpart primary ext4 1025MiB 43025MiB
parted -s $DEVICE -- mkpart primary ext4 43025MiB 100%

# Wait for the kernel to recognize the new partitions
sleep 2

# Format the EFI partition
echo "Formatting the EFI partition..."
mkfs.fat -F 32 ${DEVICE}p1

# Format the Linux filesystem partitions
echo "Formatting Linux filesystem partitions..."
mkfs.ext4 ${DEVICE}p2
mkfs.ext4 ${DEVICE}p3
mkfs.ext4 ${DEVICE}p4

echo "Partitioning and formatting complete."

if [ "$create_swapfile" = true ]; then
    echo "Creating swap file..."
    mkswap -U clear --size $swap_size /swapfile
fi

# Function to mount a partition with error checking
mount_partition() {
    local partition=$1
    local mount_point=$2

    echo "Mounting $partition on $mount_point..."
    if ! mount --mkdir $partition $mount_point; then
        echo "Failed to mount $partition on $mount_point. Exiting."
        exit 1
    fi
}

mount_partition /dev/nvme0n1p1 /mnt/boot/efi
mount_partition /dev/nvme0n1p2 /mnt/boot
mount_partition /dev/nvme0n1p3 /mnt
mount_partition /dev/nvme0n1p4 /mnt/home
echo "All partitions mounted successfully."
 
# Pacstrap defaults
pacstrap -K /mnt base base-devel linux linux-firmware ${cpu_manufacturer}-ucode\
    sway swaylock swayidle waybar wofi \
    networkmanager network-manager-applet nm-connection-editor \
    neovim vim vifm \
    obsidian

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "Pacstrap complete. Run arch-chroot /mnt and continue installation with chrooted_setup.sh"
