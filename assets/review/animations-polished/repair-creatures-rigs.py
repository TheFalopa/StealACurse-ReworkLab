"""Repair actual anatomical hinges and component weights without changing geometry."""
import bpy, json, math, hashlib, sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(r'C:\RobloxProjects\StealACurse')
HERE=ROOT/'assets/source/blender/curse_animation'
sys.path.insert(0,str(HERE))
from inspect_sources import components
from audit_semantics import author, original

def paths(ident):
    out=[]
    for side in (-1,1):
        count=4 if ident=='thimble_spider' else 3
        for i in range(count):
            if ident=='thimble_spider':
                y=-.43+i*.33
                out.append([(side*.55,y,.94),(side*(1+.11*math.sin(i)),y-.10,1.05-i*.10),(side*(1.30+.12*math.sin(i)),y-.32,.18),(side*(1.60+.08*math.cos(i)),y-.50,.095)])
            elif ident=='anchor_crab':
                y=-.30+i*.33
                out.append([(side*.58,y,.95),(side*(1.08+i*.12),y+.06,.91-i*.04),(side*(1.41+i*.06),y-.08,.29),(side*(1.61+i*.07),y-.21,.10)])
            else:
                y=-.32+i*.34
                out.append([(side*.35,y,.56),(side*.71,y-.14,.76),(side*1.03,y-.21,.21),(side*1.05,y-.34,.08)])
    return [[Vector(x) for x in line] for line in out]

def nearest(point,line):
    best=(float('inf'),0,0)
    run=0
    for a,b in zip(line,line[1:]):
        v=b-a; length=v.length
        s=max(0,min(1,(point-a).dot(v)/v.length_squared))
        distance=(point-(a+v*s)).length_squared
        if distance<best[0]:best=(distance,run+length*s,s)
        run+=length
    return best

def geometry_hash(mesh):
    payload={'vertices':[list(v.co)for v in mesh.vertices],'faces':[list(p.vertices)for p in mesh.polygons],
             'materials':[p.material_index for p in mesh.polygons],
             'uv':[[list(d.uv)for d in layer.data]for layer in mesh.uv_layers],
             'colors':[[list(d.color)for d in layer.data]for layer in mesh.color_attributes]}
    return hashlib.sha256(json.dumps(payload,separators=(',',':')).encode()).hexdigest()

ledger=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())
blenddir=ROOT/'assets/source/blender/animations-polished'
fbxdir=ROOT/'assets/export/meshes/curses/animations-polished'
blenddir.mkdir(parents=True,exist_ok=True);fbxdir.mkdir(parents=True,exist_ok=True)
manifest=[]
for ident in ('thimble_spider','anchor_crab','nail_beetle'):
    info=ledger[ident];proto=original.geo.Sculpt();author(ident)(proto)
    lo=Vector([min(v[i]for v in proto.vertices)for i in range(3)])
    hi=Vector([max(v[i]for v in proto.vertices)for i in range(3)])
    center=(lo+hi)/2
    size=Vector((info['observedSize'][0],info['observedSize'][2],info['observedSize'][1]))
    factor=Vector([size[i]/(hi[i]-lo[i])for i in range(3)])
    def point(p):return Vector([(p[i]-center[i])*factor[i]for i in range(3)])
    def raw(p):return Vector([p[i]/factor[i]+center[i]for i in range(3)])
    lines=paths(ident)
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/info['blend']))
    mesh=next(o for o in bpy.data.objects if o.type=='MESH')
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    before=geometry_hash(mesh.data)
    group_names={g.index:g.name for g in mesh.vertex_groups}
    assignments=[[]for _ in lines]
    for connected in components(mesh.data):
        original_leg=sum(1 for i in connected if any(group_names[w.group].startswith(('Leg','Knee'))and w.weight>.001 for w in mesh.data.vertices[i].groups))
        if not original_leg:continue
        probes=[raw(mesh.data.vertices[i].co)for i in connected[::max(1,len(connected)//18)]]
        index=min(range(len(lines)),key=lambda n:sum(nearest(p,lines[n])[0]for p in probes)/len(probes))
        assignments[index].extend(connected)
    for index,inds in enumerate(assignments):
        assert inds,(ident,index,'no actual leg geometry')
        leg=mesh.vertex_groups['Leg'+str(index)];knee=mesh.vertex_groups['Knee'+str(index)]
        upper_length=(lines[index][1]-lines[index][0]).length
        for i in inds:
            vertex=mesh.data.vertices[i]
            for old in list(vertex.groups):mesh.vertex_groups[old.group].remove([i])
            _,distance,_=nearest(raw(vertex.co),lines[index])
            blend=max(0,min(1,(distance-upper_length+.11)/.22));blend=blend*blend*(3-2*blend)
            if blend<1:leg.add([i],1-blend,'REPLACE')
            if blend>0:knee.add([i],blend,'REPLACE')
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    joint_manifest=[]
    for index,line in enumerate(lines):
        old_hip=list(rig.data.edit_bones['Leg'+str(index)].head)
        old_knee=list(rig.data.edit_bones['Knee'+str(index)].head)
        for label,p in [('Leg',line[0]),('Knee',line[1])]:
            b=rig.data.edit_bones[label+str(index)];b.head=point(p);b.tail=b.head+Vector((0,0,size.z*.025))
        def native(p):return [-p.x,p.z,p.y]
        joint_manifest.append({'index':index,'previousHipBlender':old_hip,'previousKneeBlender':old_knee,
           'hipRoblox':native(point(line[0])),'kneeRoblox':native(point(line[1])),'footRoblox':native(point(line[-1])), 'weightedVertices':len(inds)})
    bpy.ops.object.mode_set(mode='OBJECT')
    assert before==geometry_hash(mesh.data),'Geometry or appearance changed'
    blend=blenddir/(ident+'.blend');fbx=fbxdir/(ident+'.fbx')
    bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
       object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,use_mesh_modifiers=True,colors_type='SRGB')
    weights={b.name:sum(1 for v in mesh.data.vertices if any(g.group==mesh.vertex_groups[b.name].index and g.weight>.001 for g in v.groups))for b in rig.data.bones}
    row={'id':ident,'previousBlend':info['blend'],'previousFBX':info['fbx'],'previousMeshId':info['meshId'],
         'blend':blend.relative_to(ROOT).as_posix(),'fbx':fbx.relative_to(ROOT).as_posix(),
         'blendSHA256':hashlib.sha256(blend.read_bytes()).hexdigest(),'fbxSHA256':hashlib.sha256(fbx.read_bytes()).hexdigest(),
         'geometrySHA256Before':before,'geometrySHA256After':geometry_hash(mesh.data),'vertices':len(mesh.data.vertices),'triangles':len(mesh.data.polygons),
         'targetSize':info['observedSize'],'bones':[b.name for b in rig.data.bones],'weightedCounts':weights,'legs':joint_manifest,
         'realImportRecorded':False,'playReviewed':False,'rigChanges':'Existing Leg#/Knee# semantic names and parents preserved. Hip/knee bind pivots follow authored physical paths; whole connected leg volumes assigned to their own path, with local upper/lower blend at the physical knee.'}
    manifest.append(row)
    print('REPAIRED',ident,len(assignments),[len(a)for a in assignments],flush=True)
(ROOT/'assets/review/animations-polished/creatures-rig-repairs.json').write_text(json.dumps(manifest,indent=2))
