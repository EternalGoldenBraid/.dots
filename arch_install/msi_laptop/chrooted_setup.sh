#!/bin/bash

# Set the timezone
echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
hwclock --systohc

# Generate locales
echo "Generating locales..."
echo "fi_FI.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Set root password
echo "Set root password with `passwd`"
