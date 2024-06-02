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
    # Get the mount point of the partition
    MOUNT_POINT=$(mount | grep "${PART}" | awk '{ print $3 }')
    if [ ! -z "${MOUNT_POINT}" ]; then
        echo "Unmounting ${PART} from ${MOUNT_POINT}..."
        umount ${MOUNT_POINT}
        if [ $? -ne 0 ]; then
            echo "Failed to unmount ${PART} from ${MOUNT_POINT}. Exiting."
            exit 1
        fi
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

mount_partition ${DEVICE}p1 /mnt/boot/efi
mount_partition ${DEVICE}p2 /mnt/boot
mount_partition ${DEVICE}p3 /mnt
mount_partition ${DEVICE}p4 /mnt/home
echo "All partitions mounted successfully."

if [ "$create_swapfile" = true ]; then
    echo "Creating swap file..."
    mkswap -U clear --size $swap_size --file /mnt/swapfile
fi

echo "Creating Pacman hook to automatically copy kernel and initramfs to EFI directory..."

# Create the directory for Pacman hooks in the new system
mkdir -p /mnt/etc/pacman.d/hooks

# Create the hook file
cat <<EOF > /mnt/etc/pacman.d/hooks/copy-kernel-to-efi.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux

[Action]
Description = Copying kernel and initramfs to EFI directory
When = PostTransaction
Exec = /usr/bin/cp /boot/vmlinuz-linux /mnt/boot/efi/EFI/
Exec = /usr/bin/cp /boot/initramfs-linux.img /mnt/boot/efi/EFI/
EOF
echo "Pacman hook created successfully."
 
echo "Pacstrap installation..."
# Pacstrap defaults
pacstrap -K /mnt base base-devel linux linux-firmware ${cpu_manufacturer}-ucode\
    sway swaylock swayidle waybar wofi \
    networkmanager network-manager-applet nm-connection-editor \
    neovim vim vifm \
    obsidian

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "Pacstrap complete. Run arch-chroot /mnt and continue installation with chrooted_setup.sh"
