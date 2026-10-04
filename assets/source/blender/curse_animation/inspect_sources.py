"""Read the 56 current editable sculpts; record connected volumes for rigging.
This does not alter old sources or claim native Roblox imports.
"""
import bpy,csv,json,hashlib,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
def sources():
    rows=list(csv.DictReader((ROOT/'docs/CURSE_VISUAL_PASS2_MEASURES.csv').open(encoding='utf-8-sig')))
    for row in rows:
        source=ROOT/row['blend']
        if source.suffix!='.blend': source=ROOT/'assets/source/blender/curses_expansion/rework'/f"{row['id']}.blend"
        assert source.is_file(),str(source)
        row['actualBlend']=source.relative_to(ROOT).as_posix()
    return rows
def components(mesh):
    parent=list(range(len(mesh.vertices)))
    def find(i):
        while parent[i]!=i: parent[i]=parent[parent[i]];i=parent[i]
        return i
    for edge in mesh.edges:
        a,b=map(find,edge.vertices);parent[b]=a
    groups={}
    for v in mesh.vertices:groups.setdefault(find(v.index),[]).append(v.index)
    return list(groups.values())
def main():
    result=[]
    for row in sources():
        bpy.ops.wm.open_mainfile(filepath=str(ROOT/row['actualBlend']))
        obj=bpy.data.objects.get(row['id']);assert obj and obj.type=='MESH'
        groups=components(obj.data)
        lo=Vector([min(v.co[i] for v in obj.data.vertices)for i in range(3)])
        hi=Vector([max(v.co[i] for v in obj.data.vertices)for i in range(3)])
        detail=[]
        for ids in groups:
            points=[obj.data.vertices[i].co for i in ids]
            a=Vector([min(v[i]for v in points)for i in range(3)])
            b=Vector([max(v[i]for v in points)for i in range(3)])
            center=(a+b)/2
            detail.append({'vertices':len(ids),'min':list(a),'max':list(b),'center':list(center),
                'normalizedCenter':[(center[i]-lo[i])/(hi[i]-lo[i])for i in range(3)]})
        result.append({**row,'sourceSHA256':hashlib.sha256((ROOT/row['actualBlend']).read_bytes()).hexdigest(),
            'sourceMin':list(lo),'sourceMax':list(hi),'vertices':len(obj.data.vertices),
            'triangles':len(obj.data.polygons),'components':detail})
        print('INSPECTED',row['id'],len(groups),flush=True)
    (OUT/'current-sculpt-components-56.json').write_text(json.dumps(result,indent=2),encoding='utf8')
if __name__=='__main__':main()
