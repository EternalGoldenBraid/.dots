#!/bin/bash
set -e

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"

# Create a new user
echo "Creating user $USER_NAME..."
useradd -m -G wheel -s /bin/bash $USER_NAME

# Set password for the new user
echo "Set password for $USER_NAME..."
passwd $USER_NAME

# Create ssh keys for the new user
echo "Creating ssh keys for $USER_NAME..."
sudo -u $USER_NAME ssh-keygen -t rsa -b 4096 -f /home/$USER_NAME/.ssh/id_rsa -C "$USER_NAME@$(HOSTNAME)"

# Optional: Clone dotfiles from GitHub
dot_dir="/home/$USER_NAME/.dots"
echo "Cloning dotfiles for $USER_NAME..."
sudo -u $USER_NAME git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${dot_dir}

# Symbolic link the dotfiles
ln -s $dot_dir/.bashrc /home/$USER_NAME/.bashrc
ln -s $dot_dir/.bash_profile /home/$USER_NAME/.bash_profile
ln -s $dot_dir/.bash_aliases /home/$USER_NAME/.bash_aliases

ln -s $dot_dir/.config/nvim /home/$USER_NAME/.config/nvim
ln -s $dot_dir/.config/i3 /home/$USER_NAME/.config/sway
