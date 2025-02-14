#!/bin/bash
set -e

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
HOME=/home/$USER_NAME
DOT_DIR=${HOME}/.dotfiles

# Create a new user
echo "Creating user $USER_NAME..."
mkdir -p /home/$USER_NAME
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
echo "Cloning dotfiles for $USER_NAME..."
sudo -u $USER_NAME git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${dot_dir}
mv $HOME/.dots $HOME/.dotfiles

# Symbolic link the dotfiles
ln -sf $dot_dir/.bashrc /home/$USER_NAME/.bashrc
# ln -sf $dot_dir/.bash_profile /home/$USER_NAME/.bash_profile # Don't have this
ln -sf $dot_dir/.bash_aliases /home/$USER_NAME/.bash_aliases
ln -sf $dot_dir/xinitrc /home/$USER_NAME/.xinitrc

mkdir -p /home/$USER_NAME/.config
mkdir $HOME/bin
ln -s $DOT_DIR/.config/* /$HOME/.config/
ln -s $DOT_DIR/bin/* /$HOME/bin/

# TODO Add Paru setup
mkdir -p /home/$USER_NAME/builds
git clone https://aur.archlinux.org/paru.git /home/$USER_NAME/builds/paru
paru -S \
    gnome-keyring eduvpn 1password setups \
    slack-desktop auto-cpufreq teams-for-linux \
    rofi-greenclip
    
sudo auto-cpufreq --install

# # Time synchronization
# systemctl enable --now systemd-timesyncd.service
#
# ### Pacman Configuration
# # Check if ParallelDownloads is already set
# if grep -q "^ParallelDownloads" /etc/pacman.conf; then
#     # Update the existing line
#     sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
# else
#     # Add ParallelDownloads setting
#     echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf
# fi
#
# echo "Parallel downloads enabled for Pacman."
