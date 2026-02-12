#!/usr/bin/env bash
set -euo pipefail

LAUNCHER="$HOME/.config/rofi/scripts/launch.sh"
TERMINAL="${TERMINAL:-kitty}"
YAZI_BIN="${YAZI_BIN:-yazi}"

command -v "$YAZI_BIN" >/dev/null 2>&1 || {
  "$LAUNCHER" -e "Missing yazi in PATH"
  exit 1
}

choose_root() {
  local roots root
  roots="$HOME"$'\n'"$HOME/Projects"$'\n'"$HOME/Documents"$'\n'"$HOME/.dotfiles"
  root="$(printf '%s\n' "$roots" | "$LAUNCHER" -dmenu -p "Root: ")"
  [[ -n "${root:-}" ]] || return 1
  [[ -d "$root" ]] || return 1
  printf '%s' "$root"
}

mode="$(
  printf '%s\n' \
    "Content grep (rg) -> Yazi" \
    "Filename find (fd) -> Yazi" \
    "Browse in Yazi" \
  | "$LAUNCHER" -dmenu -p "Mode: "
)"
[[ -n "${mode:-}" ]] || exit 0

root="$(choose_root)" || exit 0

case "$mode" in
  "Browse in Yazi")
    exec "$TERMINAL" -e "$YAZI_BIN" "$root"
    ;;

  "Filename find (fd) -> Yazi")
    query="$("$LAUNCHER" -dmenu -p "Find filename: ")"
    [[ -n "${query:-}" ]] || exit 0

    results="$(
      fd \
        --hidden \
        --full-path \
        --exclude .git \
        --exclude .cache \
        --exclude .local \
        --exclude node_modules \
        --exclude nvidia_sdkm_downloads \
        "$query" "$root" 2>/dev/null | head -n 1200
    )"
    [[ -n "${results:-}" ]] || { "$LAUNCHER" -e "No filename matches for: $query"; exit 0; }

    selected="$(printf '%s\n' "$results" | "$LAUNCHER" -dmenu -i -p "Open in Yazi: ")"
    [[ -n "${selected:-}" ]] || exit 0
    [[ -e "$selected" ]] || exit 1

    if [[ -d "$selected" ]]; then
      exec "$TERMINAL" -e "$YAZI_BIN" "$selected"
    else
      exec "$TERMINAL" -e "$YAZI_BIN" "$(dirname "$selected")"
    fi
    ;;

  "Content grep (rg) -> Yazi")
    query="$("$LAUNCHER" -dmenu -p "Grep content: ")"
    [[ -n "${query:-}" ]] || exit 0

    # Keep searches snappy by returning only the first match per file.
    results="$(
      rg \
        --line-number \
        --column \
        --max-count 1 \
        --no-heading \
        --color=never \
        --smart-case \
        --hidden \
        --glob '!.git' \
        --glob '!.cache' \
        --glob '!.local' \
        --glob '!nvidia_sdkm_downloads' \
        --glob '!node_modules' \
        --glob '!.venv' \
        --glob '!venv' \
        --glob '!__pycache__' \
        "$query" "$root" 2>/dev/null | head -n 1200
    )"
    [[ -n "${results:-}" ]] || { "$LAUNCHER" -e "No content matches for: $query"; exit 0; }

    selected="$(printf '%s\n' "$results" | "$LAUNCHER" -dmenu -i -p "Open location in Yazi: ")"
    [[ -n "${selected:-}" ]] || exit 0

    file="$(printf '%s' "$selected" | cut -d: -f1)"
    [[ -f "$file" ]] || exit 1
    exec "$TERMINAL" -e "$YAZI_BIN" "$(dirname "$file")"
    ;;
esac
