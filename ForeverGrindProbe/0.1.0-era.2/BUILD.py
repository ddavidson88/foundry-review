"""Deterministic review/runtime packages; no game installation."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'dist'
VERSION='0.1.0-era.2'
def digest(data): return hashlib.sha256(data).hexdigest()
def pack(path,entries):
    with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,data in sorted(entries.items()):
            info=zipfile.ZipInfo(name,(2026,10,23,0,0,0)); info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=0o100644<<16; z.writestr(info,data)
def main():
    OUT.mkdir(exist_ok=True)
    runtime={p.relative_to(ROOT).as_posix():p.read_bytes() for p in sorted((ROOT/'ForeverGrindProbe').iterdir()) if p.is_file()}
    review=dict(runtime)
    for name in ('README.txt','PROVENANCE.txt','REVIEW.txt','BUILD.py','tests/test_grind.py'):
        review[name]=(ROOT/name).read_bytes()
    manifest={name:{'bytes':len(b),'sha256':digest(b)} for name,b in sorted(review.items())}
    review['MANIFEST.json']=(json.dumps(manifest,indent=2,sort_keys=True)+'\n').encode()
    for suffix,entries in [('RUNTIME',runtime),('REVIEW',review)]:
        path=OUT/f'ForeverGrindProbe-{VERSION}-{suffix}.zip'; pack(path,entries)
        print(path.name,path.stat().st_size,digest(path.read_bytes()))
if __name__=='__main__': main()
