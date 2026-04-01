# Theme System

This directory is the source of truth for generated theme colors.

## Files

- `palette.json`: Canonical color palette
- Optional terminal ANSI role keys: `terminal_green`, `terminal_cyan`
- Optional shared selection/highlight key: `selection_bg`
- `scripts/generate_theme.py`: Generates app-specific theme files from the palette
- `scripts/generators/README.md`: Contract for per-app generator signatures and responsibilities
- `scripts/generators/*.py`: App-specific renderers (`tmux`, `waybar`, `nvim`, `vifm`)
- `~/.dotfiles/.config/tmux/theme.generated.conf`: Generated tmux theme output (do not edit by hand)
- `~/.dotfiles/.config/waybar/colors.generated.css`: Generated Waybar colors (do not edit by hand)
- `~/.dotfiles/.config/nvim/lua/theme/generated_palette.lua`: Generated Neovim palette module (do not edit by hand)
- `~/.dotfiles/.config/vifm/colors/generated.vifm`: Generated Vifm colorscheme (do not edit by hand)
- `~/.dotfiles/.config/kitty/theme.generated.conf`: Generated Kitty colors (do not edit by hand)
- `~/.dotfiles/.config/foot/theme.generated.ini`: Generated Foot colors (do not edit by hand)
- `~/.dotfiles/.config/lazygit/theme.generated.yml`: Generated LazyGit theme overrides (do not edit by hand)
- `~/.dotfiles/.config/.colors`: Generated Bash-compatible color vars (do not edit by hand)
- `~/.dotfiles/.config/hypr/colors.generated.conf`: Generated Hyprland colors (do not edit by hand)
- `~/.dotfiles/media/zen-wallpaper.generated.png`: Palette-tinted generated wallpaper

## Usage

After changing colors in `palette.json`, run:

```bash
~/bin/theme-apply
```

To switch between preset palettes:

```bash
~/bin/theme-switch --list
~/bin/theme-switch winter-nord
~/bin/theme-switch --restore
```

This will:
1. Regenerate tmux theme output from the palette
2. Regenerate Waybar, Neovim, Vifm, Kitty, Bash, Hyprland, and wallpaper outputs
3. Reload tmux config if tmux is currently running
4. Restart Waybar if it is currently running
5. Reload Hyprland config if running in current shell
6. Restart Hyprpaper if it is currently running

## Notes

- Edit only `palette.json` for color changes.
- Generated files should be treated as build artifacts.
- Current rollout targets tmux first; other apps can be added to the generator later.

## Semantic Token Migration Plan

Goal: keep one globally intelligible palette contract while letting each app keep its own local color associations.

### Why this is sensible with current generators

Current generators already cluster into shared roles:

- Background layers: `base`, `mantle`, `crust`, `surface0`, `surface1`
- Foreground tiers: `text`, `overlay1`, `accent_text_left`, `accent_text_right`
- Emphasis/status: `accent_start`, `accent_end`, `red`, `peach`
- Selection/highlight: `selection_bg`

That means we can introduce semantic names without changing visual intent first.

### Proposed semantic base (global contract)

- `bg.base`, `bg.elevated`, `bg.overlay`, `bg.sunken`
- `fg.primary`, `fg.muted`, `fg.subtle`, `fg.inverse`
- `accent.primary`, `accent.secondary`, `accent.success`, `accent.danger`
- `role.keyword`, `role.function`, `role.type`, `role.string`, `role.number`, `role.operator`, `role.comment`, `role.error`, `role.warn`, `role.info`, `role.hint`

Notes:
- `role.*` is mainly for editor syntax and diagnostics.
- Non-editor generators can ignore `role.*` and stay on `bg.*`, `fg.*`, `accent.*`.

### Generator compatibility matrix

- `nvim.py`: fully benefits from `bg.*`, `fg.*`, `accent.*`, and `role.*` (highest priority target).
- `tmux.py`: natural fit for `bg.*`, `fg.*`, `accent.*`; no `role.*` needed.
- `waybar.py`: natural fit for `bg.*`, `fg.*`, `accent.*`; no `role.*` needed.
- `kitty.py`: natural fit for `bg.*`, `fg.*`, `accent.*`; ANSI slots can derive from semantic accents/roles.
- `foot.py`: same as kitty.
- `vifm.py`: fit for `bg.*`, `fg.*`, `accent.*`, plus optional `role.error/warn`.
- `hypr.py`: only needs accent and muted foreground roles.
- `bash.py`: prompt/status colors map to `fg.*` and `accent.*`.
- `wallpaper.py`: uses background + accent gradient only.

Conclusion: semantic tokens are cross-generator sensible; only Neovim needs richer role-level mapping work.

### Execution phases

1. Define semantic schema in `palette.json` while keeping legacy keys.
2. Extend `scripts/generators/common.py` to validate semantic keys and backfill them from legacy keys.
3. Update each generator to prefer semantic keys with legacy fallback.
4. Add contrast checks in generation for `fg.*`/`role.*` against `bg.base`.
5. Migrate Neovim mappings to explicit `role.*` usage for syntax and diagnostics.
6. Deprecate legacy keys after all generators consume semantic tokens.

### Safety constraints during migration

- No visual churn in phase 1-3: semantic keys should initially map 1:1 to current output intent.
- Keep generated file shapes stable to avoid breaking app reloads.
- Fail fast on invalid hex values; warn (or fail) on low-contrast role colors.
