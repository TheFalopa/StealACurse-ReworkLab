"""Small recoverable checkpoints for integrated animation batches."""
import hashlib,json,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
label=sys.argv[1]
assert label and all(c.isalnum()or c=='-' for c in label)
out=ROOT/'assets/review/animations-polished/checkpoints'/label
assert not out.exists(),out
out.mkdir(parents=True)
shutil.copytree(ROOT/'src',out/'src')
for relative in ['default.project.json','assets/imports/CurseMeshKit.rbxmx','assets/imports/curse-animation-current.json','build-curse-animations-polished.rbxlx','assets/review/animations-polished/gallery-observed.json']:
    path=ROOT/relative
    if path.exists():
        target=out/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
rows=[{'path':str(p.relative_to(out)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in out.rglob('*')if p.is_file()]
(out/'checkpoint.json').write_text(json.dumps({'label':label,'files':rows,'note':'Saved source/build/evidence checkpoint; not a visual approval.'},indent=2))
print('CHECKPOINT',label,len(rows),'files')
