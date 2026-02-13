import re

HEX_COLOR_RE = re.compile(r"^#[0-9a-fA-F]{6}$")

REQUIRED_KEYS = [
    "base",
    "mantle",
    "crust",
    "text",
    "surface0",
    "surface1",
    "overlay1",
    "accent_start",
    "accent_end",
    "accent_text_left",
    "accent_text_right",
]


def prepare_palette(palette: dict[str, str]) -> dict[str, str]:
    missing = [k for k in REQUIRED_KEYS if k not in palette]
    if missing:
        raise ValueError(f"missing palette keys: {', '.join(missing)}")

    merged = dict(palette)
    merged.setdefault("peach", "#fab387")
    merged.setdefault("bar_text_mid", merged["text"])
    merged.setdefault("red", "#f38ba8")
    merged.setdefault("terminal_bg", merged["base"])
    merged.setdefault("terminal_fg", merged["text"])

    validate_keys = REQUIRED_KEYS + ["peach", "bar_text_mid", "red", "terminal_bg", "terminal_fg"]
    for key in validate_keys:
        value = merged.get(key)
        if not isinstance(value, str) or not HEX_COLOR_RE.match(value):
            raise ValueError(f"invalid color for {key}: {value}")

    return merged


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    return (int(hex_color[1:3], 16), int(hex_color[3:5], 16), int(hex_color[5:7], 16))


def rgb_distance_sq(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def rgb_to_xterm_index(rgb: tuple[int, int, int]) -> int:
    levels = [0, 95, 135, 175, 215, 255]

    def nearest_level(v: int) -> int:
        return min(range(6), key=lambda i: abs(levels[i] - v))

    r_idx = nearest_level(rgb[0])
    g_idx = nearest_level(rgb[1])
    b_idx = nearest_level(rgb[2])
    cube_rgb = (levels[r_idx], levels[g_idx], levels[b_idx])
    cube_index = 16 + 36 * r_idx + 6 * g_idx + b_idx

    gray_avg = int(round((rgb[0] + rgb[1] + rgb[2]) / 3))
    gray_steps = [8 + 10 * i for i in range(24)]
    gray_i = min(range(24), key=lambda i: abs(gray_steps[i] - gray_avg))
    gray_rgb = (gray_steps[gray_i], gray_steps[gray_i], gray_steps[gray_i])
    gray_index = 232 + gray_i

    return cube_index if rgb_distance_sq(rgb, cube_rgb) <= rgb_distance_sq(rgb, gray_rgb) else gray_index
