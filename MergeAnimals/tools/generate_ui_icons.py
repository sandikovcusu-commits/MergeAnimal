"""Generate original, editable SVG line icons. No third-party icon library used."""
from pathlib import Path
icons = {
'play':'<path d="M18 13L35 24 18 35Z"/>',
'play_light':'<path d="M18 13L35 24 18 35Z"/>',
'pause':'<path d="M17 14h5v20h-5zM27 14h5v20h-5z"/>',
'restart':'<path d="M12 24a12 12 0 1 0 4-9M11 13v8h8"/>',
'settings':'<circle cx="24" cy="24" r="6"/><path d="M24 8v5M24 35v5M8 24h5M35 24h5M13 13l4 4M31 31l4 4M35 13l-4 4M17 31l-4 4"/><circle cx="24" cy="24" r="12"/>',
'home':'<path d="M9 23L24 10l15 13M13 21v16h22V21M21 37V27h6v10"/>',
'collection':'<rect x="10" y="12" width="28" height="25" rx="3"/><path d="M10 20h28M19 12v25M28 20v17"/>',
'challenge':'<path d="M13 37l22-24M13 12l22 25M12 12l5 1-4 4zM35 12l1 5-4-4zM12 36l5-2-2 4zM36 36l-5-2 2 4z"/>',
'sound':'<path d="M10 19h7l8-7v24l-8-7h-7zM30 19q7 5 0 10M34 14q12 10 0 20"/>',
'music':'<path d="M21 33V13l13-3v20M21 17l13-3"/><ellipse cx="17" cy="33" rx="4" ry="3"/><ellipse cx="30" cy="30" rx="4" ry="3"/>',
'mute':'<path d="M8 19h7l8-7v24l-8-7H8zM29 19l9 10M38 19l-9 10"/>',
'undo':'<path d="M17 15l-8 8 8 8M10 23h15q12 0 12 11"/>',
'remove':'<path d="M13 17h22M18 17v-4h12v4M16 18l2 19h12l2-19M21 22v10M27 22v10"/>',
'rescue':'<path d="M24 9c8 8 11 13 11 18a11 11 0 0 1-22 0c0-5 3-10 11-18zM24 20v12M18 26h12"/>',
'trophy':'<path d="M17 11h14v10q0 9-7 9t-7-9zM17 15h-6q0 9 7 9M31 15h6q0 9-7 9M24 30v6M17 37h14"/>',
'star':'<path d="M24 9l4.5 9.4L39 20l-7.5 7.3 1.8 10.5L24 33l-9.3 4.8 1.8-10.5L9 20l10.5-1.6z"/>',
'lock':'<rect x="14" y="21" width="20" height="16" rx="3"/><path d="M18 21v-5a6 6 0 0 1 12 0v5M24 27v4"/>',
'check':'<path d="M10 25l9 9 19-20"/>',
'close':'<path d="M13 13l22 22M35 13L13 35"/>',
'back':'<path d="M27 12L15 24l12 12M16 24h22"/>',
'reward':'<path d="M11 20h26v18H11zM9 15h30v6H9zM24 15v23M24 15c-14 0-10-10-4-7 3 1 4 4 4 7zM24 15c14 0 10-10 4-7-3 1-4 4-4 7z"/>'}
out=Path(__file__).resolve().parents[1]/'assets/ui/icons'
out.mkdir(parents=True,exist_ok=True)
for name,body in icons.items():
    stroke = '#fff9e9' if name == 'play_light' else '#513c31'
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><g fill="none" stroke="{stroke}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'
    (out/f'{name}.svg').write_text(svg)
print('Generated',len(icons),'original SVGs')
