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

# Check if session is already attached somewhere
if tmux list-clients -t "$selected" &>/dev/null; then
    # Session is attached - try to find and focus the window
    # Get the client PID
    client_pid=$(tmux list-clients -t "$selected" -F "#{client_pid}" | head -1)
    
    # Find kitty window containing this tmux session
    window=$(hyprctl clients -j | jq -r ".[] | select(.pid == $client_pid or .title | contains(\"$selected\")) | .address" | head -1)
    
    if [ -n "$window" ]; then
        hyprctl dispatch focuswindow address:$window
    else
        # Fallback: open new terminal
        kitty tmux attach-session -t "$selected" &
    fi
else
    # Session exists but not attached - open in new kitty terminal
    kitty tmux attach-session -t "$selected" &
fi
