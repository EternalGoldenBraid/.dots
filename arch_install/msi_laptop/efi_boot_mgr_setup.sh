cpu=intel
# cpu=amd

swapfile=/mnt/swapfile
resume_offset=$(filefrag -v $swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')

efi_disk=/dev/nvme0n1
efi_part=1

root_uuid=$(blkid -s UUID -o value /dev/nvme0n1p3)

# Assumes the swap file is on the root partition i.e. /mt/swapfile
swap_uuid=$(blkid -s UUID -o value /dev/nvme0n1p3)

efibootmgr --create --disk $efi_disk --part $efi_part \
            --label "EFISTUB Arch" \
            --loader /vmlinuz-linux \
            --unicode "root=$root_uuid resume=$swap_uuid resume_offset=$resume_offset rw initrd=\\$cpu-ucode-linux.img initrd=\initramfs-linux.img"

# Create fallback entry
# efibootmgr --create --disk $efi_disk --part $efi_part \
#             --label "EFISTUB Arch Fallback" \
#             --loader /vmlinuz-linux \
#             --unicode "root=$root_uuid resume=$swap_uuid resume_offset=$resume_offset rw initrd=\initramfs-linux-fallback.img"
