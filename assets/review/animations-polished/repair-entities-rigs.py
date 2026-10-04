"""Minimal owned rig repairs; no Studio access and no invented asset IDs.

Run with Blender 5.2 --background --python <this file>. Saves 3 editable rigs
and separate FBX exports for the root coordinator to import with real tools.
"""
import bpy, bmesh, hashlib, json
from pathlib import Path
from collections import Counter

ROOT=Path(r'C:\RobloxProjects\StealACurse')
OUT=ROOT/'assets/export/meshes/curses/animations-polished/entities'
OUT.mkdir(parents=True,exist_ok=True)
records=[]
RECORD_FILE=ROOT/'assets/review/animations-polished/entities-rig-repairs.json'
previous={r['id']:r for r in json.loads(RECORD_FILE.read_text())} if RECORD_FILE.exists() else {}

def components(mesh):
    adjacency=[[] for _ in mesh.vertices]
    for edge in mesh.edges:
        a,b=edge.vertices;adjacency[a].append(b);adjacency[b].append(a)
    seen=set();result=[]
    for start in range(len(adjacency)):
        if start in seen:continue
        stack=[start];seen.add(start);indices=[]
        while stack:
            index=stack.pop();indices.append(index)
            for neighbour in adjacency[index]:
                if neighbour not in seen:seen.add(neighbour);stack.append(neighbour)
        result.append(indices)
    return result

def assign(obj,indices,bone,weight=1):
    for group in obj.vertex_groups:group.remove(indices)
    obj.vertex_groups[bone].add(indices,weight,'REPLACE')
    if weight<1:obj.vertex_groups['Root'].add(indices,1-weight,'REPLACE')

for identity in ('silent_choir','night_harp','the_last_funeral'):
    source=ROOT/'assets/source/blender/curse_animation'/(identity+'.blend')
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    saved=previous.get(identity)
    if saved and before==saved['blendSHA256'] and (ROOT/saved['fbx']).exists() and hashlib.sha256((ROOT/saved['fbx']).read_bytes()).hexdigest()==saved['fbxSHA256']:
        records.append(saved)
        print('REUSE_VERIFIED_REPAIR',identity)
        continue
    bpy.ops.wm.open_mainfile(filepath=str(source))
    obj=next(o for o in bpy.data.objects if o.type=='MESH' and o.vertex_groups)
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    parts=components(obj.data)
    vertices_before=len(obj.data.vertices)
    if identity=='silent_choir':
        assert len(parts)==34 and len(parts[16])==144 and len(parts[27])==144
        # Original part marker for one head swallowed the next robe. Connected
        # components retain exact authored geometry and allow proper ownership.
        for singer,body,head in [(0,range(0,5),range(5,11)),(1,range(11,16),range(16,22)),(2,range(22,27),range(27,33))]:
            for part in body:assign(obj,parts[part],'Singer'+str(singer))
            for part in head:assign(obj,parts[part],'Bell'+str(singer))
        changes='Assign all three robe bodies to Singer0/1/2 and their own bell/head/hand ornaments to Bell0/1/2; names, pivots and geometry unchanged.'
    elif identity=='night_harp':
        assert len(parts)==59 and all(len(parts[p])==20 for p in (32,34,36,38))
        for p in (29,30,31,*range(44,59)):
            assign(obj,parts[p],'Root')
        # Keep the four physical tubes, introduce interpolation vertices only
        # along their existing straight faces. Endpoints remain on the frame.
        wire_indices=set(i for p in (32,34,36,38) for i in parts[p])
        bm=bmesh.new();bm.from_mesh(obj.data);bm.verts.ensure_lookup_table()
        edges=[e for e in bm.edges if all(v.index in wire_indices for v in e.verts) and e.calc_length()>1.0]
        assert len(edges)>=20
        bmesh.ops.subdivide_edges(bm,edges=edges,cuts=4,use_grid_fill=True)
        bm.to_mesh(obj.data);bm.free();obj.data.update()
        wire_parts=[]
        for indices in components(obj.data):
            points=[obj.data.vertices[i].co for i in indices]
            lo=[min(p[a]for p in points)for a in range(3)];hi=[max(p[a]for p in points)for a in range(3)]
            if hi[2]-lo[2]>4 and hi[0]-lo[0]<.55 and hi[1]-lo[1]<.4:
                wire_parts.append((sum(p.x for p in points)/len(points),indices,lo,hi))
        assert len(wire_parts)==4,wire_parts
        import math
        for number,(_,indices,lo,hi) in enumerate(sorted(wire_parts)):
            for index in indices:
                u=(obj.data.vertices[index].co.z-lo[2])/(hi[2]-lo[2])
                weight=math.sin(math.pi*max(0,min(1,u)))**2
                assign(obj,[index],'String'+str(number),weight)
        changes='Return harp frame, scale plates and three rings to Root. Head retains only actual ivory head/visor. Four strings receive 4 longitudinal subdivisions and pinned endpoint weights so String0/1/2/3 bend their own tube centers.'
    else:
        # Upper straps wrap the rigid coffin; fade leg influence before reaching
        # their hip attachment to avoid rotating the entire wrap off the lid.
        for vertex in obj.data.vertices:
            influences={obj.vertex_groups[g.group].name:g.weight for g in vertex.groups}
            leg=next((name for name in influences if name.startswith('Leg')),None)
            if leg:
                hip=arm.data.bones[leg].head_local.z
                influence=max(0,min(1,(hip+.22-vertex.co.z)/.44))
                original=influences.copy()
                for group in obj.vertex_groups:group.remove([vertex.index])
                root_weight=original.get('Root',0)
                for name,weight in original.items():
                    if name=='Root':continue
                    obj.vertex_groups[name].add([vertex.index],weight*influence,'REPLACE')
                    root_weight+=weight*(1-influence)
                obj.vertex_groups['Root'].add([vertex.index],root_weight,'REPLACE')
        changes='Fade upper leg weights to rigid Root at the coffin hip attachment; all four carriers retain articulated lower limbs. Geometry and pivots unchanged.'
    for vertex in obj.data.vertices:
        assert abs(sum(g.weight for g in vertex.groups)-1)<1e-4,(identity,vertex.index)
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);obj.select_set(True);bpy.context.view_layer.objects.active=obj
    fbx=OUT/(identity+'.fbx')
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,use_mesh_modifiers=True,colors_type='SRGB')
    counts=Counter()
    for vertex in obj.data.vertices:
        for g in vertex.groups:
            if g.weight>.001:counts[obj.vertex_groups[g.group].name]+=1
    records.append({'id':identity,'blend':source.relative_to(ROOT).as_posix(),'beforeBlendSHA256':before,'blendSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'fbx':fbx.relative_to(ROOT).as_posix(),'fbxSHA256':hashlib.sha256(fbx.read_bytes()).hexdigest(),'verticesBefore':vertices_before,'vertices':len(obj.data.vertices),'weightedCounts':dict(counts),'changes':changes,'realImportRecorded':False})
RECORD_FILE.write_text(json.dumps(records,indent=2),encoding='utf-8')
print('RIG_REPAIRS_PREPARED',len(records))
