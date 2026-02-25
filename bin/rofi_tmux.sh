#!/bin/bash
set -u

pick_menu() {
    local prompt="$1"
    if command -v wofi >/dev/null 2>&1; then
        wofi --dmenu --prompt "$prompt"
        return
    fi
    if command -v rofi >/dev/null 2>&1; then
        rofi -dmenu -p "$prompt"
        return
    fi
    if command -v dmenu >/dev/null 2>&1; then
        dmenu -p "$prompt"
        return
    fi
    return 1
}

notify_error() {
    local msg="$1"
    if command -v rofi >/dev/null 2>&1; then
        rofi -e "$msg"
        return
    fi
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "tmux launcher" "$msg"
        return
    fi
    echo "$msg" >&2
}

list_ssh_host_aliases() {
    [ -r "$HOME/.ssh/config" ] || return 0

    awk '
        BEGIN { IGNORECASE = 1 }
        $1 == "Host" {
            for (i = 2; i <= NF; i++) {
                if ($i ~ /^!/) continue
                if ($i ~ /[*?]/) continue
                print $i
            }
        }
    ' "$HOME/.ssh/config" | sort -u
}

focus_or_attach_local() {
    local session="$1"
    local client_pid window

    if tmux list-clients -t "$session" >/dev/null 2>&1; then
        client_pid="$(tmux list-clients -t "$session" -F "#{client_pid}" | head -1)"
        window="$(hyprctl clients -j | jq -r ".[] | select(.pid == $client_pid or .title | contains(\"$session\")) | .address" | head -1)"

        if [ -n "$window" ]; then
            hyprctl dispatch focuswindow "address:$window"
            return
        fi
    fi

    kitty tmux attach-session -t "$session" &
}

declare -a local_sessions
declare -a host_aliases
declare -a sources
declare -a source_labels

while IFS= read -r session; do
    [ -n "$session" ] || continue
    local_sessions+=("$session")
done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null)

while IFS= read -r host; do
    [ -n "$host" ] || continue
    host_aliases+=("$host")
done < <(list_ssh_host_aliases)

[ "${#local_sessions[@]}" -gt 0 ] && {
    sources+=("local")
    source_labels+=("[local] Browse local tmux sessions")
}

for host in "${host_aliases[@]}"; do
    sources+=("remote"$'\t'"$host")
    source_labels+=("[$host] Browse remote tmux sessions")
done

if [ "${#sources[@]}" -eq 0 ]; then
    notify_error "No local tmux sessions or SSH host aliases found"
    exit 1
fi

selected_source="$(
    printf '%s\n' "${source_labels[@]}" | pick_menu "Tmux source:"
)"

[ -n "${selected_source:-}" ] || exit 0

selected_source_idx=-1
for i in "${!source_labels[@]}"; do
    if [ "${source_labels[$i]}" = "$selected_source" ]; then
        selected_source_idx="$i"
        break
    fi
done

[ "$selected_source_idx" -ge 0 ] || exit 1

IFS=$'\t' read -r source_kind source_host <<<"${sources[$selected_source_idx]}"

if [ "$source_kind" = "local" ]; then
    declare -a local_labels

    for session in "${local_sessions[@]}"; do
        local_labels+=("[local] $session")
    done

    selected_local="$(
        printf '%s\n' "${local_labels[@]}" | pick_menu "Local tmux session:"
    )"
    [ -n "${selected_local:-}" ] || exit 0

    selected_local_idx=-1
    for i in "${!local_labels[@]}"; do
        if [ "${local_labels[$i]}" = "$selected_local" ]; then
            selected_local_idx="$i"
            break
        fi
    done

    [ "$selected_local_idx" -ge 0 ] || exit 1
    focus_or_attach_local "${local_sessions[$selected_local_idx]}"
    exit 0
fi

declare -a remote_sessions
declare -a remote_labels

while IFS= read -r session; do
    [ -n "$session" ] || continue
    remote_sessions+=("$session")
    remote_labels+=("[$source_host] $session")
done < <(ssh -o ConnectTimeout=5 "$source_host" "tmux list-sessions -F '#{session_name}' 2>/dev/null")

if [ "${#remote_sessions[@]}" -eq 0 ]; then
    notify_error "No tmux sessions found on $source_host"
    exit 1
fi

selected_remote="$(
    printf '%s\n' "${remote_labels[@]}" | pick_menu "Remote tmux session:"
)"

[ -n "${selected_remote:-}" ] || exit 0

selected_remote_idx=-1
for i in "${!remote_labels[@]}"; do
    if [ "${remote_labels[$i]}" = "$selected_remote" ]; then
        selected_remote_idx="$i"
        break
    fi
done

[ "$selected_remote_idx" -ge 0 ] || exit 1

escaped_session="$(printf '%q' "${remote_sessions[$selected_remote_idx]}")"
kitty ssh -t "$source_host" "tmux attach-session -t $escaped_session" &
