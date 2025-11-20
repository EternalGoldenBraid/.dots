#!/bin/bash
set -e

source ~/.dotfiles/arch_install/msi_laptop/systemd_boot/utils.sh

USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
DOT_DIR=${HOME}/.dotfiles
AUR_DIR=/home/${USER_NAME}/aur

nmtui

# Create ssh keys for the new user
# echo "Creating ssh keys for ${USER_NAME}..."
# sudo -u ${USER_NAME} ssh-keygen -t rsa -b 4096 -f /home/${USER_NAME}/.ssh/id_rsa -C "${USER_NAME}@${HOSTNAME}"

# Optional: Clone dotfiles from GitHub
# TODO ADD IF EXIST CHECK
# echo "Cloning dotfiles for ${USER_NAME}..."
# sudo -u ${USER_NAME} git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${DOT_DIR}
# git clone https://github.com/EternalGoldenBraid/.dots ${DOT_DIR}
# mv $HOME/.dots $HOME/.dotfiles

# Symbolic link the dotfiles
ln -sf ${DOT_DIR}/.bashrc /home/${USER_NAME}/.bashrc
# ln -sf $DOT_DIR/.bash_profile /home/${USER_NAME}/.bash_profile # Don't have this
ln -sf ${DOT_DIR}/.bash_aliases /home/${USER_NAME}/.bash_aliases
ln -sf ${DOT_DIR}/.bash_generals /home/${USER_NAME}/.bash_generals
ln -sf ${DOT_DIR}/xinitrc /home/${USER_NAME}/.xinitrc

mkdir -p /home/${USER_NAME}/.config
mkdir -p $HOME/bin
ln -sf ${DOT_DIR}/.config/* /$HOME/.config/
ln -sf ${DOT_DIR}/bin/* /$HOME/bin/

echo "#### Setting up paru and AUR dir..."
mkdir -p ${AUR_DIR}
git clone https://aur.archlinux.org/paru.git ${AUR_DIR}/paru
pushd ${AUR_DIR}/paru
makepkg -srci --noconfirm
popd

### Pacman Configuration
echo "#### Enabling pacman parallel downloads"
pacman_enable_parallel_downloads

paru -S \
    1password 1password-cli \
    tree-sitter-cli ncdu btop \
    gnome-keyring rofi-greenclip exa \
    slack-desktop auto-cpufreq teams-for-linux redshift \
    zotero ttf-font-awesome-5
    # python-eduvpn-client python-eduvpn_common \

setup_neovim
setup_tmux
    
sudo auto-cpufreq --install
systemctl enable --now auto-cpufreq

timedatectl set-ntp true
pushd ~/${DOT_DIR}
git config --global core.editor "nvim -f"
git remote set-url origin ${DOTS_REPO_SSH}
popd

# # Time synchronization
# systemctl enable --now systemd-timesyncd.service
