cpu=intel
# cpu=amd
efibootmgr --create --disk /dev/nvme0n1 --part 1 \
            --label "EFISTUB Arch" \
            --loader /vmlinuz-linux \
            --unicode "root=$(blkid -s UUID -o value /dev/nvme0n1p3) resume=$(blkid -s UUID -o value /dev/nvme0n1p3) resume_offset=$(filefrag -v /swapfile | awk '{ if($1=="0:"){ print $4 } }' | sed 's/\.\.//') rw initrd=\$cpu-ucode-linux.img initrd=\initramfs-linux.img"
