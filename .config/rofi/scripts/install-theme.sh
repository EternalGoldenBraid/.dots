#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/w8ste/Tokyonight-rofi-theme"
REPO_DIR="$HOME/.config/rofi/themes/Tokyonight-rofi-theme"
THEME_SRC="$REPO_DIR/tokyonight_big2.rasi"
THEME_DST="$HOME/.config/rofi/themes/tokyonight_big2.rasi"

mkdir -p "$HOME/.config/rofi/themes"

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" pull --ff-only
else
  rm -rf "$REPO_DIR"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

if [[ ! -f "$THEME_SRC" ]]; then
  echo "Theme file not found in repo: $THEME_SRC" >&2
  exit 1
fi

cp -f "$THEME_SRC" "$THEME_DST"
echo "Installed theme: $THEME_DST"
