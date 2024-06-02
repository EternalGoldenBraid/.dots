set -e

echo "Creating Pacman hook to automatically copy kernel and initramfs to EFI directory..."

# Create the directory for Pacman hooks in the new system
mkdir -p /mnt/etc/pacman.d/hooks

# Create the hook file
mkdir -p /mnt/boot/efi/EFI
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
Exec = /usr/bin/cp /boot/initramfs-linux.img /boot/efi/EFI/
EOF
echo "Pacman hook created successfully."

# Copy the kernel and initramfs to the EFI directory
cp /mnt/boot/vmlinuz-linux /mnt/boot/efi/EFI/
cp /mnt/boot/initramfs-linux.img /mnt/boot/efi/EFI/
echo "Kernel and initramfs copied to EFI directory." \
    "Check that they are copied after reboot and pacman -Syu linux."


echo "Creating EFI boot entry..."
cpu=intel
# cpu=amd

swapfile=/mnt/swapfile
resume_offset=$(filefrag -v $swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')
echo "Resume offset: $resume_offset"

efi_disk=/dev/nvme0n1
efi_part=1
echo "EFI partition: ${efi_disk}p${efi_part}"

root_uuid=$(blkid -s UUID -o value /dev/nvme0n1p3)
echo "Root UUID: $root_uuid"

# Assumes the swap file is on the root partition i.e. /mt/swapfile
swap_uuid=$(blkid -s UUID -o value /dev/nvme0n1p3)
echo "Swap UUID: $swap_uuid"

efibootmgr --create --disk ${efi_disk} --part ${efi_part} \
            --label "EFISTUB Arch" \
            --loader /vmlinuz-linux \
            --unicode "root=${root_uuid} resume=${swap_uuid} resume_offset=${resume_offset} rw initrd=\\${cpu}-ucode.img initrd=\initramfs-linux.img"

# Create fallback entry
# efibootmgr --create --disk $efi_disk --part $efi_part \
#             --label "EFISTUB Arch Fallback" \
#             --loader /vmlinuz-linux \
#             --unicode "root=$root_uuid resume=$swap_uuid resume_offset=$resume_offset rw initrd=\initramfs-linux-fallback.img"
