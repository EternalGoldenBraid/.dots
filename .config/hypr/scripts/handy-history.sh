#!/usr/bin/env bash
set -euo pipefail

DB="${HANDY_DB:-$HOME/.local/share/com.pais.handy/history.db}"
LAUNCHER="$HOME/.config/rofi/scripts/launch.sh"
LIMIT="${HANDY_HISTORY_LIMIT:-50}"
TEXT="COALESCE(NULLIF(post_processed_text, ''), transcription_text)"

[[ -f "$DB" ]] || { notify-send "Handy history" "Missing $DB"; exit 1; }

ids=()
labels=()
while IFS=$'\t' read -r id label; do
  ids+=("$id")
  labels+=("$label")
done < <(sqlite3 -readonly -separator $'\t' "$DB" \
  "SELECT id, replace(replace(replace($TEXT, char(13), ' '), char(10), ' '), char(9), ' ')
   FROM transcription_history ORDER BY timestamp DESC LIMIT $LIMIT;")

((${#ids[@]})) || { notify-send "Handy history" "No recordings"; exit 0; }

idx="$(printf '%s\n' "${labels[@]}" | "$LAUNCHER" -dmenu -i -format i -p "Handy: ")" || exit 0
[[ -n "$idx" ]] || exit 0

sqlite3 -readonly "$DB" "SELECT $TEXT FROM transcription_history WHERE id = ${ids[$idx]};" \
  | head -c -1 | wl-copy
