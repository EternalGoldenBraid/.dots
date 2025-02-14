#!/bin/bash
set -e
P
USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
DOT_DIR=${HOME}/.dotfiles

# Create ssh keys for the new user
# echo "Creating ssh keys for $USER_NAME..."
# sudo -u $USER_NAME ssh-keygen -t rsa -b 4096 -f /home/$USER_NAME/.ssh/id_rsa -C "$USER_NAME@${HOSTNAME}"

# Optional: Clone dotfiles from GitHub
# echo "Cloning dotfiles for $USER_NAME..."
# sudo -u $USER_NAME git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${dot_dir}
git clone https://github.com/EternalGoldenBraid/.dots ${DOT_DIR}
# mv $HOME/.dots $HOME/.dotfiles

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

### Pacman Configuration
pacman_enable_parallel_downloads

paru -S \
    networkmanager network-manager-applet \
    nm-connection-editor \
    neovim vim vifm obsidian firefox nemo \
    kitty git rsync \
    i3 i3status i3lock i3-gaps rofi rofi-calc picom \
    xorg xorg-xinit xorg-xrandr arandr \
    gnome-keyring libsecret \
    maim ripgrep cmake openssh \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack pavucontrol pamixer \
    texlive-latexrecommended texlive-latexextra \
    texlive-fontsrecommended texlive-fontsextra \
    texlive-mathscience texlive-plaingeneric texlive-langgreek biber \
    zathura zathura-pdf-poppler xdotool \
    lxappearance ttf-font-awesome zoxide \
    tree-sitter-cli ncdu btop \
    gnome-keyring eduvpn 1password setups \
    slack-desktop auto-cpufreq teams-for-linux \
    rofi-greenclip
    
sudo auto-cpufreq --install

# # Time synchronization
# systemctl enable --now systemd-timesyncd.service
#

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
