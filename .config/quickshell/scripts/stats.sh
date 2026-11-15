#!/usr/bin/env bash
# One JSON line of slow-changing system stats for the bar.

set -u

RT="${XDG_RUNTIME_DIR:-/tmp}"
CPU_PREV="$RT/qs-cpu-prev"

read -r _ u n s idle io irq sirq _ < /proc/stat
total=$((u + n + s + idle + io + irq + sirq))
busy=$((total - idle - io))
cpu=0
if [[ -f $CPU_PREV ]]; then
    read -r pt pb < "$CPU_PREV"
    dt=$((total - pt))
    ((dt > 0)) && cpu=$(((busy - pb) * 100 / dt))
fi
echo "$total $busy" > "$CPU_PREV"

mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)

temp=0
for z in /sys/class/thermal/thermal_zone*; do
    if [[ $(<"$z/type") == x86_pkg_temp ]]; then temp=$(($(<"$z/temp") / 1000)); break; fi
done

bl=-1
for d in /sys/class/backlight/*; do
    [[ -r $d/brightness ]] && bl=$(($(<"$d/brightness") * 100 / $(<"$d/max_brightness"))) && break
done

net_kind=none net_name="" net_sig=0
wifi=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes' | head -n1 || true)
if [[ -n $wifi ]]; then
    IFS=: read -r _ net_name net_sig <<< "$wifi"
    net_kind=wifi
elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q '^ethernet:connected'; then
    net_kind=ethernet
fi

profile=$(powerprofilesctl get 2>/dev/null || echo balanced)
shade=$(hyprshade current 2>/dev/null || true)
[[ -n $shade && $shade != off ]] && shade_on=true || shade_on=false
submap=$(hyprctl submap 2>/dev/null || true)
[[ $submap == default ]] && submap=""
layout=$(hyprctl devices -j 2>/dev/null | jq -r '[.keyboards[] | select(.main)][0].active_keymap // ""')
note=$("$HOME/.config/waybar/scripts/daily-note.sh" status 2>/dev/null | jq -r '.class // "read"')

jq -cn --argjson cpu "$cpu" --argjson mem "$mem" --argjson temp "$temp" --argjson bl "$bl" \
    --arg netKind "$net_kind" --arg netName "$net_name" --argjson netSig "${net_sig:-0}" \
    --arg profile "$profile" --argjson shade "$shade_on" --arg submap "$submap" \
    --arg layout "$layout" --arg note "$note" \
    '{cpu:$cpu,mem:$mem,temp:$temp,backlight:$bl,
      net:{kind:$netKind,name:$netName,signal:$netSig},
      profile:$profile,shade:$shade,submap:$submap,layout:$layout,note:$note}'
