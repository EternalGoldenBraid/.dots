#!/bin/bash

DOTS_REPO_HTTPS="https://github.com/EternalGoldenBraid/.dots"
DOTS_REPO_SSH="git@github.com:EternalGoldenBraid/.dots"

pacman_enable_parallel_downloads() {
    # Check if ParallelDownloads is already set
    if grep -q "^ParallelDownloads" /etc/pacman.conf; then
        # Update the existing line
        sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
    else
        # Add ParallelDownloads setting under Misc options
        sudo sed -i '/^# Misc options/a ParallelDownloads = 5' /etc/pacman.conf
    fi
    
    echo "Parallel downloads enabled for Pacman."
}

setup_neovim() {
    echo "Setting up Neovim..."
    mkdir -p ~/venvs
    pushd ~/venvs
    python3 -m venv neovim
    source neovim/bin/activate
    pip install pynvim debugpy
    deactivate
    popd
    echo "Neovim setup complete."
}

setup_tmux() {
    echo "Setting up tmux..."
    DOT_DIR=${HOME}/.dotfiles

    # Install Temp Plugin Manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ln -sf ${DOT_DIR/.config/tmux.conf} /home/${USER_NAME}/.tmux.conf
    tmux source ~/.tmux.conf
    echo "Tmux setup complete."
}
