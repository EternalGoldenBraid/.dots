#!/bin/bash
set -e

# This script enables and starts specified systemd user services.

# Function to enable and start a systemd service
function enable_start_service {
    local service="$1"
    echo "Enabling and starting service: $service"
    systemctl --user enable "$service"
    systemctl --user start "$service"
    echo "Service $service started successfully \n"
}

function restart_service {
    local service="$1"
    echo "Restarting service: $service"
    systemctl --user restart "$service"
    echo "Service $service restarted successfully \n"
}

# List of systemd user services to be enabled and started
files=(
  "rclone-mount_wallpapers.service"
  "rclone-mount_finance.service"
)

# Iterate over each service in the list and apply operations
for file in "${files[@]}"; do
  enable_start_service "$file"
  # restart_service "$file"
done
