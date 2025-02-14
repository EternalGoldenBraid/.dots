#!/bin/bash
set -e

pacman_enable_parallel_downloads() {
    # Check if ParallelDownloads is already set
    if grep -q "^ParallelDownloads" /etc/pacman.conf; then
        # Update the existing line
        sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
    else
        # Add ParallelDownloads setting under Misc options
        # echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf
        sudo sed -i '/^# Misc options/a ParallelDownloads = 5' /etc/pacman.conf
    fi
    
    echo "Parallel downloads enabled for Pacman."
}

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
DOT_DIR=${HOME}/.dotfiles
BUILD_DIR=/home/${USER_NAME}/builds

nmtui

# Create ssh keys for the new user
# echo "Creating ssh keys for ${USER_NAME}..."
# sudo -u ${USER_NAME} ssh-keygen -t rsa -b 4096 -f /home/${USER_NAME}/.ssh/id_rsa -C "${USER_NAME}@${HOSTNAME}"

# Optional: Clone dotfiles from GitHub
# echo "Cloning dotfiles for ${USER_NAME}..."
# sudo -u ${USER_NAME} git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${DOT_DIR}
# git clone https://github.com/EternalGoldenBraid/.dots ${DOT_DIR}
# mv $HOME/.dots $HOME/.dotfiles

# Symbolic link the dotfiles
ln -sf ${DOT_DIR}/.bashrc /home/${USER_NAME}/.bashrc
# ln -sf $DOT_DIR/.bash_profile /home/${USER_NAME}/.bash_profile # Don't have this
ln -sf ${DOT_DIR}/.bash_aliases /home/${USER_NAME}/.bash_aliases
ln -sf ${DOT_DIR}/xinitrc /home/${USER_NAME}/.xinitrc

mkdir -p /home/${USER_NAME}/.config
mkdir -p $HOME/bin
ln -sf ${DOT_DIR}/.config/* /$HOME/.config/
ln -sf ${DOT_DIR}/bin/* /$HOME/bin/

# TODO Add Paru setup
mkdir -p ${BUILD_DIR}
git clone https://aur.archlinux.org/paru.git /home/${USER_NAME}/builds/paru
pushd
makepkg -srci --noconfirm
popd

### Pacman Configuration
pacman_enable_parallel_downloads

paru -S \
    tree-sitter-cli ncdu btop \
    gnome-keyring eduvpn 1password setups \
    slack-desktop auto-cpufreq teams-for-linux \
    rofi-greenclip
    
sudo auto-cpufreq --install

# # Time synchronization
# systemctl enable --now systemd-timesyncd.service
#

