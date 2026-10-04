"""Integrate only real native importer observations. Preserve all old records."""
import json,re,sys,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def array(x):return [x[str(i)]for i in range(1,len(x)+1)]if isinstance(x,dict)else x
observation=ROOT/sys.argv[1]
raw=json.loads(observation.read_text(encoding='utf8'))
objects=json.loads(next(c['text']for c in raw['content']if c['type']=='text'))
project=json.loads((ROOT/'default.project.json').read_text(encoding='utf8'))
sculpts=[]
for file in (ROOT/'assets/source/blender/curse_animation').glob('*rigs.json'):
    sculpts.extend(json.loads(file.read_text(encoding='utf8')))
sourceById={r['id']:r for r in sculpts}
ledgerPath=ROOT/'assets/imports/curse-animation-current.json'
ledger=json.loads(ledgerPath.read_text(encoding='utf8'))if ledgerPath.exists()else {}
for record in array(objects):
    id=record['name']
    if id not in sourceById or not record['bones']:continue
    assert re.fullmatch(r'rbxassetid://[0-9]+',record['id'])
    size=array(record['size']);bones=array(record['bones']);src=sourceById[id]
    assert len(bones)==len(src['bones']),f'{id}: missing native bones'
    node=project['tree']['ServerStorage']['CurseMeshKit'][id]
    node['$properties']['MeshId']=record['id'];node['$properties']['InitialSize']=size;node['$properties']['Size']=size
    nodes={b['name']:{'$className':'Bone','$properties':{'CFrame':array(b['cframe'])}}for b in bones}
    for b in bones:
        parent=nodes[b['parent']]if b['parent']in nodes else node
        parent[b['name']]=nodes[b['name']]
    ledger[id]={**src,'meshId':record['id'],'observedSize':size,'nativeBones':bones,'realImportRecorded':True,
        'observationFile':observation.relative_to(ROOT).as_posix(),'playReviewed':False}
    if len(sys.argv)>2:
        batch=ROOT/sys.argv[2]
        ledger[id]['individualFBX']=ledger[id]['fbx']
        ledger[id]['individualFBXSHA256']=ledger[id]['fbxSHA256']
        ledger[id]['fbx']=batch.relative_to(ROOT).as_posix()
        ledger[id]['fbxSHA256']=hashlib.sha256(batch.read_bytes()).hexdigest()
    print('INTEGRATED_REAL_RIG',id,record['id'],len(bones))
(ROOT/'default.project.json').write_text(json.dumps(project,indent=2),encoding='utf8')
ledgerPath.write_text(json.dumps(ledger,indent=2),encoding='utf8')
assets=['-- Actual native skinned mesh IDs. Imports do not imply completed Play review.','return {']
for id,r in sorted(ledger.items()):
    assets.append(f'\t{id}={{meshId="{r["meshId"]}",fbxSha256="{r["fbxSHA256"]}",boneCount={len(r["nativeBones"])} }},')
assets.append('}')
(ROOT/'src/shared/CurseAnimationAssets.luau').write_text('\n'.join(assets)+'\n',encoding='utf8')
