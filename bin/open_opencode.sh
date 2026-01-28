#!/bin/sh

SESSION="opencode"

# Check if the session exists
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # Session doesn't exist, create it
    # -d: Detached
    # -s: Session name
    # -c: Start in HOME directory
    tmux new-session -d -s $SESSION -c "$HOME"
    
    # Start opencode in the first pane
    tmux send-keys -t $SESSION:0 "opencode" C-m
fi

# Attach to the session in a new Kitty window
kitty tmux attach -t $SESSION
