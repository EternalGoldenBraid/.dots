set -e

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
