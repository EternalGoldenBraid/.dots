### systemd-boot Arch Linux Installation Scripts

This repository contains scripts to automate the installation and initial configuration of Arch Linux.
Scripts Overview

### install.sh
**Purpose:** Prepares disk partitions, formats them, mounts them, installs the base system using Pacstrap, and configures basic system settings.

**Assumptions:**
  - Assumes the script is run as root from a live Arch Linux environment.
  - A NVME device (e.g., /dev/nvme0n1) as an argument.
  - A single disk layout with a GPT partition table.

### chrooted_setup.sh
Note this is ran directly by `install.sh`
**Purpose:** Configured to run inside a chroot environment. It sets up system configurations like timezone, locale, hostname, mkinitcpio with resume hook for suspend-to-disk functionality, and installs systemd-boot.
**Assumptions:** Assumes it's being executed inside a chroot environment on the target filesystem.

### post_install_setup.sh
**Purpose:** Adds user accounts, configures SSH keys, clones dotfiles from a GitHub repository, and sets up necessary system services.

**Assumptions:** Assumes it has network access and that it's running post-installation in the chroot environment.

Usage

Run install.sh with the target device as a parameter:

bash

./install.sh /dev/nvme0n1

This script partitions the drive, installs the base system, and then automatically calls chrooted_setup.sh and post_install_setup.sh to complete the configuration.

### Note
Ensure you have a live internet connection and the latest Arch Linux live media to avoid issues during installation. Customize the scripts as needed before running, especially to match hardware specifications like disk layout and desired software.


### Internet

Ping:
```
ping archlinux.org
```

If no connection go with iwctl:
```
iwctl device list

>> wlan0
```

e.g.
```
iwctl --passphrase <PWD> stationn <device_name> connect <SSID>
```
