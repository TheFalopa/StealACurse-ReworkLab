"""Extract actual Studio-serialized templates, including native skinning data.

Never reconstruct a skinned MeshPart from MeshId + hand-created Bone objects.
Input must be a local XML place saved by Studio after native ApplyMesh/import.
"""
import copy, hashlib, json, sys
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1])
tree=ET.parse(source)
kit=next(item for item in tree.iter('Item') if item.get('class')=='Folder'
         and item.findtext('Properties/string[@name="Name"]')=='CurseMeshKit')
meshes=kit.findall('Item')
assert len(meshes)==56, f'Expected 56 templates, got {len(meshes)}'
ledger=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text(encoding='utf8'))
observed=[]
for mesh in meshes:
    name=mesh.findtext('Properties/string[@name="Name"]')
    assert mesh.get('class')=='MeshPart'
    assert mesh.findtext('Properties/bool[@name="HasSkinnedMesh"]')=='true', name
    asset=mesh.findtext('Properties/Content[@name="MeshId"]/url')
    assert asset==ledger[name]['meshId'], (name,asset,ledger[name]['meshId'])
    observed.append({'id':name,'meshId':asset,'hasSkinnedMesh':True,
                     'boneCount':sum(1 for b in mesh.iter('Item') if b.get('class')=='Bone')})
out=ET.Element('roblox',{'version':'4'})
ET.SubElement(out,'External').text='null';ET.SubElement(out,'External').text='nil'
out.append(copy.deepcopy(kit))
used={n.text for n in kit.iter('SharedString')}
shared=tree.getroot().find('SharedStrings')
if used:
    assert shared is not None
    dest=ET.SubElement(out,'SharedStrings')
    for s in shared:
        if s.get('md5') in used: dest.append(copy.deepcopy(s))
target=ROOT/'assets/imports/CurseMeshKit.rbxmx'
ET.indent(out)
ET.ElementTree(out).write(target,encoding='utf-8',xml_declaration=True)
project=ROOT/'default.project.json'
p=json.loads(project.read_text(encoding='utf8'))
p['tree']['ServerStorage']['CurseMeshKit']={'$path':'assets/imports/CurseMeshKit.rbxmx'}
project.write_text(json.dumps(p,indent=2)+'\n',encoding='utf8')
proof={'source':str(source),'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),
       'nativeTemplateFile':str(target),'nativeTemplateSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),
       'templates':observed,'note':'Actual Studio native skinning serialization, not proof of visual approval.'}
(ROOT/'assets/review/animations-polished/native-template-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf8')
print('PRESERVED_NATIVE_SKINNING',len(observed),target)
