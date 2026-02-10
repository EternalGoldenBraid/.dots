#!/usr/bin/env bash
set -euo pipefail

THEME="${ROFI_THEME:-$HOME/.config/rofi/themes/tokyonight_big2.rasi}"
INSTALL_SCRIPT="$HOME/.config/rofi/scripts/install-theme.sh"
REPO_URL="https://github.com/w8ste/Tokyonight-rofi-theme"

if [[ ! -f "$THEME" ]]; then
  msg="Rofi theme missing: $THEME\nInstall: $INSTALL_SCRIPT\nSource: $REPO_URL"
  printf '%b\n' "$msg" >&2

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Rofi theme missing" "$THEME\nInstall: $INSTALL_SCRIPT\nSource: $REPO_URL"
  fi

  if command -v rofi >/dev/null 2>&1; then
    rofi -e "$msg" || true
  fi

  exit 1
fi

exec rofi -theme "$THEME" "$@"
