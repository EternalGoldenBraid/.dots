#!/bin/bash

# Get list of tmux sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

# Check if there are any sessions
if [ -z "$sessions" ]; then
    rofi -e "No tmux sessions found"
    exit 1
fi

# Show sessions in rofi and get selection
selected=$(echo "$sessions" | rofi -dmenu -p "Tmux session: ")

# Exit if nothing selected
if [ -z "$selected" ]; then
    exit 0
fi

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    # Switch to the selected session
    tmux switch-client -t "$selected"
else
    # Attach to the selected session
    tmux attach-session -t "$selected"
fi
