"""Verify the repaired blends retain exact geometry and rest skeletons."""
import bpy, json
from pathlib import Path
ROOT = Path(r'C:\RobloxProjects\StealACurse')
OUT = ROOT / 'assets/review/animations-polished'
def snapshot(path, id):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    mesh = bpy.data.objects[id]
    arm = next(mod.object for mod in mesh.modifiers if mod.type == 'ARMATURE')
    return dict(vertices=[list(vertex.co) for vertex in mesh.data.vertices],
        polygons=[list(poly.vertices) for poly in mesh.data.polygons],
        materials=[(material.name, list(material.diffuse_color)) for material in mesh.data.materials],
        uvs={layer.name: [list(loop.uv) for loop in layer.data] for layer in mesh.data.uv_layers},
        colors={attr.name: [(list(element.color)) for element in attr.data] for attr in mesh.data.color_attributes},
        rest={bone.name: dict(parent=bone.parent.name if bone.parent else None,
              matrix=[list(row) for row in bone.matrix_local]) for bone in arm.data.bones},
        badWeightSums=[vertex.index for vertex in mesh.data.vertices
                     if abs(sum(group.weight for group in vertex.groups) - 1) > 0.0001])
results = []
for id in ['wilted_sprout', 'cold_teacup', 'thorn_reliquary']:
    original = snapshot(OUT / 'objects-rigs-before' / (id + '.blend'), id)
    current = snapshot(ROOT / 'assets/source/blender/curse_animation' / (id + '.blend'), id)
    checks = {key: original[key] == current[key] for key in ['vertices', 'polygons', 'materials', 'uvs', 'colors', 'rest']}
    assert all(checks.values()), (id, checks)
    assert not current['badWeightSums']
    results.append(dict(id=id, exactUnchanged=checks, badWeightSums=0, nativePlayReviewed=False))
    print('RIG_REPAIR_VERIFIED', id, checks, flush=True)
(OUT / 'objects-rig-repairs-verified.json').write_text(json.dumps(results, indent=2), encoding='utf8')
