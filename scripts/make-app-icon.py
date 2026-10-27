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
# The black tile spans roughly 112..1142 of the 1254 px artwork; crop slightly inside it.
inset = 122
image = image.crop((inset, inset, 1254 - inset, 1254 - inset)).resize((1024, 1024), Image.LANCZOS)
black = image.getpixel((512, 40))
# Flood fill the white margin that remains in each rounded corner with the tile's black.
for corner in [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]:
    ImageDraw.floodfill(image, corner, black, thresh=60)
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
