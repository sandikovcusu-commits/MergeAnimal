"""Audit a Godot 4.7 V4 unencrypted PCK; CI-only, never included in Web build."""
import collections, pathlib, struct, sys
p=pathlib.Path(sys.argv[1])
with p.open('rb') as f:
    magic,version,major,minor,patch,flags,base,directory=struct.unpack('<6IQQ',f.read(40))
    assert magic==0x43504447 and version==4 and not flags & 1, 'unexpected/encrypted pack'
    f.seek(directory); count=struct.unpack('<I',f.read(4))[0]; entries={}
    for _ in range(count):
        length=struct.unpack('<I',f.read(4))[0]
        name=f.read(length).rstrip(b'\0').decode('utf-8')
        offset,size=struct.unpack('<QQ',f.read(16)); f.read(20); entries[name]=size
forbidden=['tests/','art_source/','art_reports/','concepts/','.github/','probe.gdc','mock','benchmark_', 'asset_manifest.json','.mp4','.webm','.csv','.md']
bad=[name for name in entries if any(x in name.lower() for x in forbidden)]
counts={'animals':sum(n.startswith('resources/animals/') and n.endswith('.tres') for n in entries),
        'challenges':sum(n.startswith('resources/challenges/') and n.endswith('.tres') for n in entries),
        'achievements':sum(n.startswith('resources/achievements/') and n.endswith('.tres') for n in entries),
        'themes':sum(n.startswith('assets/ui/themes/') and n.endswith('.tres') for n in entries),
        'sfx':sum(n.startswith('assets/audio/sfx/') and n.endswith('.wav.import') for n in entries),
        'music':sum(n.startswith('assets/audio/music/') and n.endswith('.wav.import') for n in entries),
        'languages':sum(n in entries for n in ('translations/en.json','translations/az.json','translations/tr.json','translations/ru.json'))}
expected={'animals':12,'challenges':20,'achievements':15,'themes':3,'sfx':20,'music':3,'languages':4}
print('PCK_AUDIT',p, 'entries',count,'counts',counts,'forbidden',bad)
if bad or counts != expected: raise SystemExit('PCK_AUDIT FAILED')
