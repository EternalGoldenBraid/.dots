#!/bin/bash

# Check if the system is running on battery
if upower -e | grep -q BAT; then
    BATTERY=$(upower -i $(upower -e | grep BAT) | grep "state" | awk '{print $2}')
    if [ "$BATTERY" = "discharging" ]; then
        systemctl suspend
    fi
fi
