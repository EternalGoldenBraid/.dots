#!/usr/bin/env bash
# Merge agent, idle-bypass and dictation state into one JSON object for shell.qml.

set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
STATE_FILE="$CACHE/handy-status.env"
BYPASS_FILE="$CACHE/idle-bypass.enabled"
NOW="$(date +%s)"
STATUS="idle"
UPDATED_AT=0

if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

if [[ "$STATUS" == "recording" && $((NOW - UPDATED_AT)) -gt 7200 ]]; then STATUS="idle"; fi
if [[ "$STATUS" == "transcribing" && $((NOW - UPDATED_AT)) -gt 45 ]]; then STATUS="idle"; fi

agent="$("$HOME/.local/bin/agent-notify" waybar 2>/dev/null || echo '{}')"
bypass=false
[[ -f "$BYPASS_FILE" ]] && bypass=true

jq -cn --argjson agent "$agent" --argjson bypass "$bypass" --arg dictation "$STATUS" '
    {
      agent: {
        state: ([$agent.class] | flatten | map(select(. == "waiting" or . == "asking" or . == "idle" or . == "working")) | first // "none"),
        text: ($agent.text // ""),
        dnd: ([$agent.class] | flatten | index("dnd") != null)
      },
      bypass: $bypass,
      dictation: $dictation
    }'
