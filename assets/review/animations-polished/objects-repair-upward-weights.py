"""Fix three upward chains whose previous helper assigned lower/upper weights backwards.

Geometry, materials, UVs, joint names, rest matrices and attachments are untouched.
This exports real FBX files; it neither imports nor assigns Roblox asset IDs.
"""
import bpy, hashlib, json, shutil
from pathlib import Path

ROOT = Path(r'C:\RobloxProjects\StealACurse')
OUT = ROOT / 'assets/review/animations-polished'
EXPORT = ROOT / 'assets/export/meshes/curses/animations-polished'
EXPORT.mkdir(parents=True, exist_ok=True)
BACKUP = OUT / 'objects-rigs-before'
BACKUP.mkdir(parents=True, exist_ok=True)
records = []
for id, first, second in [('wilted_sprout', 'Root', 'Stem'),
                          ('cold_teacup', 'Steam', 'SteamTip'),
                          ('thorn_reliquary', 'Thorn', 'ThornTip')]:
    source = ROOT / 'assets/source/blender/curse_animation' / (id + '.blend')
    backup = BACKUP / (id + '.blend')
    # Always restore the original snapshot before swapping; reruns are idempotent.
    if not backup.exists():
        shutil.copy2(source, backup)
    bpy.ops.wm.open_mainfile(filepath=str(backup))
    mesh = bpy.data.objects[id]
    arm = next(mod.object for mod in mesh.modifiers if mod.type == 'ARMATURE')
    a = mesh.vertex_groups[first]
    b = mesh.vertex_groups[second]
    weights = []
    for vertex in mesh.data.vertices:
        groups = {group.group: group.weight for group in vertex.groups}
        weights.append((groups.get(a.index, 0), groups.get(b.index, 0)))
    a.remove(range(len(mesh.data.vertices)))
    b.remove(range(len(mesh.data.vertices)))
    changed = 0
    for index, (wa, wb) in enumerate(weights):
        if wb > 0:
            a.add([index], wb, 'REPLACE')
        if wa > 0:
            b.add([index], wa, 'REPLACE')
        if abs(wa - wb) > 0.0001:
            changed += 1
    invalid = [vertex.index for vertex in mesh.data.vertices
               if abs(sum(group.weight for group in vertex.groups) - 1) > 0.0001]
    assert not invalid, invalid
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    fbx = EXPORT / (id + '.fbx')
    bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True,
        global_scale=.01, apply_unit_scale=True, bake_space_transform=False,
        object_types={'MESH', 'ARMATURE'}, add_leaf_bones=False,
        armature_nodetype='NULL', use_armature_deform_only=True,
        bake_anim=False, use_mesh_modifiers=True, colors_type='SRGB')
    record = dict(id=id, swap=[first, second], changedVertices=changed,
        source=source.relative_to(ROOT).as_posix(),
        original=backup.relative_to(ROOT).as_posix(),
        beforeSHA256=hashlib.sha256(backup.read_bytes()).hexdigest(),
        afterSHA256=hashlib.sha256(source.read_bytes()).hexdigest(),
        fbx=fbx.relative_to(ROOT).as_posix(),
        fbxSHA256=hashlib.sha256(fbx.read_bytes()).hexdigest(),
        geometryChanged=False, restBonesChanged=False,
        nativeImportPending=True, assetId=None)
    records.append(record)
    print('UPWARD_CHAIN_REPAIRED', id, changed, fbx, flush=True)
(OUT / 'objects-rig-repairs.json').write_text(json.dumps(records, indent=2), encoding='utf8')
