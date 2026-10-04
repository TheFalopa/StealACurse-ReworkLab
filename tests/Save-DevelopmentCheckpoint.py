"""Preserve local recoverable source/build checkpoints without changing Git."""
import hashlib, json, shutil, sys
from datetime import datetime, timezone
from pathlib import Path
root=Path(__file__).resolve().parents[1]
label=sys.argv[1]
assert label.replace('-','').isalnum()
target=root/'assets/review/management-animations/checkpoints'/label
assert not target.exists(), 'Checkpoint already exists; choose a new label'
files=list((root/'src').rglob('*'))+[root/'default.project.json',root/'build-curse-visual-pass2.rbxlx']
files += list(root.glob('build-curse-management-*.rbxlx'))
files += list((root/'tests').glob('Management*')) + list((root/'tests/Unit').rglob('*'))
files += list((root/'tools').glob('*LocalProfile*'))
files += [root/'tests/Build-ManagementFixture.py',root/'tests/Save-DevelopmentCheckpoint.py']
files += list((root/'tests').glob('*Animation*'))+list((root/'tools').glob('*CurseRig*'))
files += list((root/'tests').glob('*RecoveryQueue*'))+list((root/'tests').glob('*Pavement*'))
files += list((root/'tests').glob('*Motion*'))+list((root/'tests').glob('*Performance*'))
files += list((root/'assets/source/blender/curse_animation').glob('*'))
files += list((root/'assets/export/meshes/curses/animations').glob('*.fbx'))
files += list((root/'assets/imports').glob('curse-animation*.json'))
files += [root/'docs/CURSE_MANAGEMENT_ANIMATIONS.md']
files += list((root/'assets/review/management-animations').glob('final-*.json'))
hashes={}
for file in files:
    if not file.is_file(): continue
    relative=file.relative_to(root)
    output=target/relative
    output.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(file,output)
    hashes[relative.as_posix()]=hashlib.sha256(output.read_bytes()).hexdigest()
(target/'checkpoint.json').write_text(json.dumps({'utc':datetime.now(timezone.utc).isoformat(),'label':label,'files':hashes},indent=2),encoding='utf8')
print(json.dumps({'checkpoint':str(target),'files':len(hashes)}))
