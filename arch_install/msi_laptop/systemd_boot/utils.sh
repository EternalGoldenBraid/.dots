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

setup_fingerprint_auth() {
    local pam_file="/etc/pam.d/system-local-login"
    local pam_line="auth      sufficient   pam_fprintd.so"
    local tmp_file
    local backup_file

    if ! pacman -Qq fprintd >/dev/null 2>&1; then
        echo "Skipping fingerprint PAM setup: fprintd is not installed."
        return 0
    fi

    if [ ! -f "${pam_file}" ]; then
        echo "Skipping fingerprint PAM setup: ${pam_file} was not found."
        return 0
    fi

    if grep -Fqx "${pam_line}" "${pam_file}"; then
        echo "Fingerprint PAM entry already present in ${pam_file}."
        return 0
    fi

    tmp_file=$(mktemp)
    backup_file="${pam_file}.bak.$(date +%Y%m%d%H%M%S)"

    # Insert fingerprint auth before the standard system-login include.
    awk -v pam_line="${pam_line}" '
        !inserted && /^auth[[:space:]]+include[[:space:]]+system-login$/ {
            print pam_line
            inserted = 1
        }
        { print }
    ' "${pam_file}" > "${tmp_file}"

    sudo cp "${pam_file}" "${backup_file}"
    sudo install -m 644 "${tmp_file}" "${pam_file}"
    rm -f "${tmp_file}"

    echo "Fingerprint PAM enabled in ${pam_file}."
    echo "Backup saved to ${backup_file}."
}
