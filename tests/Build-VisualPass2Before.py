"""Comparable before fixture: frozen production sources, original saved place.
Only the two presentation fixtures are added. No gameplay approval is implied.
"""
from pathlib import Path
import hashlib,json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
FROZEN=ROOT/'assets/review/curse-pass2/baseline/frozen'
source_place=ROOT/'build-curse-expansion-50.rbxlx'
tree=ET.parse(source_place)
root=tree.getroot()
def name(item):
    prop=item.find("Properties/string[@name='Name']")
    return prop.text if prop is not None else ''
def child(item, wanted):
    found=[x for x in item.findall('Item') if name(x)==wanted]
    if len(found)!=1: raise ValueError(f'Expected one {wanted}, found {len(found)}')
    return found[0]
frozen_paths={
 'src__shared__CurseCatalog.luau':['ReplicatedStorage','Shared','CurseCatalog'],
 'src__shared__CurseExpansionAssets.luau':['ReplicatedStorage','Shared','CurseExpansionAssets'],
 'src__shared__CurseVFXProfiles.luau':['ReplicatedStorage','Shared','CurseVFXProfiles'],
 'src__server__Gameplay__CurseVisualService.luau':['ServerScriptService','Server','Gameplay','CurseVisualService'],
 'src__server__Gameplay__CurseService.luau':['ServerScriptService','Server','Gameplay','CurseService'],
 'src__client__CurseVFX.luau':['StarterPlayer','StarterPlayerScripts','Client','CurseVFX'],
 'src__client__UI__CurseLabels.luau':['StarterPlayer','StarterPlayerScripts','Client','UI','CurseLabels'],
}
proof={'scope':'Frozen before sources plus presentation-only QA; all original imported mesh IDs retained','sourcePlace':'build-curse-expansion-50.rbxlx','sourcePlaceSha256':hashlib.sha256(source_place.read_bytes()).hexdigest(),'sourceFingerprints':{}}
for file,path in frozen_paths.items():
    item=root
    for node in path: item=child(item,node)
    source=item.find("Properties/*[@name='Source']")
    if source is None: raise ValueError(f'Missing source: {path}')
    content=(FROZEN/file).read_text(encoding='utf-8-sig')
    source.text=content
    proof['sourceFingerprints'][str((FROZEN/file).relative_to(ROOT)).replace('\\','/')]=hashlib.sha256((FROZEN/file).read_bytes()).hexdigest()
def add_script(parent,cls,title,file):
    item=ET.SubElement(parent,'Item',{'class':cls,'referent':'PASS2_BEFORE_'+title})
    props=ET.SubElement(item,'Properties')
    ET.SubElement(props,'string',{'name':'Name'}).text=title
    ET.SubElement(props,'bool',{'name':'Disabled'}).text='false'
    ET.SubElement(props,'ProtectedString',{'name':'Source'}).text=(ROOT/file).read_text(encoding='utf-8-sig')
    proof['sourceFingerprints'][file]=hashlib.sha256((ROOT/file).read_bytes()).hexdigest()
add_script(child(root,'ServerScriptService'),'Script','Pass2Audit','tests/VisualPass2Audit.server.luau')
add_script(child(child(root,'StarterPlayer'),'StarterPlayerScripts'),'LocalScript','Pass2AuditCamera','tests/VisualPass2Audit.client.luau')
target=ROOT/'build-curse-pass2-before-compare.rbxlx'
tree.write(target,encoding='utf-8',xml_declaration=True)
proof['artifact']=target.name
proof['artifactSha256']=hashlib.sha256(target.read_bytes()).hexdigest()
(ROOT/'build-curse-pass2-before-compare.proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print('Before comparison fixture saved; 7 frozen sources and original imported meshes retained.')
