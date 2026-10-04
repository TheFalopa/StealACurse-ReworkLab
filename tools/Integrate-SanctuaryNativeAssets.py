"""Preserve Studio's real skinning serialization and observed import identifiers."""
import copy, hashlib, json, sys
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
evidence=ROOT/'assets/review/sanctuary-restoration/visuals'
source=Path(sys.argv[1])
tree=ET.parse(source)
kit=next(i for i in tree.iter('Item') if i.get('class')=='Folder' and i.findtext('Properties/string[@name="Name"]')=='CurseMeshKit')
observed=json.loads((evidence/'native-remodel-observed.json').read_text())
batch=json.loads((evidence/'source-production-batch.json').read_text())
ledgerPath=ROOT/'assets/imports/curse-animation-current.json'
ledger=json.loads(ledgerPath.read_text())
assert {r['id'] for r in observed}=={r['id'] for r in batch['assets']}
proof=[]
for mesh in kit.findall('Item'):
    ident=mesh.findtext('Properties/string[@name="Name"]')
    asset=mesh.findtext('Properties/Content[@name="MeshId"]/url')
    assert mesh.get('class')=='MeshPart' and mesh.findtext('Properties/bool[@name="HasSkinnedMesh"]')=='true',ident
    imported=next((r for r in observed if r['id']==ident),None)
    expected=imported['meshId'] if imported else ledger[ident]['meshId']
    assert asset==expected,(ident,asset,expected)
    proof.append({'id':ident,'meshId':asset,'hasSkinnedMesh':True,'boneCount':sum(i.get('class')=='Bone' for i in mesh.iter('Item'))})
assert len(proof)==56
for row in observed:
    ident=row['id'];old=ledger[ident];prod=next(r for r in batch['assets'] if r['id']==ident)
    assert max(abs(a-b) for a,b in zip(row['size'],old['targetSize']))<.01
    assert len(row['nativeBones'])==len(old['nativeBones'])
    old['previousRestorationMeshId']=old['meshId']
    old.update(meshId=row['meshId'],observedSize=row['size'],nativeBones=row['nativeBones'],blend=prod['after']['source'],blendSHA256=prod['after']['sourceSHA256'],fbx=batch['batch'],fbxSHA256=batch['batchSHA256'],vertices=prod['after']['vertices'],triangles=prod['after']['triangles'],observationFile='assets/review/sanctuary-restoration/visuals/native-remodel-observed.json',realImportRecorded=True,hasSkinnedMesh=True,playReviewed=False)
    individual=ROOT/'assets/export/meshes/curses/sanctuary-restoration'/f'{ident}.fbx'
    old['individualFBX']=individual.relative_to(ROOT).as_posix();old['individualFBXSHA256']=hashlib.sha256(individual.read_bytes()).hexdigest()
out=ET.Element('roblox',{'version':'4'})
ET.SubElement(out,'External').text='null';ET.SubElement(out,'External').text='nil';out.append(copy.deepcopy(kit))
used={s.text for s in kit.iter('SharedString')};nativeShared=tree.getroot().find('SharedStrings')
if used:
    assert nativeShared is not None
    dest=ET.SubElement(out,'SharedStrings')
    for s in nativeShared:
        if s.get('md5') in used:dest.append(copy.deepcopy(s))
    assert {s.get('md5') for s in dest}==used
target=ROOT/'assets/imports/CurseMeshKit.rbxmx'
ET.indent(out);ET.ElementTree(out).write(target,encoding='utf-8',xml_declaration=True)
ledgerPath.write_text(json.dumps(ledger,indent=2)+'\n',encoding='utf8')
lines=['-- Actual native skinned imports; visual verification is tracked separately.','return {']
for ident,row in sorted(ledger.items()):
    lines.append('\t'+ident+'={meshId="'+row['meshId']+'",fbxSha256="'+row['fbxSHA256']+'",boneCount='+str(len(row['nativeBones']))+' },')
lines.append('}')
(ROOT/'src/shared/CurseAnimationAssets.luau').write_text('\n'.join(lines)+'\n',encoding='utf8')
(evidence/'native-template-proof.json').write_text(json.dumps({'source':str(source),'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'nativeTemplateFile':str(target),'nativeTemplateSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),'templates':proof,'note':'Native skinning serialization; Play review is separate.'},indent=2)+'\n')
print('PRESERVED',len(proof),'native templates; INTEGRATED',len(observed),'observed imports')
