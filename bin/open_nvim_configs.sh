#!/bin/sh

# Neovim config editing session setup in tmux

session="nvim-config"
nvimConfigDir="$HOME/.config/nvim"

term="kitty"

# Start tmux server
tmux -u start-server

# Create a new tmux session, detached, named after your session variable
tmux new-session -d -s $session -c $nvimConfigDir

# Rename the first window to 'nvim-main'
tmux rename-window -t $session:0 'nvim-main'

# In the first pane, open init.lua with nvim
tmux send-keys -t $session:0 "nvim init.lua" C-m

# Attach to the session
$term tmux attach -t $session
