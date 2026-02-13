# Theme System

This directory is the source of truth for generated theme colors.

## Files

- `palette.json`: Canonical color palette
- `scripts/generate_theme.py`: Generates app-specific theme files from the palette
- `~/.dotfiles/.config/tmux/theme.generated.conf`: Generated tmux theme output (do not edit by hand)

## Usage

After changing colors in `palette.json`, run:

```bash
~/bin/theme-apply
```

This will:
1. Regenerate tmux theme output from the palette
2. Reload tmux config if tmux is currently running

## Notes

- Edit only `palette.json` for color changes.
- Generated files should be treated as build artifacts.
- Current rollout targets tmux first; other apps can be added to the generator later.
