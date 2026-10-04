"""Combine the actual frozen individual FBXs without joining or inventing IDs.

Imports each real single-asset export, applies its FBX transform, restores the
authored stud scale by100, then exports the21 distinct objects at0.01. An
actual reimport checks each component against its own individual FBX evidence.
This does not edit or re-export any individual FBX.
"""
from pathlib import Path
import sys, json, hashlib, math
import bpy
from mathutils import Vector, Matrix
sys.dont_write_bytecode=True
SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[4]
sys.path.insert(0,str(SOURCE))
from rework_geometry import reset, check_mesh

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def color_set(obj):
    col=obj.data.color_attributes.get('SACPaintedColor')
    if col is None: raise RuntimeError(obj.name+' missing color')
    return {tuple(round(float(c)*255) for c in item.color_srgb) for item in col.data}

def bounds(obj):
    b=[obj.matrix_world@Vector(p) for p in obj.bound_box]
    lo=[min(v[a] for v in b) for a in range(3)]; hi=[max(v[a] for v in b) for a in range(3)]
    return ([h-l for h,l in zip(hi,lo)],[(h+l)*.5 for h,l in zip(hi,lo)])

def main():
    rows=json.loads((SOURCE/'high_geometry.json').read_text(encoding='utf-8'))['assets']
    if len(rows)!=21 or len({r['id'] for r in rows})!=21: raise RuntimeError('Need exactly21 unique high rarity models')
    reset(); meshes=[]; expected={}
    for row in rows:
        path=ROOT/row['export']
        if digest(path)!=row['sha256']: raise RuntimeError(row['id']+' individual export changed')
        previous=set(bpy.context.scene.objects)
        bpy.ops.import_scene.fbx(filepath=str(path))
        created=[o for o in bpy.context.scene.objects if o not in previous and o.type=='MESH']
        if len(created)!=1 or created[0].name!=row['id']: raise RuntimeError('Individual root mismatch')
        obj=created[0]; dims,center=bounds(obj)
        if any(abs(a-b*.01)>1e-6 for a,b in zip(dims,row['blenderDimensions'])): raise RuntimeError('Individual imported dimensions differ')
        colors=color_set(obj)
        expected[row['id']]={'row':row,'dimensions':dims,'colors':colors,'triangles':len(obj.data.polygons)}
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        obj.data.transform(Matrix.Scale(100,4)); obj.data.update(); obj.location=(0,0,0)
        meshes.append(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes: obj.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    batch=ROOT/'assets/export/meshes/curses/rework/high_import_batch.fbx'
    bpy.ops.export_scene.fbx(filepath=str(batch),use_selection=True,global_scale=.01,apply_unit_scale=True,
                            bake_space_transform=False,object_types={'MESH'},add_leaf_bones=False,
                            path_mode='AUTO',use_mesh_modifiers=True,colors_type='SRGB')
    batchsha=digest(batch)
    reset(); bpy.ops.import_scene.fbx(filepath=str(batch))
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if len(imported)!=21 or {o.name for o in imported}!=set(expected): raise RuntimeError('Batch lost/renamed model roots')
    validated=[]
    for obj in imported:
        e=expected[obj.name]; row=e['row']; qa=check_mesh(obj); dims,center=bounds(obj)
        if any(abs(a-b)>1e-6 for a,b in zip(dims,e['dimensions'])) or max(abs(v) for v in center)>1e-6:
            raise RuntimeError(obj.name+' combined scale/origin mismatch')
        if len(obj.data.polygons)!=e['triangles'] or len(obj.data.vertices)!=row['vertices']:
            raise RuntimeError(obj.name+' combined topology mismatch')
        if color_set(obj)!=e['colors'] or len(obj.data.uv_layers)!=1:
            raise RuntimeError(obj.name+' combined paint/UV mismatch')
        uvs=[float(c) for entry in obj.data.uv_layers[0].data for c in entry.uv]
        if min(uvs)<-.0001 or max(uvs)>1.0001: raise RuntimeError(obj.name+' UV outside normalized range')
        if digest(ROOT/row['export'])!=row['sha256']: raise RuntimeError('Individual FBX changed during batch export')
        validated.append(dict(qa,id=obj.name,status='COMBINED_FBX_COMPONENT_PASS',meshName=obj.name,
                              individualFbxSha256=row['sha256'],fbxSha256=row['sha256'],batchSha256=batchsha,
                              triangles=len(obj.data.polygons),vertices=len(obj.data.vertices),
                              roundtripDimensions=dims,robloxIntendedSize=row['robloxIntendedSize'],
                              center=center,paintedColorCount=len(e['colors']),uvLayers=1,uvMin=min(uvs),uvMax=max(uvs)))
    report={'status':'HIGH21_COMBINED_FBX_ROUND_TRIP_PASS','batchExport':str(batch.relative_to(ROOT)).replace('\\','/'),
            'batchSha256':batchsha,'assetCount':21,'globalScale':.01,'combinedByJoining':False,
            'method':'Actual frozen component FBX import, inverse100 scale, distinct mesh export, actual combined FBX reimport; individual export hashes verified unchanged',
            'assets':sorted(validated,key=lambda r:r['id'])}
    (SOURCE/'high_import_batch_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('HIGH21_IMPORT_BATCH_PASS',batchsha,sum(r['triangles'] for r in validated),flush=True)

if __name__=='__main__': main()
