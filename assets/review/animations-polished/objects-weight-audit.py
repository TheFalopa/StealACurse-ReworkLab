"""Inspect, never alter, the eighteen object rigs assigned to this agent."""
import bpy, json
from pathlib import Path

ROOT = Path(r'C:\RobloxProjects\StealACurse')
IDS = ('haunted_mirror crying_mask candle_wisp grave_key mourning_ribbon '
       'wilted_sprout ink_imp lost_locket ashen_book lantern_lurker pale_guest '
       'cold_teacup grave_compass pale_gramophone raven_quill sorrow_chalice '
       'thorn_reliquary chime_triplets').split()
rows = []
for id in IDS:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'assets/source/blender/curse_animation' / (id + '.blend')))
    mesh = bpy.data.objects[id]
    arm = next(mod.object for mod in mesh.modifiers if mod.type == 'ARMATURE')
    weights = {}
    bad = []
    for vertex in mesh.data.vertices:
        total = sum(group.weight for group in vertex.groups)
        if abs(total - 1) > 0.0001:
            bad.append([vertex.index, total])
        for group in vertex.groups:
            if group.weight < 0.01:
                continue
            weights.setdefault(mesh.vertex_groups[group.group].name, []).append(vertex.co.copy())
    bones = []
    for bone in arm.data.bones:
        points = weights.get(bone.name, [])
        bones.append(dict(name=bone.name, parent=bone.parent.name if bone.parent else None,
            head=list(bone.head_local), tail=list(bone.tail_local),
            vertices=len(points), weightedMin=[min(point[i] for point in points) for i in range(3)] if points else None,
            weightedMax=[max(point[i] for point in points) for i in range(3)] if points else None))
    parent = list(range(len(mesh.data.vertices)))
    def find(index):
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index
    for edge in mesh.data.edges:
        a, b = map(find, edge.vertices)
        parent[b] = a
    components = {}
    for vertex in mesh.data.vertices:
        components.setdefault(find(vertex.index), []).append(vertex)
    component_rows = []
    for vertices in components.values():
        group_weight = {}
        for vertex in vertices:
            for group in vertex.groups:
                name = mesh.vertex_groups[group.group].name
                group_weight[name] = group_weight.get(name, 0) + group.weight
        component_rows.append(dict(vertices=len(vertices), groups=group_weight,
            min=[min(vertex.co[i] for vertex in vertices) for i in range(3)],
            max=[max(vertex.co[i] for vertex in vertices) for i in range(3)]))
    rows.append(dict(id=id, vertices=len(mesh.data.vertices), badWeightSums=bad, bones=bones, components=component_rows))
    print('OBJECT_WEIGHT_AUDIT', id, len(bones), 'invalid=', len(bad), flush=True)
(ROOT / 'assets/review/animations-polished/objects-weight-audit.json').write_text(json.dumps(rows, indent=2), encoding='utf8')
