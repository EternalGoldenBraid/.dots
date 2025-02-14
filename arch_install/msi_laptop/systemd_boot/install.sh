#!/bin/bash
### Create, format and mount partitions

set -e

# Script to create and format partitions on a specified device using parted
swap_size=12G
create_swapfile=true
# root_size=30G

cpu_manufacturer=intel
# cpu_manufacturer=amd


### Functions
mount_partition() {
    local partition=$1
    local mount_point=$2

    echo "Mounting $partition on $mount_point..."
    if ! mount --mkdir $partition $mount_point; then
        echo "Failed to mount $partition on $mount_point. Exiting."
        exit 1
    fi
}

partition_drive() {
    echo "Partitioning new GPT partition table on $DEVICE..."
    parted --script $DEVICE mklabel gpt \
           mkpart primary fat32 1MiB 1025MiB \
           set 1 esp on \
           mkpart primary ext4 1025MiB 41025MiB \
           mkpart primary ext4 41025MiB 100%
    sleep 2  # Allow the kernel to recognize the new partitions
}

format_partitions() {
    echo "Formatting the EFI partition..."
    mkfs.fat -F 32 ${DEVICE}p1
    echo "Formatting Linux filesystem partitions..."
    mkfs.ext4 ${DEVICE}p2
    mkfs.ext4 ${DEVICE}p3
}

mount_partitions() {
    mount_partition ${DEVICE}p2 /mnt
    mount_partition ${DEVICE}p1 /mnt/boot
    mount_partition ${DEVICE}p3 /mnt/home
}

create_swap_file() {
    echo "Creating swap file..."
    mkswap -U clear --size $swap_size --file /mnt/swapfile
}

pacman_enable_parallel_downloads() {
    # Check if ParallelDownloads is already set
    if grep -q "^ParallelDownloads" /etc/pacman.conf; then
        # Update the existing line
        sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
    else
        # Add ParallelDownloads setting under Misc options
        # echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf
        sudo sed -i '/^# Misc options/a ParallelDownloads = 5' /etc/pacman.conf
    fi
    
    echo "Parallel downloads enabled for Pacman."
}

install_system() {
    echo "Pacstrap installation..."
    pacman_enable_parallel_downloads
    # might need to update the keyring on an old image?
    pacman -Sy --noconfirm archlinux-keyring
    
    # sway swaylock swayidle swaybg waybar wofi \
    # nvidia nvidia-utils nvidia-settings \ # Fuck this
    pacstrap -K /mnt base base-devel \
        linux linux-firmware ${cpu_manufacturer}-ucode openssh git \
        networkmanager network-manager-applet \
        nm-connection-editor \
        neovim vim vifm obsidian firefox nemo \
        kitty git rsync tmux \
        i3 i3status i3lock i3-gaps rofi rofi-calc picom \
        xorg xorg-xinit xorg-xrandr arandr \
        gnome-keyring libsecret \
        maim ripgrep cmake \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack pavucontrol pamixer \
        texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-fontsextra \
        texlive-mathscience texlive-plaingeneric texlive-langgreek biber \
        zathura zathura-pdf-poppler xdotool \
        lxappearance ttf-font-awesome zoxide \
        tree-sitter-cli ncdu btop

    genfstab -U /mnt >> /mnt/etc/fstab
}

### Main Script Execution
set -e
if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX or /dev/nvme0n1"
    exit 1
elif [ ! -b "$1" ]; then
    echo "Error: $1 is not a valid block device."
    exit 1
fi
DEVICE=$1

for PART in $(ls ${DEVICE}* 2>/dev/null); do
    if mount | grep -q ${PART}; then
        echo "Unmount ${PART} first."
        exit 1
    fi
done

partition_drive
format_partitions
mount_partitions
[ "$create_swapfile" = true ] && create_swap_file
install_system

echo "Partitioning, formatting and mounting complete."
echo "Initiating chroot setup..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "SCRIPT_DIR: $SCRIPT_DIR"

function run_chrooted( ) {
    filename=$1
    if [ ! -f "${SCRIPT_DIR}/${filename}" ]; then
        echo "Error: file ${filename} not found in ${SCRIPT_DIR}. Exiting."
        exit 1
    fi
    echo "Copying ${filename} to /mnt..."
    cp "${SCRIPT_DIR}/${filename}" /mnt/.
    arch-chroot /mnt /bin/bash /${filename}
    rm /mnt/${filename}
    echo "Finished running ${filename} in chroot."
}

run_chrooted chrooted_setup.sh
# run_chrooted post_install_setup.sh # TODO Figure out how to run these things as user
