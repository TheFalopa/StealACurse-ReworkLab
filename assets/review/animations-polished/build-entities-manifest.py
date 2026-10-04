"""Gather factual source/bone/import metadata for the root coordinator."""
import json, re, hashlib
from pathlib import Path
ROOT=Path(r'C:\RobloxProjects\StealACurse')
module=ROOT/'src/client/CurseActsEntities.luau'
ids=re.findall(r'function acts\.([a-z_]+)\(',module.read_text())
assert len(ids)==len(set(ids))==17
rigs={r['id']:r for r in json.loads((ROOT/'assets/source/blender/curse_animation/remaining-rigs.json').read_text())}
ledger=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())
repairs={r['id']:r for r in json.loads((ROOT/'assets/review/animations-polished/entities-rig-repairs.json').read_text())}
rows=[]
for identity in ids:
    r=rigs[identity];current=ledger[identity];repair=repairs.get(identity)
    rows.append({'id':identity,'module':'src/client/CurseActsEntities.luau','moduleSHA256':hashlib.sha256(module.read_bytes()).hexdigest(),'blend':r['blend'],'bones':r['bones'],'weightedCounts':repair['weightedCounts'] if repair else r['weightedCounts'],'oldRecordedRealMeshId':current['meshId'],'fbxPrepared':repair['fbx'] if repair else r['fbx'],'fbxSHA256':repair['fbxSHA256'] if repair else r['fbxSHA256'],'rigRepairNeeded':bool(repair),'currentSourceReimportPending':bool(repair),'statesImplemented':['PROCESSION','CARRYING','DELIVERING','PLACED','UNPLACED'],'pickupPlacementReactions':'concept bone reactions via stateAge; coordinated gaits use real path distance','boneNamesChanged':False,'boneHierarchyChanged':False,'VFXAnchorsChanged':False,'status':'AUTHORED_PENDING_ROOT_INTEGRATED_PLAY_REVIEW'})
(ROOT/'assets/review/animations-polished/entities-acting-manifest.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print('ENTITY_MANIFEST',len(rows),'REAL_IMPORTS_PENDING',sum(r['currentSourceReimportPending']for r in rows))
