#!/usr/bin/env python3
"""Check declared asset bytes only; this does not establish origin or rights."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / 'ASSET_MANIFEST.json').read_text())
problems = []
entries = manifest['assets']
seen = set()
for entry in entries:
    name = entry['file']
    if name in seen:
        problems.append(f'duplicate: {name}')
    seen.add(name)
    target = (root / name).resolve()
    if not target.is_relative_to(root) or not target.is_file():
        problems.append(f'missing/outside project: {name}')
        continue
    expected = entry.get('sha256')
    if not expected or hashlib.sha256(target.read_bytes()).hexdigest() != expected:
        problems.append(f'SHA256 missing/mismatch: {name}')
if problems:
    raise SystemExit('\n'.join(problems))
print(f'PASS: {len(entries)} declared asset hashes match. Provenance and rights are not established by this check.')
