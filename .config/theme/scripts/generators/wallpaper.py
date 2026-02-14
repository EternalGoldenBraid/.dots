from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


def generate(
    palette: dict[str, str],
    source_path: str,
    *,
    input_path: Path,
    output_path: Path,
) -> None:
    """Generate a palette-tinted wallpaper from the source image.

    The source zen wallpaper is grayscale, so we map darks -> terminal_bg and
    highlights -> accent_end using a CLUT gradient.
    """
    magick = shutil.which("magick")
    if not magick:
        raise RuntimeError("ImageMagick 'magick' binary not found in PATH")

    low = palette["terminal_bg"]
    high = palette["accent_end"]
    output_path.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        magick,
        str(input_path),
        "-colorspace",
        "Gray",
        "(",
        "-size",
        "1x256",
        f"gradient:{low}-{high}",
        ")",
        "-clut",
        str(output_path),
    ]
    subprocess.run(cmd, check=True)
