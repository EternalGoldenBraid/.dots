#!/bin/bash

# Script to create and format partitions on a specified device using parted

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
