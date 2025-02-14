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
    mkdir -p ~/venvs/neovim
    pushd ~/venvs/neovim
    python3 -m venv neovim
    source neovim/bin/activate
    pip install pynvim debugpy
    deactivate
    popd
}
