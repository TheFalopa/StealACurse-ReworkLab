"""Preserve recoverable local source/native-asset/build checkpoints (no Git writes)."""
import hashlib, json, shutil, sys, zlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
label = sys.argv[1]
assert label and all(c.isalnum() or c == '-' for c in label)
out = ROOT / 'assets/review/sanctuary-restoration/checkpoints' / label
assert not out.exists(), out
out.mkdir(parents=True)
for folder in ['src', 'docs']:
    shutil.copytree(ROOT / folder, out / folder)
for relative in ['default.project.json', 'assets/imports/CurseMeshKit.rbxmx',
                 'assets/imports/curse-animation-current.json', 'build-curse-animations-polished.rbxlx',
                 'build-sanctuary-restoration-update.rbxlx',
                 'assets/review/sanctuary-restoration/studio-baseline-digests.json',
                 'assets/review/sanctuary-restoration/baseline-build-proof.json']:
    source = ROOT / relative
    if source.exists():
        target = out / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
proof_file = ROOT / 'assets/review/sanctuary-restoration/baseline-build-proof.json'
digest_file = ROOT / 'assets/review/sanctuary-restoration/studio-baseline-digests.json'
matches, mismatches = [], []
if label == '00-polished-start' and proof_file.exists() and digest_file.exists():
    proof, observed = json.loads(proof_file.read_text()), json.loads(digest_file.read_text())
    for row in proof['scripts']:
        data = (ROOT / row['source']).read_text(encoding='utf-8-sig').replace('\r\n', '\n').encode()
        actual = observed.get(row['path'].removeprefix('game.'))
        expected = {'length':len(data), 'adler32':zlib.adler32(data)}
        (matches if expected == actual else mismatches).append(row['source'])
    (out / 'studio-source-comparison.json').write_text(json.dumps({'matches':matches,'mismatches':mismatches},indent=2))
    print('STUDIO SOURCE COMPARISON', len(matches), 'matches', 'mismatches', mismatches)
rows = [{'path':p.relative_to(out).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in out.rglob('*') if p.is_file()]
(out / 'checkpoint.json').write_text(json.dumps({'label':label,'files':rows,'note':'Recoverable source/native asset/build checkpoint; not a test approval.'},indent=2))
print('CHECKPOINT',label,len(rows),'files')
