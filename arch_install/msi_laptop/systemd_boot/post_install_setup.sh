#!/bin/bash
set -e

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"

# Create a new user
echo "Creating user $USER_NAME..."
useradd -m -G wheel -s /bin/bash $USER_NAME

# Add the new user to the sudoers file via visudo
echo "Adding $USER_NAME to the sudoers file..."
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers

# Set password for the new user
echo "Set password for $USER_NAME..."
passwd $USER_NAME

# Create ssh keys for the new user
echo "Creating ssh keys for $USER_NAME..."
sudo -u $USER_NAME ssh-keygen -t rsa -b 4096 -f /home/$USER_NAME/.ssh/id_rsa -C "$USER_NAME@${HOSTNAME}"

# Optional: Clone dotfiles from GitHub
dot_dir="/home/$USER_NAME/.dots"
echo "Cloning dotfiles for $USER_NAME..."
sudo -u $USER_NAME git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${dot_dir}

# Symbolic link the dotfiles
ln -sf $dot_dir/.bashrc /home/$USER_NAME/.bashrc
ln -sf $dot_dir/.bash_profile /home/$USER_NAME/.bash_profile
ln -sf $dot_dir/.bash_aliases /home/$USER_NAME/.bash_aliases

mkdir -p /home/$USER_NAME/.config
ln -sf $dot_dir/.config/nvim /home/$USER_NAME/.config/.
ln -sf $dot_dir/.config/i3 /home/$USER_NAME/.config/.

# Time synchronization
systemctl enable --now systemd-timesyncd.service

### Pacman Configuration
# Check if ParallelDownloads is already set
if grep -q "^ParallelDownloads" /etc/pacman.conf; then
    # Update the existing line
    sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
else
    # Add ParallelDownloads setting
    echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf
fi

echo "Parallel downloads enabled for Pacman."
