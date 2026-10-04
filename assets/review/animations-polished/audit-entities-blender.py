"""Read-only audit of the 17 entity rigs. Does not save Blender sources."""
import bpy, json
from pathlib import Path

ROOT = Path(r'C:\RobloxProjects\StealACurse')
IDS = 'veil_mourner umbrella_wraith sundial_sentinel blood_moon_rose night_harp judgement_scales cathedral_heart hollow_throne nameless_door silent_choir the_first_grave the_last_funeral the_last_star crown_of_silence the_undertow the_unwritten worldroot'.split()
rows = []
for curse_id in IDS:
    path = ROOT / 'assets/source/blender/curse_animation' / (curse_id + '.blend')
    bpy.ops.wm.open_mainfile(filepath=str(path))
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    groups = {g.index:g.name for g in mesh.vertex_groups}
    weight_bounds = {}
    for vertex in mesh.data.vertices:
        for weight in vertex.groups:
            if weight.weight < 0.15:
                continue
            name = groups[weight.group]
            entry = weight_bounds.setdefault(name, {'count':0, 'min':[1e9]*3, 'max':[-1e9]*3})
            entry['count'] += 1
            for axis in range(3):
                entry['min'][axis] = min(entry['min'][axis], vertex.co[axis])
                entry['max'][axis] = max(entry['max'][axis], vertex.co[axis])
    rows.append({'id':curse_id,'mesh':mesh.name,'rig':rig.name,'modifiers':[(m.type,m.object.name if m.type=='ARMATURE' and m.object else None) for m in mesh.modifiers],
        'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(b.head_local),'tail':list(b.tail_local),'weighted':weight_bounds.get(b.name)} for b in rig.data.bones]})
out = ROOT / 'assets/review/animations-polished/entities-blender-audit.json'
out.write_text(json.dumps(rows, indent=2), encoding='utf-8')
print('READ_ONLY_AUDIT', len(rows), str(out))
