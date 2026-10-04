"""Integrate observed Studio imports. Never derive or guess asset IDs."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
evidence=ROOT/'assets/review/animations-polished'
observed=json.loads((evidence/'native-rig-repairs-10-observed.json').read_text())
batch=json.loads((evidence/'rig-repairs-import-batch.json').read_text())
assert {r['id']for r in observed}==set(batch['ids'])
sources={r['id']:r for r in batch['sources']}
ledgerPath=ROOT/'assets/imports/curse-animation-current.json'
ledger=json.loads(ledgerPath.read_text())
repairs={}
for file in ['creatures-rig-repairs.json','entities-rig-repairs.json','objects-rig-repairs.json']:
    for row in json.loads((evidence/file).read_text()):repairs[row['id']]=row
for row in observed:
    ident=row['id'];old=ledger[ident];fix=repairs[ident]
    assert row['hasSkinnedMesh'] is True and row['meshId'].startswith('rbxassetid://')
    assert max(abs(a-b)for a,b in zip(row['size'],old['targetSize']))<.01,(ident,row['size'],old['targetSize'])
    assert len(row['nativeBones'])==len(old['bones']),ident
    old['previousAnimationMeshId']=old['meshId']
    old['blend']=sources[ident]['blend'];old['blendSHA256']=sources[ident]['blendSHA256']
    old['fbx']=batch['fbx'];old['fbxSHA256']=batch['sha256']
    old['individualFBX']=fix['fbx'];old['individualFBXSHA256']=fix['fbxSHA256']
    old['meshId']=row['meshId'];old['observedSize']=row['size'];old['nativeBones']=row['nativeBones']
    old['observationFile']='assets/review/animations-polished/native-rig-repairs-10-observed.json'
    old['realImportRecorded']=True;old['hasSkinnedMesh']=True;old['playReviewed']=False
    if 'vertices' in fix:old['vertices']=fix['vertices']
ledgerPath.write_text(json.dumps(ledger,indent=2)+'\n',encoding='utf8')
lines=['-- Real native skinned assets. Visual review is tracked separately.','return {']
for ident,row in sorted(ledger.items()):
    lines.append('\t'+ident+'={meshId="'+row['meshId']+'",fbxSha256="'+row['fbxSHA256']+'",boneCount='+str(len(row['nativeBones']))+' },')
lines.append('}')
(ROOT/'src/shared/CurseAnimationAssets.luau').write_text('\n'.join(lines)+'\n',encoding='utf8')
print('INTEGRATED_REAL_REPAIRS',len(observed))
