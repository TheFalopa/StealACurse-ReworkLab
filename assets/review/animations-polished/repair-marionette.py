"""Keep the approved sculpt; articulate its real elbows/knees and string endpoints."""
import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(r'C:\RobloxProjects\StealACurse');HERE=ROOT/'assets/source/blender/curse_animation'
sys.path.insert(0,str(HERE));from inspect_sources import components;from audit_semantics import author,original
ident='phantom_marionette';info=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())[ident]
proto=original.geo.Sculpt();author(ident)(proto)
lo=Vector([min(v[i]for v in proto.vertices)for i in range(3)]);hi=Vector([max(v[i]for v in proto.vertices)for i in range(3)]);center=(lo+hi)/2
size=Vector((info['observedSize'][0],info['observedSize'][2],info['observedSize'][1]));factor=Vector([size[i]/(hi[i]-lo[i])for i in range(3)])
def point(p):return Vector([(p[i]-center[i])*factor[i]for i in range(3)])
def raw(p):return Vector([p[i]/factor[i]+center[i]for i in range(3)])
def digest(mesh):
 return hashlib.sha256(json.dumps({'v':[list(v.co)for v in mesh.vertices],'f':[list(p.vertices)for p in mesh.polygons],'m':[p.material_index for p in mesh.polygons],'uv':[[list(d.uv)for d in l.data]for l in mesh.uv_layers],'c':[[list(d.color)for d in l.data]for l in mesh.color_attributes]},separators=(',',':')).encode()).hexdigest()
lines={n:[Vector(p)for p in ps]for n,ps in {
 'ArmL':[(-.28,0,2.98),(-.79,-.05,3.24),(-1.24,-.10,3.63)],
 'ArmR':[(.31,0,2.96),(.77,.01,2.70),(1.28,-.06,2.45)],
 'LegL':[(-.19,0,2.36),(-.62,-.05,1.71),(-.41,-.12,1.08)],
 'LegR':[(.21,0,2.34),(.47,.14,1.85),(.87,.11,1.61)]}.items()}
def nearest(p,line):
 best=(1e8,0);run=0
 for a,b in zip(line,line[1:]):
  v=b-a;t=max(0,min(1,(p-a).dot(v)/v.length_squared));d=(p-a-v*t).length_squared
  if d<best[0]:best=(d,run+v.length*t)
  run+=v.length
 return best
tree=BVHTree.FromPolygons([Vector(v)for v in proto.vertices],proto.faces)
parts=[0]*len(proto.faces)
for index,part in enumerate(proto.parts):
 end=proto.parts[index+1]['first_face']if index+1<len(proto.parts)else len(parts)
 for f in range(part['first_face'],end):parts[f]=index
bpy.ops.wm.open_mainfile(filepath=str(ROOT/info['blend']))
mesh=next(o for o in bpy.data.objects if o.type=='MESH');rig=next(o for o in bpy.data.objects if o.type=='ARMATURE');before=digest(mesh.data)
string_bones=[('ArmLTip',Vector((-1.24,-.09,3.65))),('Head',Vector((.10,-.02,3.88))),('ArmRTip',Vector((1.28,-.05,2.46))),('Body',Vector((-.19,.03,2.37)))]
for connected in components(mesh.data):
 points=[raw(mesh.data.vertices[i].co)for i in connected];mean=sum(points,Vector())/len(points)
 probes=points[::max(1,len(points)//15)]
 votes=[parts[tree.find_nearest(p)[2]]for p in probes]
 part=max(set(votes),key=votes.count)
 string=False
 if part==1:
  # Long thin strings have >.3 height range; crossbars stay on Root.
  a=min(points,key=lambda p:p.z);b=max(points,key=lambda p:p.z)
  string=b.z-a.z>.30 and b.z>4.40 and (max(p.x for p in points)-min(p.x for p in points))<1.1
  chosen=min(string_bones,key=lambda pair:(a-pair[1]).length_squared)[0]if string else 'Root'
 elif mean.z>3.10 and abs(mean.x)<.69:
  chosen='Head'
 else:
  scores={name:sum(nearest(p,line)[0]for p in probes)/len(probes)for name,line in lines.items()}
  chosen=min(scores,key=scores.get)
  if scores[chosen]>.075:chosen='Body'
 for index,p in zip(connected,points):
  for old in list(mesh.data.vertices[index].groups):mesh.vertex_groups[old.group].remove([index])
  if string:
   zmin=min(v.z for v in points);zmax=max(v.z for v in points);q=max(0,min(1,(zmax-p.z)/(zmax-zmin)))
   weights={'Root':1-q,chosen:q}
  elif chosen in lines:
   line=lines[chosen];distance=nearest(p,line)[1];k=(line[1]-line[0]).length
   q=max(0,min(1,(distance-k+.10)/.20));q=q*q*(3-2*q)
   weights={chosen:1-q,chosen+'Tip':q}
  else:weights={chosen:1}
  for name,w in weights.items():
   if w>1e-6:mesh.vertex_groups[name].add([index],w,'REPLACE')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for name,line in lines.items():
 for label,p in [(name,line[0]),(name+'Tip',line[1])]:
  b=rig.data.edit_bones[label];b.head=point(p);b.tail=b.head+Vector((0,0,size.z*.025))
bpy.ops.object.mode_set(mode='OBJECT');assert digest(mesh.data)==before
blend=ROOT/'assets/source/blender/animations-polished/phantom_marionette.blend';fbx=ROOT/'assets/export/meshes/curses/animations-polished/phantom_marionette.fbx'
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(blend))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,use_mesh_modifiers=True,colors_type='SRGB')
weighted={b.name:sum(1 for v in mesh.data.vertices if any(g.group==mesh.vertex_groups[b.name].index and g.weight>.001 for g in v.groups))for b in rig.data.bones}
for name in lines:assert weighted[name]>0 and weighted[name+'Tip']>0,(name,weighted)
row={'id':ident,'previousBlend':info['blend'],'previousFBX':info['fbx'],'previousMeshId':info['meshId'],'blend':blend.relative_to(ROOT).as_posix(),'fbx':fbx.relative_to(ROOT).as_posix(),'blendSHA256':hashlib.sha256(blend.read_bytes()).hexdigest(),'fbxSHA256':hashlib.sha256(fbx.read_bytes()).hexdigest(),'geometrySHA256Before':before,'geometrySHA256After':digest(mesh.data),'vertices':len(mesh.data.vertices),'triangles':len(mesh.data.polygons),'targetSize':info['observedSize'],'bones':[b.name for b in rig.data.bones],'weightedCounts':weighted,'realImportRecorded':False,'playReviewed':False,'rigChanges':'Original semantic bone names/parents retained. Actual proximal and distal puppet tubes blended around authored elbows/knees. Four lower string endpoints follow ArmLTip, Head, ArmRTip, Body; upper endpoints remain Root. Crossbars remain rigid.'}
path=ROOT/'assets/review/animations-polished/creatures-rig-repairs.json';rows=json.loads(path.read_text());rows=[r for r in rows if r['id']!=ident]+[row];path.write_text(json.dumps(rows,indent=2))
print('REPAIRED',ident,weighted,flush=True)
