#!/bin/bash

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
    mkdir -p ~/venvs
    pushd ~/venvs
    python3 -m venv neovim
    source neovim/bin/activate
    pip install pynvim debugpy
    deactivate
    popd
}

setup_tmux() {
    DOT_DIR=${HOME}/.dotfiles

    # Install Temp Plugin Manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ln -sf ${DOT_DIR/tmux.conf /home/${USER_NAME}/.tmux.conf
    tmux source ~/.tmux.conf
}
