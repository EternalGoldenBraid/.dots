#!/bin/bash

pushd ~/.dots
git stash; git pull; 
chmod +x *.sh
umount \
    /dev/nvme0n1p1 \
    /dev/nvme0n1p3 \
    /dev/nvme0n1p2

popd
