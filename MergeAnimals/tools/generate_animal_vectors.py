#!/usr/bin/env python3
"""Create twelve original circular vector character designs for this project.

Hand-authored geometric SVG paths and palettes; no raster/image/model inputs.
The output is deterministic; the 512-unit viewBox maps exactly to a physics
circle centered at (256, 256) with radius 256. See the audit and license report.
"""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'art_source' / 'vector_animals'
OUTLINE = '#553e39'
# base (highlight, shade), ear, muzzle, markings
PALETTES = {
 'mouse': ('#d0ced7','#9f99ae','#efb8c3','#f5e4df','#aca4b7'),
 'hamster': ('#f6c878','#ce8a4d','#f8b3a1','#fff0cf','#df9d58'),
 'rabbit': ('#f3eee8','#c7c1c8','#f1b4bf','#fffaf4','#d7ced2'),
 'cat': ('#f4c37a','#c8854f','#efaca2','#fff0dc','#a66c49'),
 'dog': ('#eac195','#b88567','#c99183','#fff0dc','#986b57'),
 'fox': ('#f9a55d','#d2643a','#f2b5a5','#fff2df','#a75139'),
 'raccoon': ('#c7c8c8','#8a939a','#e9b4ad','#f1e7dc','#64727c'),
 'koala': ('#ced4d1','#939fa3','#e5a4a9','#f2eee5','#7d8d92'),
 'panda': ('#fff9e9','#d8ddd3','#eab6ad','#fffdf3','#455459'),
 'bear': ('#cda276','#9e6d54','#e6aaa2','#f4d5ae','#825c4c'),
 'lion': ('#f7cc72','#db9b4e','#eeb29b','#fff0cf','#b66e36'),
 'elephant': ('#b5ced2','#87a9b4','#ecb2b6','#e4edef','#7c9fab'),
}
# All distinguishing silhouette elements lie inside the collision disk.
EARS = {
 'mouse': '<circle cx="111" cy="142" r="64"/><circle cx="401" cy="142" r="64"/>',
 'hamster': '<circle cx="126" cy="126" r="48"/><circle cx="386" cy="126" r="48"/>',
 'rabbit': '<path d="M145 157 Q125 94 158 42 Q179 18 197 58 L219 152Z"/><path d="M367 157 Q387 94 354 42 Q333 18 315 58 L293 152Z"/>',
 'cat': '<path d="M92 168 L113 65 Q121 38 150 64 L211 130Z"/><path d="M420 168 L399 65 Q391 38 362 64 L301 130Z"/>',
 'dog': '<path d="M100 144 Q42 161 53 258 Q58 317 102 306 L152 212Z"/><path d="M412 144 Q470 161 459 258 Q454 317 410 306 L360 212Z"/>',
 'fox': '<path d="M88 169 L108 64 Q115 42 143 64 L209 132Z"/><path d="M424 169 L404 64 Q397 42 369 64 L303 132Z"/>',
 'raccoon': '<path d="M104 158 L120 79 Q126 55 151 75 L211 135Z"/><path d="M408 158 L392 79 Q386 55 361 75 L301 135Z"/>',
 'koala': '<circle cx="91" cy="181" r="70"/><circle cx="421" cy="181" r="70"/>',
 'panda': '<circle cx="121" cy="129" r="52"/><circle cx="391" cy="129" r="52"/>',
 'bear': '<circle cx="127" cy="124" r="53"/><circle cx="385" cy="124" r="53"/>',
 'lion': '<circle cx="129" cy="127" r="44"/><circle cx="383" cy="127" r="44"/>',
 'elephant': '<path d="M117 140 Q53 115 48 221 Q45 314 98 328 Q138 331 159 260Z"/><path d="M395 140 Q459 115 464 221 Q467 314 414 328 Q374 331 353 260Z"/>',
}
INNER = {
 'mouse': '<circle cx="111" cy="142" r="38"/><circle cx="401" cy="142" r="38"/>',
 'hamster': '<circle cx="126" cy="126" r="25"/><circle cx="386" cy="126" r="25"/>',
 'rabbit': '<path d="M162 137 Q151 82 172 57 Q184 45 191 75 L201 145Z"/><path d="M350 137 Q361 82 340 57 Q328 45 321 75 L311 145Z"/>',
 'cat': '<path d="M112 148 L126 83 L178 129Z"/><path d="M400 148 L386 83 L334 129Z"/>',
 'dog': '<path d="M95 166 Q64 191 75 253 Q80 276 99 276 L126 212Z"/><path d="M417 166 Q448 191 437 253 Q432 276 413 276 L386 212Z"/>',
 'fox': '<path d="M110 145 L120 84 L173 131Z"/><path d="M402 145 L392 84 L339 131Z"/>',
 'raccoon': '<path d="M123 142 L133 91 L179 132Z"/><path d="M389 142 L379 91 L333 132Z"/>',
 'koala': '<circle cx="91" cy="181" r="41"/><circle cx="421" cy="181" r="41"/>',
 'panda': '<circle cx="121" cy="129" r="24"/><circle cx="391" cy="129" r="24"/>',
 'bear': '<circle cx="127" cy="124" r="27"/><circle cx="385" cy="124" r="27"/>',
 'lion': '<circle cx="129" cy="127" r="23"/><circle cx="383" cy="127" r="23"/>',
 'elephant': '<path d="M105 164 Q65 166 72 247 Q76 289 104 297 L135 247Z"/><path d="M407 164 Q447 166 440 247 Q436 289 408 297 L377 247Z"/>',
}
MARKS = {
 'mouse': '<ellipse cx="162" cy="267" rx="43" ry="23" fill="#edbec7" opacity=".52"/><ellipse cx="350" cy="267" rx="43" ry="23" fill="#edbec7" opacity=".52"/>',
 'hamster': '<path d="M81 263 Q107 194 163 200 Q187 242 178 321 Q123 351 85 309Z M431 263 Q405 194 349 200 Q325 242 334 321 Q389 351 427 309Z" fill="#fff1d9" opacity=".9"/>',
 'rabbit': '<ellipse cx="152" cy="284" rx="34" ry="19" fill="#f0b8c1" opacity=".5"/><ellipse cx="360" cy="284" rx="34" ry="19" fill="#f0b8c1" opacity=".5"/>',
 'cat': '<path d="M217 86 L228 147 M256 80 L256 143 M295 86 L284 147" fill="none" stroke="#b77b55" stroke-width="12" stroke-linecap="round" opacity=".7"/>',
 'dog': '<ellipse cx="174" cy="231" rx="54" ry="61" fill="#b78365" opacity=".55"/>',
 'fox': '<path d="M66 269 Q120 240 164 300 Q182 340 223 354 Q154 389 103 344Z M446 269 Q392 240 348 300 Q330 340 289 354 Q358 389 409 344Z" fill="#fff3dd"/>',
 'raccoon': '<path d="M105 216 Q154 180 208 208 Q208 271 160 281 Q115 277 105 216Z M407 216 Q358 180 304 208 Q304 271 352 281 Q397 277 407 216Z" fill="#71808a"/>',
 'koala': '<ellipse cx="166" cy="276" rx="32" ry="19" fill="#e8b4b1" opacity=".5"/><ellipse cx="346" cy="276" rx="32" ry="19" fill="#e8b4b1" opacity=".5"/>',
 'panda': '<ellipse cx="173" cy="231" rx="51" ry="60" transform="rotate(-17 173 231)" fill="#4a5658"/><ellipse cx="339" cy="231" rx="51" ry="60" transform="rotate(17 339 231)" fill="#4a5658"/>',
 'bear': '<ellipse cx="150" cy="280" rx="34" ry="19" fill="#e4afa5" opacity=".45"/><ellipse cx="362" cy="280" rx="34" ry="19" fill="#e4afa5" opacity=".45"/>',
 'lion': '<path d="M196 128 Q256 96 316 128" fill="none" stroke="#d49743" stroke-width="12" stroke-linecap="round"/>',
 'elephant': '<ellipse cx="154" cy="268" rx="28" ry="16" fill="#ebb7ba" opacity=".45"/><ellipse cx="358" cy="268" rx="28" ry="16" fill="#ebb7ba" opacity=".45"/>',
}
def generate(name, colors):
    hi, shade, ear, muzzle, mark = colors
    width = 256 if name in ('mouse','hamster','rabbit') else 512
    ear_fill = mark if name == 'panda' else shade if name in ('dog','raccoon','elephant') else hi
    # Mane is a scalloped round shape and remains inside the 256-radius disk.
    mane = '<circle cx="256" cy="256" r="246" fill="#b96d38" stroke="#553e39" stroke-width="8"/><circle cx="256" cy="256" r="234" fill="#d89142" stroke="#e3a450" stroke-width="8" stroke-dasharray="13 14"/>' if name == 'lion' else ''
    head_r = 183 if name == 'lion' else 210 if name in ('rabbit', 'dog', 'elephant') else 230
    head_y = 260 if name == 'lion' else 292 if name in ('rabbit', 'dog', 'elephant') else 272
    eyes = ('<ellipse cx="176" cy="234" rx="24" ry="33" fill="#fffaf0"/><ellipse cx="336" cy="234" rx="24" ry="33" fill="#fffaf0"/>' if name == 'panda' else '')
    eyes += '<ellipse cx="179" cy="234" rx="18" ry="24"/><ellipse cx="333" cy="234" rx="18" ry="24"/>'
    nose = '<ellipse cx="256" cy="277" rx="23" ry="31" fill="#5b6a70"/><path d="M256 304 Q256 329 270 328" fill="none" stroke="#553e39" stroke-width="7" stroke-linecap="round"/>' if name == 'koala' else '<path d="M238 277 Q256 267 274 277 Q270 292 256 296 Q242 292 238 277Z"/><path d="M256 296 Q256 313 242 318 M256 296 Q256 313 270 318" fill="none" stroke="#553e39" stroke-width="7" stroke-linecap="round"/>'
    if name == 'elephant':
        nose = '<path d="M233 268 Q224 299 230 342 Q234 370 257 370 Q281 369 288 352 L280 337 Q274 346 263 345 Q264 304 278 272Z" fill="#a9c4ca" stroke="#553e39" stroke-width="7"/><path d="M241 330 Q253 334 265 330 M241 344 Q251 348 263 345" fill="none" stroke="#789da7" stroke-width="5" stroke-linecap="round"/>'
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{width}" viewBox="0 0 512 512">
<defs><radialGradient id="fur" cx=".35" cy=".25" r=".8"><stop stop-color="{hi}"/><stop offset="1" stop-color="{shade}"/></radialGradient></defs>
<g stroke="{OUTLINE}" stroke-width="8" stroke-linejoin="round">{mane}<g fill="{ear_fill}">{EARS[name]}</g></g>
<g fill="{ear}" opacity=".8">{INNER[name]}</g>
<circle cx="256" cy="{head_y}" r="{head_r}" fill="url(#fur)" stroke="{OUTLINE}" stroke-width="8"/>
<ellipse cx="200" cy="164" rx="91" ry="41" fill="#ffffff" opacity=".12" transform="rotate(-16 200 164)"/>
{MARKS[name]}
<ellipse cx="256" cy="318" rx="85" ry="62" fill="{muzzle}" opacity=".88"/>
<g fill="{OUTLINE}">{eyes}{nose}</g>
<g fill="#fff"><circle cx="173" cy="226" r="6"/><circle cx="327" cy="226" r="6"/></g>
<path d="M148 383 Q256 420 364 383" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".16"/>
</svg>'''
    path=ROOT/name/'normal.svg'; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(svg+'\n', encoding='utf8')

if __name__ == '__main__':
    for name, colors in PALETTES.items(): generate(name, colors)
    print('Generated', len(PALETTES), 'project-specific vector animals')
