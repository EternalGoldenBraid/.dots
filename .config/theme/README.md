# Theme System

This directory is the source of truth for generated theme colors.

## Files

- `palette.json`: Canonical color palette
- `scripts/generate_theme.py`: Generates app-specific theme files from the palette
- `~/.dotfiles/.config/tmux/theme.generated.conf`: Generated tmux theme output (do not edit by hand)
- `~/.dotfiles/.config/waybar/colors.generated.css`: Generated Waybar colors (do not edit by hand)
- `~/.dotfiles/.config/nvim/lua/theme/generated_palette.lua`: Generated Neovim palette module (do not edit by hand)

## Usage

After changing colors in `palette.json`, run:

```bash
~/bin/theme-apply
```

This will:
1. Regenerate tmux theme output from the palette
2. Regenerate Waybar and Neovim theme outputs
3. Reload tmux config if tmux is currently running
4. Restart Waybar if it is currently running

## Notes

- Edit only `palette.json` for color changes.
- Generated files should be treated as build artifacts.
- Current rollout targets tmux first; other apps can be added to the generator later.
