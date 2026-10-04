"""Build an import convenience batch from exact frozen Common FBX components.

No individual source/export is rewritten. The batch contains fifteen separate
named Mesh objects at the origin, retaining their own UV and corner paint.
"""
from pathlib import Path
import sys, json, hashlib, math
import bpy, bmesh
from mathutils import Matrix, Vector

SOURCE=Path(__file__).resolve().parent
sys.path.insert(0,str(SOURCE))
from rework_geometry import ROOT, EXPORT, reset, check_mesh, material


def signature(obj):
    check_mesh(obj)
    bounds=[obj.matrix_world@Vector(v) for v in obj.bound_box]
    lo=[min(v[a] for v in bounds) for a in range(3)]
    hi=[max(v[a] for v in bounds) for a in range(3)]
    colors=obj.data.color_attributes.get('SACPaintedColor')
    if not colors: raise RuntimeError(obj.name+': missing painted corners')
    rgba=[tuple(round(c*255) for c in d.color_srgb) for d in colors.data]
    # Order-insensitive corner color multiset survives FBX triangulation order.
    color_sha=hashlib.sha256(json.dumps(sorted(rgba),separators=(',',':')).encode()).hexdigest()
    return {'dimensions':[hi[a]-lo[a] for a in range(3)],'center':[(hi[a]+lo[a])/2 for a in range(3)],
            'triangles':len(obj.data.polygons),'vertices':len(obj.data.vertices),
            'uvLayers':len(obj.data.uv_layers),'colorCount':len(set(rgba)),
            'colorCornersSha256':color_sha,'materials':len(obj.data.materials)}


def batch(rows):
    reset(); originals={}
    for row in rows:
        before=set(bpy.data.objects)
        path=ROOT/row['export']
        bpy.ops.import_scene.fbx(filepath=str(path))
        imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
        assert len(imported)==1 and imported[0].name==row['id']
        obj=imported[0]; originals[row['id']]=signature(obj)
        assert hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256']
        # Imported geometry is metres (.01 authored units). Bake world geometry
        # back to authored scale and reset transforms before the .01 FBX export.
        world=obj.matrix_world.copy()
        for v in obj.data.vertices: v.co=(world@v.co)*100
        obj.matrix_world=Matrix.Identity(4); obj.data.update()
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH': obj.select_set(True)
    path=EXPORT/'common_import_batch.fbx'
    bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,global_scale=.01,
        apply_unit_scale=True,bake_space_transform=False,object_types={'MESH'},
        add_leaf_bones=False,path_mode='AUTO',use_mesh_modifiers=True,colors_type='SRGB')
    reset(); bpy.ops.import_scene.fbx(filepath=str(path))
    objects={o.name:o for o in bpy.context.scene.objects if o.type=='MESH'}
    assert set(objects)==set(originals),'Combined batch roots differ from components'
    validated=[]
    for row in rows:
        actual=signature(objects[row['id']]); expected=originals[row['id']]
        for key in ('dimensions','center'):
            assert all(abs(a-b)<1e-6 for a,b in zip(actual[key],expected[key])),(row['id'],key)
        for key in ('triangles','vertices','uvLayers','colorCount','colorCornersSha256','materials'):
            assert actual[key]==expected[key],(row['id'],key,actual[key],expected[key])
        assert max(abs(c) for c in actual['center'])<1e-6
        validated.append(dict(actual,id=row['id'],componentExport=row['export'],
            componentFbxSha256=row['sha256'],robloxIntendedSize=row['robloxIntendedSize'],
            status='BATCH_COMPONENT_ROUND_TRIP_PASS'))
    report={'status':'COMMON_BATCH_ROUND_TRIP_PASS','export':str(path.relative_to(ROOT)).replace('\\','/'),
            'fbxSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'roots':len(objects),
            'totalTriangles':sum(r['triangles'] for r in rows),'assets':validated}
    (SOURCE/'common_import_batch_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('COMMON_BATCH_PASS',report['roots'],report['totalTriangles'],report['fbxSha256'])


def contact_sheet(rows):
    reset(); paint=material()
    for index,row in enumerate(rows):
        with bpy.data.libraries.load(str(ROOT/row['blendSource']),link=False) as (available,loaded):
            loaded.objects=[row['id']]
        obj=loaded.objects[0]; bpy.context.collection.objects.link(obj)
        # Preserve actual authored proportions; each source has its own bounds.
        x=(index%5-2)*4.8; z=(1-index//5)*5.2+.7
        obj.location=(x,0,z); obj.data.materials.clear(); obj.data.materials.append(paint)
        bpy.ops.object.text_add(location=(x,-.05,z-2.3),rotation=(math.pi/2,0,0))
        label=bpy.context.object; label.data.body=row['displayName']; label.data.align_x='CENTER'
        label.data.size=.29; label.data.extrude=0
        caption=bpy.data.materials.get('ContactCaption') or bpy.data.materials.new('ContactCaption')
        caption.diffuse_color=(.83,.80,.70,1); label.data.materials.append(caption)
    bpy.ops.object.camera_add(location=(0,-65,6.2))
    camera=bpy.context.object; target=Vector((0,0,.65))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'; camera.data.ortho_scale=25.0
    scene=bpy.context.scene; scene.camera=camera
    for p,power,size in [((-7,-15,13),9000,14),((13,-7,4),6500,11),((0,8,13),10000,12)]:
        bpy.ops.object.light_add(type='AREA',location=p)
        light=bpy.context.object; light.data.energy=power; light.data.shape='DISK'; light.data.size=size
        light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
    scene.world.color=(.022,.024,.031); scene.render.engine='CYCLES'; scene.cycles.samples=32
    scene.render.resolution_x=1800; scene.render.resolution_y=1280; scene.render.resolution_percentage=100
    scene.view_settings.view_transform='Standard'; scene.view_settings.exposure=-.3
    scene.render.filepath=str(SOURCE/'common_contact_sheet.png')
    bpy.ops.render.render(write_still=True)


if __name__=='__main__':
    rows=json.loads((SOURCE/'common_geometry.json').read_text(encoding='utf-8'))['assets']
    batch(rows); contact_sheet(rows)
