#!/usr/bin/env bash
# Emits one JSON line per second: latency (ms, null on loss) to the default
# gateway and to 1.1.1.1, plus the kernel neighbour (ARP) table.
set -u

rtt() {
    ping -n -c1 -W1 "$1" 2>/dev/null | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p'
}

while :; do
    route=$(ip -j route show default 2>/dev/null)
    gwip=$(jq -r '.[0].gateway // empty' <<<"$route")
    dev=$(jq -r '.[0].dev // empty' <<<"$route")
    tmp=$(mktemp -d)
    [[ -n $gwip ]] && rtt "$gwip" >"$tmp/gw" &
    rtt 1.1.1.1 >"$tmp/inet" &
    wait
    jq -cn \
        --arg gwip "$gwip" --arg dev "$dev" \
        --arg gw "$(cat "$tmp/gw" 2>/dev/null)" --arg inet "$(cat "$tmp/inet" 2>/dev/null)" \
        --argjson neigh "$(ip -j neigh 2>/dev/null | jq -c '[.[] | select(.lladdr) | {ip: .dst, mac: .lladdr, dev: .dev, state: .state[0]}]')" \
        '{gwip:$gwip, dev:$dev, gw:($gw|tonumber? // null), inet:($inet|tonumber? // null), neigh:$neigh}' || exit
    rm -rf "$tmp"
    sleep 1
done
