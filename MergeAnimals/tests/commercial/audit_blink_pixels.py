#!/usr/bin/env python3
"""Confirm each derived closed-eye PNG changes only the eye area.
Requires Pillow and @resvg/resvg-js, both development-only dependencies.
This checks pixels, not perceptual quality or legal clearance.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import functools, os, subprocess
from PIL import Image, ImageChops
R = Path(__file__).resolve().parents[2]
js = '''const {Resvg}=require('@resvg/resvg-js');const fs=require('fs');fs.writeFileSync(process.argv[2],new Resvg(fs.readFileSync(process.argv[1]),{fitTo:{mode:'width',value:256}}).render().asPng())'''
with TemporaryDirectory() as td:
    for file in sorted((R/'assets/animals').glob('*/blink.png')):
        name=file.parent.name
        reference=Path(td)/(name+'.png')
        subprocess.run(['node','-e',js,str(R/'art_source/vector_animals'/name/'normal.svg'),str(reference)],check=True,env=os.environ.copy())
        a=Image.open(reference).convert('RGBA');b=Image.open(file).convert('RGBA')
        diff=ImageChops.difference(a,b)
        box=functools.reduce(ImageChops.lighter,diff.split()).getbbox()
        assert box and box[0]>=70 and box[1]>=98 and box[2]<=181 and box[3]<=136,(name,box)
        print('PASS',name,box)
print('PASS eye-area-only pixel difference for 12 independently rasterized 256px frames')
