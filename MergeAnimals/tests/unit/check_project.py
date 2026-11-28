"""Static resource path and prototype contract checks; not a Godot execution test."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[2]
errors = []
files = [p for p in root.rglob('*') if p.is_file() and p.suffix in {'.tscn', '.tres', '.gd', '.godot'} and '.godot' not in p.parts]
for file in files:
    for path in re.findall(r'res://[^"\s]+', file.read_text(encoding='utf-8')):
        if '%' not in path and not (root / path.removeprefix('res://')).is_file():
            errors.append(f'{file.relative_to(root)}: missing {path}')
project = (root / 'project.godot').read_text()
for expected in ('gl_compatibility', 'scenes/ui/MainMenu.tscn', 'viewport_width=720', 'viewport_height=1280'):
    if expected not in project:
        errors.append(f'project.godot missing {expected}')
for animal in ('mouse', 'hamster', 'rabbit'):
    text = (root / f'resources/animals/{animal}.tres').read_text()
    for expected in ('radius = ', 'body_mass = ', 'unlock_id = '):
        if expected not in text:
            errors.append(f'{animal}.tres missing {expected}')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'PASS: {len(files)} project text files scanned; resource paths and basic configuration verified.')
