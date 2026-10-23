#!/usr/bin/env python3
"""Build exact review/runtime ZIPs with Python 3 standard library only.

Run from any directory: python BUILD.py [output-directory]
Stored ZIP members, fixed UTC timestamps, sorted paths and explicit permissions
make output independent of zlib version and host file metadata.
"""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parent
NAME = 'ForeverLaunchGuide-0.1.0-era.1'
FILES = [
    'BUILD.py', 'README.md', 'REVIEW.md', 'SOURCES.md', 'CHANGELOG-DRAFT.md',
    'ForeverLaunchGuide/ForeverLaunchGuide.toc', 'ForeverLaunchGuide/Guide.lua',
    'tests/README.md', 'tests/requirements.txt', 'tests/test_rxp_parser.py',
    'tests/upstream/LICENSE', 'tests/upstream/PROVENANCE.json',
    'tests/upstream/parser-excerpts.lua',
]

def sha(data):
    return hashlib.sha256(data).hexdigest()

def make_zip(path, entries):
    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_STORED) as z:
        for name, data in sorted(entries.items()):
            info = zipfile.ZipInfo(name, (2026, 10, 23, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_STORED
            z.writestr(info, data)
    data = path.read_bytes()
    assert len(data) < 9_000_000, 'Review transport size limit exceeded'
    return {'name': path.name, 'bytes': len(data), 'sha256': sha(data),
            'members': len(entries)}

def build(output):
    output.mkdir(parents=True, exist_ok=True)
    source = {name: (ROOT / name).read_bytes() for name in FILES}
    runtime = {n: b for n, b in source.items() if n.startswith('ForeverLaunchGuide/')}
    manifest = ''.join(f'{sha(data)}  {name}\n' for name, data in sorted(source.items())).encode()
    review = dict(source, **{'MANIFEST.sha256': manifest})
    result = {'runtime': make_zip(output / (NAME + '.zip'), runtime),
              'review': make_zip(output / (NAME + '-REVIEW.zip'), review)}
    (output / (NAME + '-identity.json')).write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    build(Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / 'dist')
