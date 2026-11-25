"""Local WIP asset audit; requires Pillow. Geometry checks are not artistic approval."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
NAMES = ['mouse','hamster','rabbit','cat','dog','fox','raccoon','koala','panda','bear','lion','elephant']
out = ROOT / 'art_reports'; out.mkdir(exist_ok=True)
font = ImageFont.load_default()
results = []
for name in NAMES:
    path = ROOT / 'assets' / 'animals' / name / 'normal.png'
    if not path.exists():
        results.append({'id': name, 'status': 'missing'}); continue
    im = Image.open(path); a = im.getchannel('A'); p = a.load(); w,h = im.size
    total = outside = 0
    for y in range(h):
        for x in range(w):
            if p[x,y] > 32:
                total += 1
                outside += (x - (w-1)/2)**2 + (y-(h-1)/2)**2 > (min(w,h)/2)**2
    edge = max([p[x,0] for x in range(w)] + [p[x,h-1] for x in range(w)] + [p[0,y] for y in range(h)] + [p[w-1,y] for y in range(h)])
    results.append({'id':name,'path':str(path.relative_to(ROOT)), 'format':im.format,'mode':im.mode,'size':[w,h], 'bbox':a.getbbox(), 'alpha_minmax':a.getextrema(), 'edge_alpha_max':edge, 'opaque_outside_collision_percent':round(100*outside/max(total,1),2), 'status':'WIP_NOT_COMMERCIALLY_CLEARED'})
(out/'audit.json').write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
for mode in ['white','black','collision']:
    cell=230; title=25
    sheet=Image.new('RGB',(cell*4,(cell+title)*3), '#eee8dc' if mode!='black' else '#252525')
    draw=ImageDraw.Draw(sheet)
    for i,name in enumerate(NAMES):
        x=(i%4)*cell; y=(i//4)*(cell+title)
        draw.rectangle((x,y,x+cell-1,y+cell-1), fill=('#ffffff' if mode=='white' else '#151515' if mode=='black' else '#f3ead7'))
        path=ROOT/'assets'/'animals'/name/'normal.png'
        if path.exists():
            im=Image.open(path).convert('RGBA').resize((200,200),Image.Resampling.LANCZOS)
            sheet.paste(im,(x+15,y+15),im)
            if mode=='collision':
                draw.ellipse((x+15,y+15,x+215,y+215),outline='#00a9dd',width=2)
        else:
            draw.text((x+65,y+105),'MISSING',fill='#e05a4d',font=font)
        draw.text((x+10,y+cell+4), name.upper() + (' (missing)' if not path.exists() else ''), fill=('#fff' if mode=='black' else '#40342f'),font=font)
    sheet.save(out / ('contact_'+mode+'_WIP.png'))
print(json.dumps(results, indent=2))
