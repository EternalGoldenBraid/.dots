#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/handy-status.env"
IDLE_BYPASS_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/idle-bypass.enabled"
STATUS="idle"
UPDATED_AT=0
NOW="$(date +%s)"

if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

if [[ "${STATUS:-idle}" == "recording" && $((NOW - ${UPDATED_AT:-0})) -gt 7200 ]]; then
    STATUS="idle"
fi

if [[ "${STATUS:-idle}" == "transcribing" && $((NOW - ${UPDATED_AT:-0})) -gt 45 ]]; then
    STATUS="idle"
fi

if [[ -f "$IDLE_BYPASS_FILE" ]]; then
    printf '{"text":"  NO LOCK / SLEEP  ","class":["idle-bypass","active"],"alt":"idle-bypass"}\n'
    exit 0
fi

case "${STATUS:-idle}" in
    recording)
        printf '{"text":"  LIVE DICTATION  ","class":["recording","active"],"alt":"recording"}\n'
        ;;
    transcribing)
        printf '{"text":"  TRANSCRIBING  ","class":["transcribing","active"],"alt":"transcribing"}\n'
        ;;
    *)
        printf '{"text":"","class":["idle"],"alt":"idle"}\n'
        ;;
esac
