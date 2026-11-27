#!/usr/bin/env python3
"""Package committed project and an uninstrumented CI export; TEST ONLY, not rights clearance.
Usage: python tools/package_commercial_test.py COMMIT CI_WEB_EVIDENCE.zip OUTPUT_DIR
Build clean source, Web test ZIP and a release-assets directory. Then run
../tests/commercial/audit_packages.py with these outputs and the V0.8.3 PCK.
"""
import io, pathlib, subprocess, sys, tarfile, zipfile, shutil
if len(sys.argv)!=4: raise SystemExit(__doc__)
commit,evidence,out=sys.argv[1:]; out=pathlib.Path(out).resolve();out.mkdir(parents=True,exist_ok=True)
project=pathlib.Path(__file__).resolve().parents[1]
repo=project.parent
archive=subprocess.check_output(['git','archive',commit,'MergeAnimals'],cwd=repo)
assets=out/'release-assets';shutil.rmtree(assets,ignore_errors=True);assets.mkdir()
source=out/'MergeAnimals-V0.9.0.1.1-Godot.zip'; web=out/'MergeAnimals-V0.9.0.1.1-Web-Test.zip'
committed={}
with tarfile.open(fileobj=io.BytesIO(archive),mode='r:') as tar, zipfile.ZipFile(source,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for m in tar:
  if not m.isfile(): continue
  name=m.name
  if name.startswith(('MergeAnimals/art_reports/','MergeAnimals/concepts/')):continue
  if '..' in pathlib.PurePosixPath(name).parts:raise ValueError(name)
  content=tar.extractfile(m).read();committed[name]=content;z.writestr(name,content)
  prefix='MergeAnimals/assets/'
  if name.startswith(prefix):
   dest=assets/name[len(prefix):];dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(content)
with zipfile.ZipFile(evidence) as original, zipfile.ZipFile(web,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 allowed={'index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'}
 seen=set()
 for info in original.infolist():
  if info.filename.startswith('web/') and len(pathlib.PurePosixPath(info.filename).parts)==2 and not info.is_dir():
   name=info.filename[4:]
   if name not in allowed or name in seen:raise ValueError('unexpected/duplicate Web file '+name)
   z.writestr(name,original.read(info));seen.add(name)
 if seen!=allowed:raise ValueError('missing Web files: '+str(allowed-seen))
 prefix='MergeAnimals/third_party_notices/'
 for name,content in sorted(committed.items()):
  if name.startswith(prefix) and name.endswith('.txt'):z.writestr('notices/'+name[len(prefix):],content)
 for notice in ('THIRD_PARTY_NOTICES.md','COMMERCIAL_RIGHTS_REPORT.md','LICENSE_EVIDENCE.md'):z.writestr('notices/'+notice,committed['MergeAnimals/'+notice])
 z.writestr('notices/TEST_ONLY.txt','V0.9.0.1.1 TEST ONLY — COMMERCIAL RELEASE BLOCKED. No ads in this standard Web export. Applicable Arena output rights and written consent are not established. See LICENSE_EVIDENCE.md and COMMERCIAL_RIGHTS_REPORT.md.\n')
(assets/'notices').mkdir()
for name,content in committed.items():
 prefix='MergeAnimals/third_party_notices/'
 if name.startswith(prefix) and name.endswith('.txt'):
  (assets/'notices'/name[len(prefix):]).write_bytes(content)
for name in ('THIRD_PARTY_NOTICES.md','COMMERCIAL_RIGHTS_REPORT.md','LICENSE_EVIDENCE.md'):
 (assets/'notices'/name).write_bytes(committed['MergeAnimals/'+name])
(assets/'TEST_ONLY.txt').write_text('TEST ONLY — NOT CLEARED FOR COMMERCIAL DISTRIBUTION. See notices/COMMERCIAL_RIGHTS_REPORT.md and LICENSE_EVIDENCE.md.\n')
print('Packaged',source,web,'and',assets)
