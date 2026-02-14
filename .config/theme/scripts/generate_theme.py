#!/usr/bin/env python3
import json
import pathlib
import sys

from generators import bash, hypr, kitty, nvim, tmux, vifm, wallpaper, waybar
from generators.common import prepare_palette


def main() -> int:
    home = pathlib.Path.home()
    palette_path = pathlib.Path(
        sys.argv[1] if len(sys.argv) > 1 else home / ".dotfiles/.config/theme/palette.json"
    )

    if not palette_path.is_file():
        print(f"ERROR: palette file not found: {palette_path}", file=sys.stderr)
        return 1

    with palette_path.open("r", encoding="utf-8") as f:
        raw_palette = json.load(f)

    try:
        palette = prepare_palette(raw_palette)
    except ValueError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 1

    targets = {
        "tmux": {
            "out": home / ".dotfiles/.config/tmux/theme.generated.conf",
            "render": tmux.render,
        },
        "waybar": {
            "out": home / ".dotfiles/.config/waybar/colors.generated.css",
            "render": waybar.render,
        },
        "nvim": {
            "out": home / ".dotfiles/.config/nvim/lua/theme/generated_palette.lua",
            "render": nvim.render,
        },
        "vifm": {
            "out": home / ".dotfiles/.config/vifm/colors/generated.vifm",
            "render": vifm.render,
        },
        "kitty": {
            "out": home / ".dotfiles/.config/kitty/theme.generated.conf",
            "render": kitty.render,
        },
        "bash": {
            "out": home / ".dotfiles/.config/.colors",
            "render": bash.render,
        },
        "hypr": {
            "out": home / ".dotfiles/.config/hypr/colors.generated.conf",
            "render": hypr.render,
        },
    }

    source_path = str(palette_path)
    for target in targets.values():
        out_path = target["out"]
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(target["render"](palette, source_path), encoding="utf-8")
        print(f"Generated {out_path}")

    wallpaper_in = home / ".dotfiles/media/zen-wallpaper.png"
    wallpaper_out = home / ".dotfiles/media/zen-wallpaper.generated.png"
    wallpaper.generate(
        palette,
        source_path,
        input_path=wallpaper_in,
        output_path=wallpaper_out,
    )
    print(f"Generated {wallpaper_out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
