"""Aggregate existing authored rigs for one native importer transaction.
Individual editable .blend/FBX files remain authoritative and recoverable.
"""
import bpy,json,sys,hashlib
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def main():
    args=sys.argv[sys.argv.index('--')+1:];label=args[0];ids=args[1:]
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for i,id in enumerate(ids):
        with bpy.data.libraries.load(str(HERE/(id+'.blend')),link=False)as(src,dst):
            dst.objects=[name for name in src.objects if name in (id,id+'_Rig')]
        for obj in dst.objects:
            bpy.context.collection.objects.link(obj)
        arm=bpy.data.objects[id+'_Rig'];obj=bpy.data.objects[id]
        # FBX bone identifiers must be unique across armatures in a batch.
        # Keep the individual sources unchanged; namespacing is export-only.
        for group in obj.vertex_groups:group.name=id+'__'+group.name
        for bone in arm.data.bones:bone.name=id+'__'+bone.name
        arm.location.x=0
    # Roblox's importer supports one deforming skeleton per FBX model. Join
    # the namespaced armatures while preserving each mesh's world transform.
    arms=[x for x in bpy.context.scene.objects if x.type=='ARMATURE']
    bpy.ops.object.select_all(action='DESELECT')
    for arm in arms:arm.select_set(True)
    common=arms[0];bpy.context.view_layer.objects.active=common
    bpy.ops.object.join()
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            world=obj.matrix_world.copy();obj.parent=common;obj.matrix_world=world
            for mod in obj.modifiers:
                if mod.type=='ARMATURE':mod.object=common
    bpy.ops.object.select_all(action='SELECT')
    path=ROOT/'assets/export/meshes/curses/animations'/f'{label}.fbx'
    bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
        object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,colors_type='SRGB')
    (HERE/(label+'-import-batch.json')).write_text(json.dumps({'ids':ids,'fbx':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()},indent=2),encoding='utf8')
    print('NATIVE_IMPORT_BATCH',path,ids,flush=True)
if __name__=='__main__':main()
