#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/bin"
LAUNCHER="$HOME/.config/rofi/scripts/launch.sh"

if [[ ! -d "$BIN_DIR" ]]; then
  echo "Missing bin dir: $BIN_DIR" >&2
  exit 1
fi

selected="$(ls "$BIN_DIR" | "$LAUNCHER" -dmenu -p "Run: ")"
[[ -n "${selected:-}" ]] || exit 0

exec "$BIN_DIR/$selected"
