#!/usr/bin/env bash
set -euo pipefail

class_name="calendar-popup"

get_clients_json() {
    local out
    out="$(hyprctl -j clients 2>/dev/null || true)"
    if [ -n "${out}" ] && jq -e . >/dev/null 2>&1 <<< "${out}"; then
        printf '%s\n' "${out}"
        return 0
    fi

    out="$(hyprctl clients -j 2>/dev/null || true)"
    if [ -n "${out}" ] && jq -e . >/dev/null 2>&1 <<< "${out}"; then
        printf '%s\n' "${out}"
        return 0
    fi

    return 1
}

# Toggle existing popup if it's already open.
clients_json="$(get_clients_json || true)"
pids=""
if [ -n "${clients_json}" ]; then
    pids="$(jq -r --arg class "${class_name}" '.[] | select((.class == $class) or (.initialClass == $class)) | .pid' <<< "${clients_json}" || true)"
fi
if [ -n "${pids}" ]; then
    while IFS= read -r pid; do
        [ -n "${pid}" ] && kill "${pid}" 2>/dev/null || true
    done <<< "${pids}"
    exit 0
fi

exec kitty --class "${class_name}" --title "Calendar Popup" --detach \
    bash -lc '
        if command -v ikhal >/dev/null 2>&1; then
            ikhal && exit 0
        fi
        clear
        if command -v khal >/dev/null 2>&1; then
            khal calendar --once 2>/dev/null || true
            echo
            khal list now 30d 2>/dev/null || true
        else
            cal -3
        fi
        echo
        read -r -n 1 -p "Press any key to close..." _
    '
