- Make sure the destination directories exist for rclone mounts.
- Place in `~/.config/systemd/user/<filename>.service`
- Run `systemctl --user enable <filename>.service`
- Run `systemctl --user start <filename>.service`

Troubleshooting:
- `systemctl --user status <filename>.service`
- `journalctl --user -u <filename>.service`
