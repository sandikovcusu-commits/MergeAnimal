#!/usr/bin/env python3
"""Reproducibility and static content audit; not legal clearance.
Needs @resvg/resvg-js 2.6.2 on NODE_PATH and fonttools 4.69.1.
"""
import hashlib, os, pathlib, shutil, subprocess, tempfile, xml.etree.ElementTree as ET
R = pathlib.Path(__file__).resolve().parents[2]
NAMES = ['mouse','hamster','rabbit','cat','dog','fox','raccoon','koala','panda','bear','lion','elephant']

def same(a, b):
    if a.read_bytes() != b.read_bytes():
        raise AssertionError(f'nonidentical regeneration: {a.relative_to(R)}')

def run(*args):
    subprocess.run(args, check=True, stdout=subprocess.PIPE)

with tempfile.TemporaryDirectory(prefix='asset-repro-') as tmp:
    t = pathlib.Path(tmp)
    (t/'tools').mkdir(); (t/'assets/fonts').mkdir(parents=True)
    for name in ['generate_animal_vectors.py','render_animal_vectors.cjs','generate_expression_vectors.py','render_expression_vectors.cjs','generate_ui_icons.py','generate_audio.py','generate_logo.py','generate_button_themes.py']:
        shutil.copy2(R/'tools'/name,t/'tools'/name)
    shutil.copy2(R/'assets/fonts/DejaVuSans.ttf',t/'assets/fonts/DejaVuSans.ttf')
    run('python3',str(t/'tools/generate_animal_vectors.py'))
    svg_count = 0
    for name in NAMES:
        svg = R/'art_source/vector_animals'/name/'normal.svg'
        same(svg, t/'art_source/vector_animals'/name/'normal.svg')
        document = ET.parse(svg)
        for element in document.iter():
            tag = element.tag.rsplit('}',1)[-1].lower()
            assert tag not in ('image','script','foreignobject','use','style'), (svg,tag)
            for key,value in element.attrib.items():
                key=key.rsplit('}',1)[-1].lower(); value=value.lower().strip()
                assert key not in ('href','src') and 'data:' not in value and 'http:' not in value and 'https:' not in value, (svg,key,value)
                if 'url(' in value: assert value.startswith('url(#') and value.endswith(')'), (svg,value)
        (t/'assets/animals'/name).mkdir(parents=True)
        svg_count += 1
    run('node',str(t/'tools/render_animal_vectors.cjs'))
    for name in NAMES:
        same(R/'assets/animals'/name/'normal.png',t/'assets/animals'/name/'normal.png')
    run('python3',str(t/'tools/generate_expression_vectors.py'))
    run('node',str(t/'tools/render_expression_vectors.cjs'))
    for name in NAMES:
        for frame in ('blink','happy','surprise'):
            svg = R/'art_source/vector_animals'/name/(frame+'.svg')
            same(svg,t/'art_source/vector_animals'/name/(frame+'.svg'))
            same(R/'assets/animals'/name/(frame+'.png'),t/'assets/animals'/name/(frame+'.png'))
            for element in ET.parse(svg).iter():
                tag=element.tag.rsplit('}',1)[-1].lower()
                assert tag not in ('image','script','foreignobject','use','style'),(svg,tag)
                for key,value in element.attrib.items():
                    key=key.rsplit('}',1)[-1].lower();value=value.lower().strip()
                    assert key not in ('href','src') and not any(v in value for v in ('data:','http:','https:')),(svg,key,value)
                    if 'url(' in value: assert value.startswith('url(#') and value.endswith(')'),(svg,value)
    run('python3',str(t/'tools/generate_ui_icons.py'))
    icons = sorted((R/'assets/ui/icons').glob('*.svg')); assert len(icons)==20
    for icon in icons: same(icon,t/'assets/ui/icons'/icon.name)
    for svg in list((R/'assets/ui/icons').glob('*.svg')) + list((R/'assets/backgrounds').glob('*.svg')) + [R/'assets/ui/logo/wild_garden.svg']:
        document = ET.parse(svg)
        for e in document.iter():
            assert e.tag.rsplit('}',1)[-1].lower() not in ('image','script','foreignobject','use','style'), svg
            for k,v in e.attrib.items():
                assert k.rsplit('}',1)[-1].lower() not in ('href','src') and not any(x in v.lower() for x in ('data:','http:','https:')), svg
                if 'url(' in v: assert v.strip().startswith('url(#') and v.strip().endswith(')'), svg
    run('python3',str(t/'tools/generate_button_themes.py'))
    for theme in (R/'assets/ui/themes').glob('*.tres'):
        generated=(t/'assets/ui/themes'/theme.name).read_text()
        if theme.stem in ('forest','snow','sunset'):
            generated=generated.replace('load_steps=6','load_steps=7',1).replace('\n\n[sub_resource', '\n\n[ext_resource type=\"FontFile\" path=\"res://assets/fonts/DejaVuSans.ttf\" id=\"ui_font\"]\n\n[sub_resource',1).replace('[resource]\n','[resource]\ndefault_font = ExtResource(\"ui_font\")\n',1)
        assert theme.read_text()==generated,theme
    run('python3',str(t/'tools/generate_audio.py'))
    sound = sorted((R/'assets/audio').rglob('*.wav')); assert len(sound)==23
    for wav in sound: same(wav,t/wav.relative_to(R))
    (t/'assets/ui/logo').mkdir(parents=True)
    run('python3',str(t/'tools/generate_logo.py'))
    same(R/'assets/ui/logo/wild_garden.svg',t/'assets/ui/logo/wild_garden.svg')
    print(f'PASS: {svg_count} SVG, 12 PNG, 36 expression SVG/PNG, 20 icons, 8 themes (including font edits), 23 WAV and logo reproduced; runtime SVGs contain no external link/image/script/use element')
    print('LIMIT: this establishes inputs and deterministic output only, not AI training provenance, character similarity, copyright, or commercial rights')
