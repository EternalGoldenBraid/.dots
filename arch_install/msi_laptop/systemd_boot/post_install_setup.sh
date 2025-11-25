l!/bin/bash
set -e

source ~/.dotfiles/arch_install/msi_laptop/systemd_boot/utils.sh

# --- CONFIGURATION ---
# Set to "wayland" (Hyprland) or "x11" (i3)
TARGET_ENV="wayland" 
USER_NAME="nicklas"
GITHUB_USERNAME="EternalGoldenBraid"
DOT_DIR=${HOME}/.dotfiles
AUR_DIR=/home/${USER_NAME}/aur
# ---------------------


echo "#### Starting Post-Install Setup for $TARGET_ENV..."


nmtui

# echo "Cloning dotfiles for ${USER_NAME}..."
# git clone https://github.com/${GITHUB_USERNAME}/.dots.git ${DOT_DIR}

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

# 2. Define Package Lists

# --- CORE UTILITIES (Desktop Agnostic) ---
CORE_PKGS=(
    "neovim" "vim" "vifm" "obsidian" "firefox" "nemo"
    "wezterm" "git" "rsync" "tmux" "wget" "curl"
    "tree-sitter-cli" "ncdu" "btop" "lazygit" "unzip" "pixi" "rclone"
    "npm" "nodejs" "fzf"
    "pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack" "pavucontrol" "pamixer"
    "zathura" "zathura-pdf-poppler"
    "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji" # Fonts are critical
    "gnome-keyring" "libsecret"
    "1password" "1password-cli"
    "slack-desktop" "teams-for-linux" "zotero"
    "auto-cpufreq"
    "kitty" "exa"
    # texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-fontsextra \
    # texlive-mathscience texlive-plaingeneric texlive-langgreek biber texlive-binextra \
)


# --- ENVIRONMENT SPECIFIC ---

if [ "$TARGET_ENV" == "wayland" ]; then
    echo "-> Selecting Wayland (Hyprland) packages..."
    ENV_PKGS=(
        "hyprland"          # The Compositor
        "waybar"            # Status Bar
        "wofi"              # App Launcher (Simple)
        "rofi-wayland"      # App Launcher (Complex/Themable)
        "hyprpaper"         # Wallpaper manager
        "hyprlock"          # Lock screen
        "hypridle"          # Idle daemon
        "nwg-displays"      # Arandr alternative
        "grim" "slurp"      # Screenshot tools (replaces maim)
        "wl-clipboard"      # Clipboard utils (replaces xclip)
        "cliphist"          # Clipboard manager (replaces greenclip)
        "gammastep"         # Blue light filter (replaces redshift)
        "wlr-randr"         # CLI Monitor config (replaces xrandr)
        "nwg-look"          # GTK Theme switcher (replaces lxappearance)
        "qt5-wayland"       # Qt support
        "qt6-wayland"       # Qt support
    )
else
    echo "-> Selecting X11 (i3) packages..."
    ENV_PKGS=(
        "i3-wm" "i3status" "i3lock" "i3-gaps"
        "rofi" "rofi-calc" "rofi-greenclip"
        "picom"             # Compositor
        "xorg-server" "xorg-xinit" "xorg-xrandr" "arandr"
        "maim"              # Screenshot
        "xclip"             # Clipboard
        "redshift"          # Blue light
        "lxappearance"      # Theming
        "feh"               # Wallpaper
    )
fi

# 3. Install Packages
echo "#### Installing packages..."

# Combine lists
ALL_PKGS=("${CORE_PKGS[@]}" "${ENV_PKGS[@]}")

# Run installation
paru -S --needed --noconfirm "${ALL_PKGS[@]}"


# 4. Post-Install Configuration

setup_neovim
setup_tmux
    
echo "WARNING: auto-cpufreq not setup"
# Note: On EndeavourOS, verify 'power-profiles-daemon' isn't conflicting before enabling auto-cpufreq
# sudo auto-cpufreq --install
# systemctl enable --now auto-cpufreq

timedatectl set-ntp true
pushd ~/${DOT_DIR}
git config --global core.editor "nvim -f"
git remote set-url origin ${DOTS_REPO_SSH}
popd

# # Time synchronization
# systemctl enable --now systemd-timesyncd.service

echo "#### Setup Complete! ####"

echo "
    Go ahead and setup 1password by enabling cli and ssh-agent integration in the developer settings.
"
