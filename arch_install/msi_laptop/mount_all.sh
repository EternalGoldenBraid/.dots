#!/bin/bash

# Script to mount partitions for an Arch Linux installation

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

# Mount the EFI system partition
mount_partition /dev/nvme0n1p1 /mnt/boot/efi

# Mount the Boot partition
mount_partition /dev/nvme0n1p2 /mnt/boot

# Mount the Root partition
mount_partition /dev/nvme0n1p3 /mnt

# Mount the Home partition
mount_partition /dev/nvme0n1p4 /mnt/home

echo "All partitions mounted successfully."
