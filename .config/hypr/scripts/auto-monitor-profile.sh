#!/usr/bin/env bash

set -euo pipefail

HYPR_DIR="${HOME}/.config/hypr"
PROFILE_ROOT="${HYPR_DIR}/monitor-profiles"
ACTIVE_MONITORS_CONF="${HYPR_DIR}/monitors.conf"
ACTIVE_WORKSPACES_CONF="${HYPR_DIR}/workspaces.conf"
STATE_FILE="${HYPR_DIR}/.last-monitor-profile"

log() {
    printf '[monitor-profile] %s\n' "$*" >&2
}

inside_hypr() {
    [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]
}

current_tokens() {
    if ! inside_hypr; then
        return 1
    fi

    hyprctl monitors all 2>/dev/null | awk '
        /^Monitor / {
            print "name:" $2
        }
        /^[[:space:]]*description:[[:space:]]*/ {
            sub(/^[[:space:]]*description:[[:space:]]*/, "")
            print "desc:" $0
        }
    '
}

normalize_lines() {
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | sort -u
}

find_matching_profile() {
    local current tmp_current profile fp_file tmp_fp missing
    current="$(current_tokens || true)"
    [ -n "$current" ] || return 1

    tmp_current="$(mktemp)"
    printf '%s\n' "$current" | normalize_lines > "$tmp_current"

    for profile in "$PROFILE_ROOT"/*; do
        [ -d "$profile" ] || continue
        fp_file="$profile/fingerprint.txt"
        [ -f "$fp_file" ] || continue

        tmp_fp="$(mktemp)"
        normalize_lines < "$fp_file" > "$tmp_fp"
        if [ ! -s "$tmp_fp" ]; then
            rm -f "$tmp_fp"
            continue
        fi

        missing="$(comm -23 "$tmp_fp" "$tmp_current" || true)"
        if [ -z "$missing" ]; then
            rm -f "$tmp_current" "$tmp_fp"
            basename "$profile"
            return 0
        fi
        rm -f "$tmp_fp"
    done

    rm -f "$tmp_current"
    return 1
}

apply_profile() {
    local profile_name profile_dir
    profile_name="$1"
    profile_dir="${PROFILE_ROOT}/${profile_name}"

    [ -f "${profile_dir}/monitors.conf" ] || {
        log "missing ${profile_dir}/monitors.conf"
        return 1
    }

    cp "${profile_dir}/monitors.conf" "$ACTIVE_MONITORS_CONF"

    if [ -f "${profile_dir}/workspaces.conf" ]; then
        cp "${profile_dir}/workspaces.conf" "$ACTIVE_WORKSPACES_CONF"
    fi

    printf '%s\n' "$profile_name" > "$STATE_FILE"

    if inside_hypr; then
        hyprctl reload >/dev/null 2>&1 || true
    fi

    log "applied profile: ${profile_name}"
}

apply_matching() {
    local matched current_applied
    matched="$(find_matching_profile || true)"

    if [ -z "$matched" ]; then
        log "no profile matched connected monitors"
        return 0
    fi

    current_applied=""
    if [ -f "$STATE_FILE" ]; then
        current_applied="$(cat "$STATE_FILE" 2>/dev/null || true)"
    fi

    if [ "$matched" = "$current_applied" ]; then
        return 0
    fi

    apply_profile "$matched"
}

capture_profile() {
    local profile_name profile_dir mode tmp
    profile_name="$1"
    mode="${2:-desc}"
    profile_dir="${PROFILE_ROOT}/${profile_name}"

    mkdir -p "$profile_dir"

    if [ -f "$ACTIVE_MONITORS_CONF" ]; then
        cp "$ACTIVE_MONITORS_CONF" "${profile_dir}/monitors.conf"
    fi
    if [ -f "$ACTIVE_WORKSPACES_CONF" ]; then
        cp "$ACTIVE_WORKSPACES_CONF" "${profile_dir}/workspaces.conf"
    fi

    case "$mode" in
        desc)
            tmp="$(mktemp)"
            current_tokens | awk '/^desc:/' | normalize_lines > "$tmp"
            if [ -s "$tmp" ]; then
                cp "$tmp" "${profile_dir}/fingerprint.txt"
            else
                current_tokens | awk '/^name:/' | normalize_lines > "${profile_dir}/fingerprint.txt"
            fi
            rm -f "$tmp"
            ;;
        names)
            current_tokens | awk '/^name:/' | normalize_lines > "${profile_dir}/fingerprint.txt"
            ;;
        all)
            current_tokens | normalize_lines > "${profile_dir}/fingerprint.txt"
            ;;
        *)
            log "unsupported capture mode: ${mode} (use: desc|names|all)"
            return 1
            ;;
    esac

    log "captured profile: ${profile_name} (mode=${mode})"
}

watch_events() {
    local sock
    apply_matching

    sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

    if ! command -v socat >/dev/null 2>&1 || [ ! -S "$sock" ]; then
        log "watch mode unavailable (missing socat or socket); applied once only"
        return 0
    fi

    stdbuf -oL socat -U - "UNIX-CONNECT:${sock}" | while IFS= read -r line; do
        case "$line" in
            monitoradded*|monitorremoved*)
                sleep 1
                apply_matching
                ;;
        esac
    done
}

usage() {
    cat <<'EOF'
Usage:
  auto-monitor-profile.sh apply
  auto-monitor-profile.sh watch
  auto-monitor-profile.sh capture <profile-name> [desc|names|all]

Notes:
  - Profiles live in ~/.config/hypr/monitor-profiles/<profile-name>/
  - fingerprint.txt decides when a profile is selected
EOF
}

main() {
    local cmd
    cmd="${1:-watch}"

    case "$cmd" in
        apply)
            apply_matching
            ;;
        watch)
            watch_events
            ;;
        capture)
            [ "${2:-}" ] || {
                usage
                return 1
            }
            capture_profile "$2" "${3:-desc}"
            ;;
        *)
            usage
            return 1
            ;;
    esac
}

main "$@"
