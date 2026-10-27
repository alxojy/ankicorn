#!/usr/bin/env python3
"""Builds the 1024x1024 opaque AppIcon from design/app-icon-source.png (needs Pillow).

Crops to the black tile, fills the white corner areas with the tile's black (iOS applies the mask) and writes
app/Cornhub/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png plus its Contents.json.
"""
import json
import pathlib

from PIL import Image, ImageDraw

root = pathlib.Path(__file__).resolve().parent.parent
source = root / "design" / "app-icon-source.png"
out_dir = root / "app/Cornhub/Resources/Assets.xcassets/AppIcon.appiconset"

image = Image.open(source).convert("RGB")
# The black tile spans roughly 112..1142 of the 1254 px artwork; crop inside it, away from the edge anti-aliasing.
inset = 136
image = image.crop((inset, inset, 1254 - inset, 1254 - inset)).resize((1024, 1024), Image.LANCZOS)
black = image.getpixel((512, 40))
# Flood fill the white margin that remains in each rounded corner with the tile's black.
for corner in [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]:
    ImageDraw.floodfill(image, corner, black, thresh=160)
# Anti-aliased leftovers along the corner arcs: paint everything outside a circle of radius R in each corner black.
R = 250
mask = Image.new("L", (1024, 1024), 255)
draw = ImageDraw.Draw(mask)
for cx, cy, x0, y0 in [(R, R, 0, 0), (1023 - R, R, 1024 - R, 0), (R, 1023 - R, 0, 1024 - R), (1023 - R, 1023 - R, 1024 - R, 1024 - R)]:
    draw.rectangle((x0, y0, x0 + R - 1, y0 + R - 1), fill=0)
    draw.ellipse((cx - R, cy - R, cx + R, cy + R), fill=255)
# Keep real content: only the corner squares are touched, and the circle keeps the tile inside.
image.paste(Image.new("RGB", (1024, 1024), black), mask=Image.eval(mask, lambda v: 255 - v))
image.save(out_dir / "AppIcon.png", format="PNG")
(out_dir / "Contents.json").write_text(
    json.dumps(
        {
            "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
            "info": {"author": "xcode", "version": 1},
        },
        indent=2,
    )
    + "\n"
)
