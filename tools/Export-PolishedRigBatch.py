"""Export the ten audited rig repairs in a single native import transaction.

No asset IDs are assigned here. Source objects, geometry and rest bones are
loaded as authored; namespacing affects only this combined FBX.
"""
import bpy, hashlib, json
from pathlib import Path
ROOT = Path(r'C:\RobloxProjects\StealACurse')
IDS = 'thimble_spider anchor_crab nail_beetle phantom_marionette wilted_sprout cold_teacup thorn_reliquary silent_choir night_harp the_last_funeral'.split()
audit = []
for ident in 'cursed_doll watching_eye soul_chains plague_monarch the_void'.split():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/source/blender/curse_animation'/f'{ident}.blend'))
    obj=next(x for x in bpy.data.objects if x.type=='MESH')
    arm=next(x for x in bpy.data.objects if x.type=='ARMATURE')
    row={'id':ident,'bones':[]}
    for b in arm.data.bones:
        vg=obj.vertex_groups.get(b.name);pts=[]
        if vg:
            for v in obj.data.vertices:
                if any(w.group==vg.index and w.weight>.05 for w in v.groups):pts.append(obj.matrix_world@v.co)
        row['bones'].append({'name':b.name,'parent':b.parent.name if b.parent else None,
            'head':list(arm.matrix_world@b.head_local),'tail':list(arm.matrix_world@b.tail_local),
            'vertices':len(pts),'bounds':{'min':[min(p[k] for p in pts)for k in range(3)],'max':[max(p[k]for p in pts)for k in range(3)]}if pts else None})
    audit.append(row)
(ROOT/'assets/review/animations-polished/core-rig-audit.json').write_text(json.dumps(audit,indent=2))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
sources=[]
for ident in IDS:
    base=ROOT/'assets/source/blender/animations-polished'/f'{ident}.blend'
    if not base.exists():base=ROOT/'assets/source/blender/curse_animation'/f'{ident}.blend'
    with bpy.data.libraries.load(str(base),link=False)as(src,dst):
        dst.objects=[n for n in src.objects if n in (ident,ident+'_Rig')]
    for obj in dst.objects:
        bpy.context.collection.objects.link(obj)
    mesh=next(o for o in dst.objects if o.type=='MESH')
    arm=next(o for o in dst.objects if o.type=='ARMATURE')
    for vg in mesh.vertex_groups:vg.name=ident+'__'+vg.name
    for b in arm.data.bones:b.name=ident+'__'+b.name
    sources.append({'id':ident,'blend':base.relative_to(ROOT).as_posix(),'blendSHA256':hashlib.sha256(base.read_bytes()).hexdigest()})
arms=[x for x in bpy.context.scene.objects if x.type=='ARMATURE']
bpy.ops.object.select_all(action='DESELECT')
for arm in arms:arm.select_set(True)
common=arms[0];bpy.context.view_layer.objects.active=common;bpy.ops.object.join()
for mesh in bpy.context.scene.objects:
    if mesh.type=='MESH':
        world=mesh.matrix_world.copy();mesh.parent=common;mesh.matrix_world=world
        for mod in mesh.modifiers:
            if mod.type=='ARMATURE':mod.object=common
bpy.ops.object.select_all(action='SELECT')
out=ROOT/'assets/export/meshes/curses/animations-polished/polished-rig-repairs-10.fbx'
bpy.ops.export_scene.fbx(filepath=str(out),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
    object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,colors_type='SRGB')
manifest={'sources':sources,'ids':IDS,'fbx':out.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}
(ROOT/'assets/review/animations-polished/rig-repairs-import-batch.json').write_text(json.dumps(manifest,indent=2))
print('REAL_FBXS_EXPORTED',str(out),flush=True)
