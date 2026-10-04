"""Revisions driven by actual 22-stud Studio Play captures; preserve first exports."""
import bpy, sys, json, hashlib, math
from pathlib import Path
from mathutils import Vector
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))
import author_batch01 as batch
SOURCE = HERE / 'revision02'
EXPORT = ROOT / 'assets/export/meshes/curses/visual-pass2/revision02'
SOURCE.mkdir(exist_ok=True); EXPORT.mkdir(exist_ok=True)
rows=[]
for id in ('cold_teacup', 'coin_crawler'):
    old = json.loads((HERE/(id+'_metrics.json')).read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(HERE/(id+'.blend')))
    obj=bpy.data.objects[id]
    obj.location=(0,0,0)
    factors=Vector((1,1,1))
    if id=='cold_teacup':
        paint=obj.data.color_attributes['SACPaintedColor']
        steam=next(p for p in old['semanticParts'] if p['name']=='CurledShadowSteam')
        for polygon in obj.data.polygons[steam['first_face']:steam['last_face_exclusive']]:
            # Charcoal steam retains dark volume, with cool sculpted faces readable at night.
            edge=max(0, polygon.normal.x*.65-polygon.normal.y*.35)
            color=(.13+edge*.13,.18+edge*.14,.23+edge*.15,1)
            for loop in polygon.loop_indices: paint.data[loop].color_srgb=color
        note='Actual Studio capture exposed black-on-night steam: charcoal faces now have restrained cool edge contrast.'
    else:
        bpy.context.view_layer.update()
        dims=obj.dimensions.copy()
        factors=Vector((5.8/dims.x,4.1/dims.y,3.2/dims.z))
        for vertex in obj.data.vertices: vertex.co*=factors
        note='Actual Studio capture exposed uniform-runtime shrinkage: baked low, broad 5.8 x 3.2 x 4.1-stud crawler proportions.'
    obj.data.update(); bpy.context.view_layer.update()
    dims=list(obj.dimensions)
    hook=Vector((old['vfxHook'][0],-old['vfxHook'][2],old['vfxHook'][1]))*factors
    row={**old,'revision':2,'previousFbxSha256':old['sha256'],
         'source':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
         'blendSource':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
         'export':str((EXPORT/(id+'.fbx')).relative_to(ROOT)).replace('\\','/'),
         'blenderDimensions':dims,'intendedRobloxSize':[dims[0],dims[2],dims[1]],
         'robloxIntendedSize':[dims[0],dims[2],dims[1]],
         'vfxHook':[hook.x,hook.z,-hook.y],'vfxHookRoblox':[hook.x,hook.z,-hook.y],
         'diagonal':math.sqrt(sum(v*v for v in dims)),
         'localValidation':batch.geo.check_mesh(obj),
         'designNotes':old['designNotes']+[note],
         'realImportRecorded':False,'appearanceChecked':False,'gameplayChecked':False}
    obj['VFXHook_Blender']=list(hook)
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.fbx(filepath=str(ROOT/row['export']),use_selection=True,global_scale=.01,
                            apply_unit_scale=True,object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
    row['sha256']=hashlib.sha256((ROOT/row['export']).read_bytes()).hexdigest()
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/row['source']))
    row['roundtripValidation']=batch.geo.validate_asset(row)
    (SOURCE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
    rows.append(row)
    print('PASS2_REVISION_READY',id,row['intendedRobloxSize'],flush=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
for index,row in enumerate(rows):
    with bpy.data.libraries.load(str(ROOT/row['source']),link=False) as (a,b): b.objects=[row['id']]
    obj=b.objects[0]; bpy.context.collection.objects.link(obj); obj.location=(index*16,0,0)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=str(EXPORT/'batch01-revision02.fbx'),use_selection=True,global_scale=.01,
                        apply_unit_scale=True,object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
(SOURCE/'revision02-local-geometry.json').write_text(json.dumps({'assets':rows,'studioImportPending':True},indent=2)+'\n',encoding='utf-8')
print('PASS2_REVISION_DONE',len(rows),flush=True)
