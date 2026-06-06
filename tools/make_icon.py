#!/usr/bin/env python3
"""Turn a green rounded-square-on-black icon into a full-bleed opaque app icon.

Replaces the black background (outside the rounded square + the rounded corners)
with the icon's own green, removes any alpha, and exports a 1024x1024 PNG that's
ready for iOS/Android (the OS applies the rounded mask itself).

Usage:  python3 make_icon.py input.png output_1024.png
"""
import sys
import numpy as np
from PIL import Image


def main(src: str, dst: str) -> None:
    im = Image.open(src).convert("RGB")
    a = np.array(im).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]

    # The background green: clearly green pixels (green channel dominant, not white).
    bg_mask = (g > 40) & (g < 130) & (r < g) & (b < g) & (np.maximum(r, b) < 130)
    bg = (np.median(a[bg_mask], axis=0) if bg_mask.sum() > 1000
          else np.array([26, 77, 53])).astype(np.uint8)

    # Black / near-black (the outside + rounded corners): low green channel.
    dark = (g < 30) & (r < 40) & (b < 40)

    out = a.astype(np.uint8).copy()
    out[dark] = bg

    Image.fromarray(out, "RGB").resize((1024, 1024), Image.LANCZOS).save(dst)
    print(f"wrote {dst}  (bg green = {tuple(int(x) for x in bg)})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python3 make_icon.py input.png output_1024.png")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
