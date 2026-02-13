#!/usr/bin/env python3
import json
import pathlib
import sys

from generators import nvim, tmux, vifm, waybar
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
    }

    source_path = str(palette_path)
    for target in targets.values():
        out_path = target["out"]
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(target["render"](palette, source_path), encoding="utf-8")
        print(f"Generated {out_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
