#!/usr/bin/env python3
"""Audit raster alpha against the existing circular sprite footprint.

This checks static artwork only, not moving visual scale or physics behavior.
Requires Pillow; coordinates follow 512px centered normal and 256px frames.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
NAMES = ('mouse', 'hamster', 'rabbit', 'cat', 'dog', 'fox', 'raccoon',
         'koala', 'panda', 'bear', 'lion', 'elephant')
for name in NAMES:
    for frame in ('normal', 'blink', 'happy', 'surprise'):
        path = ROOT / 'assets' / 'animals' / name / (frame + '.png')
        image = Image.open(path).convert('RGBA')
        assert image.width == image.height and image.width in (256, 512), path
        radius = image.width / 2
        outside = sum(1 for y in range(image.height) for x in range(image.width)
                      if (x + .5 - radius)**2 + (y + .5 - radius)**2 > radius**2
                      and image.getpixel((x, y))[3] > 8)
        assert not outside, (name, frame, outside)
    print('PASS bounded static frames:', name)
print('PASS 48 raster footprints; alpha threshold 8, not dynamic/physics evidence')
