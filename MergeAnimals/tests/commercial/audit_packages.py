#!/usr/bin/env python3
"""Compare delivery outputs with known old visual hashes and baseline imported textures.
Run only after building the two zips and populating release-assets/; see audit report.
"""
import hashlib,json,pathlib,struct,sys,zipfile
R=pathlib.Path(__file__).resolve().parents[2]
if len(sys.argv)!=5: raise SystemExit('usage: audit_packages.py source.zip web.zip release-assets baseline.pck')
source,web,assets,baseline=map(pathlib.Path,sys.argv[1:])
def digest(x): return hashlib.sha256(x).hexdigest()
old=json.loads((R/'docs/asset_audit/legacy_visual_sha256.json').read_text())['visuals']
hashes={x['sha256'] for x in old}; problems=[]
def inspect(label,files):
 count=0
 for name,content in files:
  count+=1
  if digest(content) in hashes: problems.append(f'{label}: historical visual exact match {name}')
 print(label,'files',count)
def zipfiles(z):
 for info in z.infolist():
  if not info.is_dir(): yield info.filename,z.read(info)
with zipfile.ZipFile(source) as z:
 assert z.testzip() is None
 inspect('source zip',zipfiles(z))
 assert not any(n.startswith(('MergeAnimals/concepts/', 'MergeAnimals/art_reports/')) for n in z.namelist()), 'historical directories in clean source'
 assert len([n for n in z.namelist() if n.startswith('MergeAnimals/assets/animals/') and n.endswith('/normal.png')])==12
with zipfile.ZipFile(web) as z:
 assert z.testzip() is None
 inspect('web zip',zipfiles(z))
 pack=z.read('index.pck')
 assert any(n.endswith('DEJAVU-UPSTREAM-LICENSE.txt') for n in z.namelist()),'full font license not included'
 assert any(n.endswith('GODOT-COPYRIGHT.txt') for n in z.namelist()),'engine component notices not included'
inspect('release assets',((str(p.relative_to(assets)),p.read_bytes()) for p in assets.rglob('*') if p.is_file()))
assert len(list((assets/'animals').glob('*/normal.png')))==12

def pck(data):
 magic,version,major,minor,patch,flags,base,directory=struct.unpack_from('<6IQQ',data)
 assert magic==0x43504447 and version==4 and not flags&1
 count,=struct.unpack_from('<I',data,directory); pos=directory+4;result={}
 for i in range(count):
  length,=struct.unpack_from('<I',data,pos);pos+=4
  name=data[pos:pos+length].rstrip(b'\0').decode();pos+=length
  off,size=struct.unpack_from('<QQ',data,pos);pos+=16
  checksum=data[pos:pos+16];pos+=16
  entry_flags,=struct.unpack_from('<I',data,pos);pos+=4
  assert not entry_flags & 1
  content=data[base+off:base+off+size]
  assert len(content)==size and hashlib.md5(content).digest()==checksum,(name,'bad PCK content checksum')
  result[name]=content
 return result
prior=pck(baseline.read_bytes());current=pck(pack)
old_tex={n:digest(b) for n,b in prior.items() if n.startswith('.godot/imported/normal.png-') and n.endswith('.ctex')}
new_tex={n:digest(b) for n,b in current.items() if n.startswith('.godot/imported/normal.png-') and n.endswith('.ctex')}
assert len(old_tex)==len(new_tex)==12 and old_tex.keys()==new_tex.keys(), 'animal import set mismatch'
for name,sha in old_tex.items():
 if new_tex[name]==sha:problems.append(f'PCK unchanged historical texture {name}')
oldctex=set(old_tex.values());
for n,b in current.items():
 if digest(b) in oldctex or digest(b) in hashes:problems.append(f'PCK historical payload {n}')
for n in current:
 if any(x in n.lower() for x in ('art_source/','art_reports/','concepts/','tests/','mock','probe.gdc')): problems.append(f'PCK forbidden {n}')
print('PCK',len(current),'entries; all 12 baseline imported animal textures differ; no exact historical visual or texture hashes')
if problems: raise SystemExit('\n'.join(problems))
print('PASS package audit — exact known hashes only; altered/unknown derivatives and legal rights not established')
