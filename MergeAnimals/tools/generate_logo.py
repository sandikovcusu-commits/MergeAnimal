#!/usr/bin/env python3
"""Generate an original vector wordmark using bundled DejaVu glyph outlines."""
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from pathlib import Path
r=Path(__file__).resolve().parents[1]
f=TTFont(str(r/'assets/fonts/DejaVuSans.ttf')); glyphs=f.getGlyphSet(); cmap=f.getBestCmap(); metrics=f['hmtx'].metrics; units=f['head'].unitsPerEm

def word(text, size, y, fill, stroke):
 scale=size/units; width=sum(metrics[cmap[ord(c)]][0]*scale for c in text); x=(720-width)/2
 paths=[]
 for c in text:
  g=cmap[ord(c)]; pen=SVGPathPen(glyphs); glyphs[g].draw(pen); d=pen.getCommands()
  if d: paths.append(f'<path d="{d}" transform="translate({x:.2f} {y}) scale({scale:.5f} {-scale:.5f})" fill="{fill}" stroke="{stroke}" stroke-width="95" stroke-linejoin="round" paint-order="stroke"/>')
  x+=metrics[g][0]*scale
 return ''.join(paths)
svg='''<svg xmlns="http://www.w3.org/2000/svg" width="720" height="230" viewBox="0 0 720 230">
<path d="M69 44 Q49 12 29 40 Q30 63 70 69 M651 44 Q671 12 691 40 Q690 63 650 69" fill="#9acb7a" stroke="#4c6947" stroke-width="5"/>
<path d="M147 182 Q360 160 573 182 L553 216 Q360 204 167 216 Z" fill="#edbf76" stroke="#79583b" stroke-width="5"/>
<circle cx="54" cy="98" r="10" fill="#f2bc62"/><circle cx="666" cy="98" r="10" fill="#f2bc62"/>
'''+word('MERGE',78,82,'#f5bd67','#553d2c')+word('ANIMALS',83,160,'#a9d891','#496545')+word('WILD GARDEN',32,207,'#563e2c','#edbf76')+'</svg>'
(r/'assets/ui/logo/wild_garden.svg').write_text(svg)
