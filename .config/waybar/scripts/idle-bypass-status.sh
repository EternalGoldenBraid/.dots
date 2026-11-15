#!/usr/bin/env bash

set -euo pipefail

IDLE_BYPASS_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/idle-bypass.enabled"

if [[ -f "$IDLE_BYPASS_FILE" ]]; then
    printf '{"text":"  NO LOCK / SLEEP  ","class":["idle-bypass","active"],"alt":"idle-bypass"}\n'
else
    printf '{"text":"","class":["idle"],"alt":"idle"}\n'
fi
