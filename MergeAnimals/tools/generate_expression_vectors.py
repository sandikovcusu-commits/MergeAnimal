#!/usr/bin/env python3
"""Derive editable facial expression SVGs from our own V0.9.0.1 vector artwork.
No external image/model input. Normal geometry stays untouched; blink changes
only the eyes, while happy/surprise adjust eyes and the existing mouth.
Run before render_expression_vectors.cjs; see ASSET_LICENSES.md.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'art_source' / 'vector_animals'
open_eyes = '<ellipse cx="179" cy="234" rx="18" ry="24"/><ellipse cx="333" cy="234" rx="18" ry="24"/>'
highlights = '<g fill="#fff"><circle cx="173" cy="226" r="6"/><circle cx="327" cy="226" r="6"/></g>'
mouth = '<path d="M256 296 Q256 313 242 318 M256 296 Q256 313 270 318" fill="none" stroke="#553e39" stroke-width="7" stroke-linecap="round"/>'
eye_variants = {
    'blink': '<path d="M160 235 Q179 248 198 235 M314 235 Q333 248 352 235" fill="none" stroke="#553e39" stroke-width="9" stroke-linecap="round"/>',
    'happy': '<path d="M159 240 Q179 215 199 240 M313 240 Q333 215 353 240" fill="none" stroke="#553e39" stroke-width="10" stroke-linecap="round"/>',
    'surprise': '<ellipse cx="179" cy="232" rx="20" ry="29"/><ellipse cx="333" cy="232" rx="20" ry="29"/>',
}
for directory in sorted(p for p in root.iterdir() if p.is_dir()):
    normal = (directory / 'normal.svg').read_text()
    assert normal.count(open_eyes) == 1 and normal.count(highlights) == 1, directory
    for name, eyes in eye_variants.items():
        result = normal.replace(open_eyes, eyes)
        if name != 'surprise': result = result.replace(highlights, '')
        if name == 'happy':
            if mouth in result:
                result = result.replace(mouth, '<path d="M236 310 Q256 338 276 310" fill="none" stroke="#553e39" stroke-width="8" stroke-linecap="round"/>')
            elif directory.name == 'koala':
                result = result.replace('M256 304 Q256 329 270 328', 'M239 314 Q256 338 273 314')
            elif directory.name == 'elephant':
                result = result.replace('</svg>', '<path d="M206 307 Q210 319 221 323 M291 323 Q302 319 306 307" fill="none" stroke="#553e39" stroke-width="6" stroke-linecap="round"/></svg>')
        if name == 'surprise':
            if mouth in result:
                result = result.replace(mouth, '<ellipse cx="256" cy="321" rx="11" ry="15" fill="#553e39"/>')
            elif directory.name == 'koala':
                result = result.replace('<path d="M256 304 Q256 329 270 328" fill="none" stroke="#553e39" stroke-width="7" stroke-linecap="round"/>', '<ellipse cx="256" cy="325" rx="10" ry="13" fill="#553e39"/>')
            elif directory.name == 'elephant':
                result = result.replace('</svg>', '<ellipse cx="205" cy="306" rx="8" ry="11" fill="#553e39"/><ellipse cx="307" cy="306" rx="8" ry="11" fill="#553e39"/></svg>')
        (directory / f'{name}.svg').write_text(result)
