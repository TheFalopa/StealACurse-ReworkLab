import bpy,json
from pathlib import Path
root=Path('C:/RobloxProjects/StealACurse')
rows=[]
for ident in ['music_box_dancer','thorn_reliquary']:
    source=root/'assets/source/blender/curse_animation'/f'{ident}.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    record={'id':ident,'source':str(source),'meshes':[]}
    for obj in bpy.data.objects:
        if obj.type!='MESH':continue
        groups=[]
        for group in obj.vertex_groups:
            verts=[v for v in obj.data.vertices if any(g.group==group.index and g.weight>.5 for g in v.groups)]
            if verts:
                lo=[min(v.co[a] for v in verts) for a in range(3)]
                hi=[max(v.co[a] for v in verts) for a in range(3)]
                groups.append({'name':group.name,'vertices':len(verts),'minimum':lo,'maximum':hi})
        record['meshes'].append({'name':obj.name,'groups':groups,'materials':[m.name for m in obj.data.materials]})
    rows.append(record)
out=root/'assets/review/animations-polished/user-two-curses/weights.json'
out.write_text(json.dumps(rows,indent=2))
print('TWO_CURSE_WEIGHTS',out)
