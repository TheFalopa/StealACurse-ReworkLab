"""Read-only Blender rig and weighted-volume audit for the creature acting group."""
import bpy, json
from pathlib import Path
from mathutils import Vector

ROOT=Path(r'C:\RobloxProjects\StealACurse')
IDS='grave_hopper hourglass_hound nail_beetle coin_crawler marrow_dice thimble_spider anchor_crab music_box_dancer hollow_violin sleepwalker_shoes phantom_marionette clockwork_raven eclipse_stag thorn_cathedral sunken_crown endless_library'.split()
ledger=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())
results=[]
for ident in IDS:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/ledger[ident]['blend']))
    mesh=next(x for x in bpy.data.objects if x.type=='MESH')
    rig=next(x for x in bpy.data.objects if x.type=='ARMATURE')
    row={'id':ident,'size':ledger[ident]['observedSize'],'meshObject':mesh.name,'armature':rig.name,'bones':[]}
    for b in rig.data.bones:
        group=mesh.vertex_groups.get(b.name)
        pts=[]; weights=[]
        if group:
            for v in mesh.data.vertices:
                for w in v.groups:
                    if w.group==group.index and w.weight>.001:
                        pts.append(mesh.matrix_world@v.co);weights.append(w.weight)
        bounds=None
        if pts:
            bounds={'min':[min(p[i] for p in pts) for i in range(3)],'max':[max(p[i] for p in pts) for i in range(3)]}
        row['bones'].append({'name':b.name.split('__')[-1], 'parent':b.parent.name.split('__')[-1] if b.parent else None,'head':list(rig.matrix_world@b.head_local),'tail':list(rig.matrix_world@b.tail_local),'worldRotation':list((rig.matrix_world@b.matrix_local).to_quaternion()),'localRotation':list(b.matrix_local.to_quaternion()),'weightedVertices':len(pts),'bounds':bounds})
    results.append(row)
    print('AUDIT',ident,'bones',len(row['bones']),'weighted',sum(b['weightedVertices'] for b in row['bones']),flush=True)
(ROOT/'assets/review/animations-polished/creatures-rig-audit.json').write_text(json.dumps(results,indent=2))
