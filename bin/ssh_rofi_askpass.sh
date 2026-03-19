#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/.dotfiles/tmux/bin/ssh-askpass" "$@"
