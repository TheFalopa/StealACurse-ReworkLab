"""Shared original Curse rework authoring, painted surfaces, export and QA.

API: Sculpt() extends the historical Builder primitives (box, bevel_box,
profile, tube, ellipsoid, ring, ribbon, lathe, diamond). Methods take palette
keys. Add new keys to PALETTE. begin_part(name) records semantic face ranges.
finish(id,name,rarity,reference,hook,profile) creates centered object, real FBX,
per-Curse metrics and editable .blend. render(obj,path,azimuth=-.28) captures
actual geometry. validate_asset(metrics) reimports and returns roundtrip QA.
Modeling functions must return hook in Blender X/Y/Z before centering.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

sys.dont_write_bytecode = True
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[4]
EXPORT = ROOT / 'assets/export/meshes/curses/rework'
EXPORT.mkdir(parents=True, exist_ok=True)
spec = importlib.util.spec_from_file_location('historical_expansion_builder', SOURCE.parent / 'generate_expansion.py')
old = importlib.util.module_from_spec(spec)
spec.loader.exec_module(old)

PALETTE = dict(old.PALETTE)
PALETTE.update({
    'wax': (.90,.77,.49), 'wax_light': (1,.88,.62), 'wax_shadow': (.64,.48,.25),
    'flame': (.13,.78,.95), 'flame_core': (.55,.98,1), 'eye': (.025,.022,.028),
    'stone_light': (.53,.49,.42), 'stone_dark': (.25,.245,.23), 'moss': (.38,.47,.12),
    'iron': (.23,.20,.21), 'iron_edge': (.40,.33,.28), 'rust': (.45,.245,.105),
    'blue_cloth': (.20,.35,.46), 'cloth': (.095,.085,.10), 'cloth_edge': (.19,.17,.19),
    'ochre': (.63,.37,.10), 'petal': (.84,.55,.20), 'green': (.30,.34,.13),
    'paper': (.80,.66,.42), 'paper_light': (.92,.78,.52), 'ink': (.028,.025,.035),
    'gold': (.58,.39,.14), 'gold_edge': (.82,.61,.29), 'ghost': (.89,.84,.68),
    'green_glow': (.61,.76,.25), 'sand': (.66,.55,.36), 'sand_light': (.81,.71,.51),
    'porcelain': (.86,.82,.69), 'blue_paint': (.18,.33,.48), 'white_glow': (.99,.88,.57),
})


def reset():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def material():
    mat=bpy.data.materials.get('SAC_Rework_Painted') or bpy.data.materials.new('SAC_Rework_Painted')
    mat.use_nodes=True
    nt=mat.node_tree
    nt.nodes.clear()
    output=nt.nodes.new('ShaderNodeOutputMaterial')
    shader=nt.nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Roughness'].default_value=.78
    paint=nt.nodes.new('ShaderNodeVertexColor'); paint.layer_name='SACPaintedColor'
    emit=nt.nodes.new('ShaderNodeAttribute'); emit.attribute_name='SACEmissiveMask'
    nt.links.new(paint.outputs['Color'],shader.inputs['Base Color'])
    nt.links.new(paint.outputs['Color'],shader.inputs['Emission Color'])
    nt.links.new(emit.outputs['Fac'],shader.inputs['Emission Strength'])
    nt.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    mat.diffuse_color=(1,1,1,1)
    return mat


class Sculpt(old.Builder):
    def __init__(self):
        super().__init__()
        self.parts=[]

    def begin_part(self,name):
        self.parts.append({'name':name,'first_face':len(self.faces)})

    def transform_since(self,start,matrix):
        for index in range(start,len(self.vertices)):
            self.vertices[index]=tuple(matrix @ Vector(self.vertices[index]))

    def rotated_box(self,center,size,key,angles=(0,0,0),bevel=.08):
        start=len(self.vertices)
        self.bevel_box((0,0,0),size,key,bevel)
        rotation=Matrix.Rotation(angles[2],4,'Z') @ Matrix.Rotation(angles[1],4,'Y') @ Matrix.Rotation(angles[0],4,'X')
        self.transform_since(start,Matrix.Translation(Vector(center)) @ rotation)

    def leaf(self,points,widths,key,thickness=.08):
        self.ribbon(points,widths,key,thickness)

    def object(self,name,mat=None):
        mins=[min(v[a] for v in self.vertices) for a in range(3)]
        maxs=[max(v[a] for v in self.vertices) for a in range(3)]
        self.offset=[(lo+hi)*.5 for lo,hi in zip(mins,maxs)]
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v[a]-self.offset[a] for a in range(3)) for v in self.vertices],[],self.faces)
        mesh.update(); mesh.materials.append(mat or material())
        uv=mesh.uv_layers.new(name='CurseMaterialUV')
        colors=mesh.color_attributes.new(name='SACPaintedColor',type='BYTE_COLOR',domain='CORNER')
        mesh.color_attributes.active_color=colors
        mask=mesh.attributes.new(name='SACEmissiveMask',type='FLOAT',domain='CORNER')
        names=list(PALETTE)
        tile_grid=math.ceil(math.sqrt(len(names)))
        luminous={'flame','flame_core','cyan','white_glow','green_glow'}
        for polygon,key in zip(mesh.polygons,self.face_materials):
            tile=names.index(key)
            normal=polygon.normal
            dominant=max(range(3),key=lambda a:abs(normal[a])); axes=[a for a in range(3) if a!=dominant]
            for li in polygon.loop_indices:
                v=mesh.vertices[mesh.loops[li].vertex_index].co+Vector(self.offset)
                u=(v[axes[0]]-mins[axes[0]])/max(.001,maxs[axes[0]]-mins[axes[0]])
                w=(v[axes[1]]-mins[axes[1]])/max(.001,maxs[axes[1]]-mins[axes[1]])
                uv.data[li].uv=((tile%tile_grid+.035+u*.93)/tile_grid,(tile//tile_grid+.035+w*.93)/tile_grid)
                height=(v.z-mins[2])/max(.001,maxs[2]-mins[2])
                broad=.82+.19*height+.07*math.sin(v.x*2.9+v.z*1.7+tile)
                variation=.065*math.sin(v.x*11.1+v.y*8.7+v.z*6.1+tile*1.37)
                if key in {'cloth','cloth_edge','blue_cloth','paper','paper_light'}:
                    variation+=.03*math.sin(v.z*25+v.x*1.8)
                if key in {'wood','bark','green','ochre'}:
                    variation+=.06*math.sin(v.z*2+v.x*13.5)
                if key in {'iron','iron_edge','gold','gold_edge','stone','stone_light','sand'}:
                    variation+=.055*math.sin(v.x*14.2-v.z*8.8+v.y*3.6)
                edge=.035*max(0,normal.z) if key not in luminous|{'eye','ink'} else 0
                rgb=tuple(max(0,min(1,c*(broad+variation)+edge)) for c in PALETTE[key])
                colors.data[li].color_srgb=rgb+(1,)
                mask.data[li].value=1.1 if key in luminous else 0
        bm=bmesh.new(); bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bm.to_mesh(mesh); bm.free(); mesh.update()
        obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
        obj['sourceReference']=str(name)
        return obj

    def finish(self,id,display,rarity,reference,hook,profile='authored',notes='',diagonal_limit=7):
        obj=self.object(id)
        obj['sourceReference']=reference; obj['designNotes']=notes
        dims=tuple(float(v) for v in obj.dimensions)
        diagonal=math.sqrt(sum(v*v for v in dims))
        if diagonal>diagonal_limit: raise RuntimeError(f'{id}: authored diagonal {diagonal:.3f} exceeds {diagonal_limit}')
        qa=check_mesh(obj)
        shifted=tuple(hook[i]-self.offset[i] for i in range(3))
        obj['VFXHook_Blender']=shifted; obj['VFXProfile']=profile
        fbx=EXPORT/(id+'.fbx')
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,
                                 bake_space_transform=False,object_types={'MESH'},add_leaf_bones=False,
                                 path_mode='AUTO',use_mesh_modifiers=True,colors_type='SRGB')
        for index,part in enumerate(self.parts):
            part['last_face_exclusive']=self.parts[index+1]['first_face'] if index+1<len(self.parts) else len(self.faces)
        colors=obj.data.color_attributes.get('SACPaintedColor')
        unique_colors=len({tuple(round(float(c)*255) for c in item.color_srgb) for item in colors.data})
        row={'id':id,'displayName':display,'rarity':rarity,'sourceReference':reference,
             'source':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
             'export':str(fbx.relative_to(ROOT)).replace('\\','/'),
             'sha256':hashlib.sha256(fbx.read_bytes()).hexdigest(),'triangles':len(obj.data.polygons),
             'vertices':len(obj.data.vertices),'blenderDimensions':list(dims),
             'intendedRobloxSize':[dims[0],dims[2],dims[1]],'diagonal':diagonal,
             'vfxHook':[shifted[0],shifted[2],-shifted[1]],'vfxProfile':profile,
             'palette':sorted(set(self.face_materials)),'paintedColorCount':unique_colors,
             'uvLayers':len(obj.data.uv_layers),'colorLayer':'SACPaintedColor','semanticParts':self.parts,
             'modelComplete':True,'referenceReviewed':True,'localValidation':qa,'realImportRecorded':False,
             'appearanceChecked':False,'gameplayChecked':False,'enabled':False,
             'designNotes':notes if isinstance(notes,list) else [notes],
             'blendSource':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
             'robloxIntendedSize':[dims[0],dims[2],dims[1]],
             'vfxHookRoblox':[shifted[0],shifted[2],-shifted[1]]}
        bpy.context.preferences.filepaths.save_version=0
        bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(id+'.blend')))
        (SOURCE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
        return obj,row


def check_mesh(obj):
    mesh=obj.data; bm=bmesh.new(); bm.from_mesh(mesh)
    qa={'nonManifoldEdges':sum(not e.is_manifold for e in bm.edges),
        'looseVertices':sum(not v.link_faces for v in bm.verts),
        'degenerateFaces':sum(f.calc_area()<1e-12 for f in bm.faces)}
    bm.free()
    if any(qa.values()): raise RuntimeError(f'{obj.name}: {qa}')
    if any(not math.isfinite(c) for v in mesh.vertices for c in v.co): raise RuntimeError('Non-finite geometry')
    return qa


def render(obj,path,azimuth=-.28):
    for o in bpy.context.scene.objects: o.hide_render=o!=obj
    center=Vector(obj.location)
    maxdim=max(obj.dimensions)
    bpy.ops.object.camera_add(location=center+Vector((maxdim*azimuth,-maxdim*3,maxdim*.70)))
    camera=bpy.context.object
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'; camera.data.ortho_scale=maxdim*1.38
    scene=bpy.context.scene; scene.camera=camera
    for location,energy,size in [((-4,-6,8),950,5),((5,-1,3),650,4),((0,5,6),1150,4)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(location)); light=bpy.context.object
        light.data.energy=energy; light.data.shape='DISK'; light.data.size=size
        light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    scene.world.color=(.035,.035,.045)
    scene.render.engine='CYCLES'; scene.cycles.samples=24
    scene.render.resolution_x=800; scene.render.resolution_y=900; scene.render.resolution_percentage=100
    scene.view_settings.view_transform='Standard'
    scene.view_settings.exposure=-.65
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)


def validate_asset(row):
    reset()
    bpy.ops.import_scene.fbx(filepath=str(ROOT/row['export']))
    roots=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if len(roots)!=1 or roots[0].name!=row['id']: raise RuntimeError('Roundtrip root/name mismatch')
    obj=roots[0]; qa=check_mesh(obj)
    bounds=[obj.matrix_world@Vector(v) for v in obj.bound_box]
    mins=[min(v[a] for v in bounds) for a in range(3)]; maxs=[max(v[a] for v in bounds) for a in range(3)]
    dims=[hi-lo for lo,hi in zip(mins,maxs)]; center=[(hi+lo)/2 for lo,hi in zip(mins,maxs)]
    if any(abs(c)>.0001 for c in center): raise RuntimeError('Roundtrip center mismatch')
    if any(abs(a-b*.01)>.0001 for a,b in zip(dims,row['blenderDimensions'])): raise RuntimeError('Roundtrip scale mismatch')
    if len(obj.data.polygons)!=row['triangles']: raise RuntimeError('Roundtrip triangle mismatch')
    colors=obj.data.color_attributes.get('SACPaintedColor')
    if not colors or len(obj.data.uv_layers)!=1: raise RuntimeError('Roundtrip color/UV missing')
    count=len({tuple(round(float(c)*255) for c in d.color_srgb) for d in colors.data})
    if count<20: raise RuntimeError(f'Insufficient authored colors: {count}')
    return dict(qa,fbxDimensions=dims,center=center,triangleCount=len(obj.data.polygons),
                colorCount=count,uvLayers=len(obj.data.uv_layers),materials=len(obj.data.materials),valid=True,
                id=row['id'],status='FBX_ROUND_TRIP_PASS',
                fbxSha256=hashlib.sha256((ROOT/row['export']).read_bytes()).hexdigest())
