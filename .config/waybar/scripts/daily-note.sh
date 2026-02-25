#!/usr/bin/env bash
set -euo pipefail

note_file="${HOME}/daily.md"
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}"
read_stamp="${state_dir}/daily-note.last_read"
terminal="${TERMINAL:-kitty}"

ensure_paths() {
    mkdir -p "${state_dir}"
}

is_unread() {
    [ -s "${note_file}" ] || return 1
    [ -f "${read_stamp}" ] || return 0
    [ "${note_file}" -nt "${read_stamp}" ]
}

print_status() {
    ensure_paths

    if is_unread; then
        printf '{"text":"NOTE","class":"unread","tooltip":"daily.md has unread changes. Left click: open and mark read. Right click: keep unread."}\n'
    else
        printf '{"text":"note","class":"read","tooltip":"No unread note changes. Left click: open daily.md. Right click: mark unread."}\n'
    fi
}

open_note() {
    ensure_paths
    touch "${read_stamp}"

    if command -v ${terminal} >/dev/null 2>&1; then
        ${terminal} --class "daily-note" --title "Daily Note" --detach \
            bash -lc '${EDITOR:-nvim} "$1"' _ "${note_file}" >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
        nohup xdg-open "${note_file}" >/dev/null 2>&1 &
    else
        "${EDITOR:-vi}" "${note_file}"
    fi

    pkill -RTMIN+9 waybar >/dev/null 2>&1 || true
}

mark_unread() {
    ensure_paths
    rm -f "${read_stamp}"
    pkill -RTMIN+9 waybar >/dev/null 2>&1 || true
}

mark_read() {
    ensure_paths
    touch "${read_stamp}"
    pkill -RTMIN+9 waybar >/dev/null 2>&1 || true
}

case "${1:-status}" in
    status) print_status ;;
    open) open_note ;;
    mark-unread) mark_unread ;;
    mark-read) mark_read ;;
    *)
        echo "Usage: $0 {status|open|mark-unread|mark-read}" >&2
        exit 1
        ;;
esac
