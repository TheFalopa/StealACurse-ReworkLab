"""Articulate the actual second-pass volumes, retaining painted colors/UVs.
First quality cases only. Exports are pending real Studio import and Play review.
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(HERE));from inspect_sources import sources,components
sys.path.insert(0,str(ROOT/'assets/source/blender/curses_visual_pass2'))
import author_batch01 as original
geo=original.geo;high=original.high
EXPORT=ROOT/'assets/export/meshes/curses/animations';EXPORT.mkdir(parents=True,exist_ok=True)

def rig(row):
    id=row['id'];fn=original.ORIGINALS[id][2] if id in original.ORIGINALS else high.plague_monarch
    prototype=geo.Sculpt();fn(prototype)
    rawlo=Vector([min(v[i]for v in prototype.vertices)for i in range(3)])
    rawhi=Vector([max(v[i]for v in prototype.vertices)for i in range(3)])
    rawcenter=(rawlo+rawhi)/2
    target=Vector((float(row['after_W']),float(row['after_D']),float(row['after_H'])))
    factors=Vector([target[i]/(rawhi[i]-rawlo[i])for i in range(3)])
    def point(raw):return Vector([(raw[i]-rawcenter[i])*factors[i]for i in range(3)])
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/row['actualBlend']))
    obj=bpy.data.objects[id];mesh=obj.data
    lo=Vector([min(v.co[i]for v in mesh.vertices)for i in range(3)])
    hi=Vector([max(v.co[i]for v in mesh.vertices)for i in range(3)])
    for v in mesh.vertices:v.co=Vector([(v.co[i]-(lo[i]+hi[i])/2)*target[i]/(hi[i]-lo[i])for i in range(3)])
    mesh.update();groups=components(mesh)
    def raw(co):return Vector([co[i]/factors[i]+rawcenter[i]for i in range(3)])
    bones={'Root':((0,0,0),None)};assignments={}
    def add(name,p,parent='Root'):bones[name]=(p,parent)
    def rigid(ids,bone):
        for index in ids:assignments[index]={bone:1.0}
    def bend(ids,upper,lower,joint,axis=2,width=.18):
        for index in ids:
            co=raw(mesh.vertices[index].co);t=max(0,min(1,(joint+width-co[axis])/(2*width)))
            assignments[index]={upper:1-t,lower:t}
    if id=='cursed_doll':
        add('Head',(-.1,0,2.8));add('Dress',(0,0,1.9))
        for side,label in [(-1,'L'),(1,'R')]:
            add('Arm'+label,(side*.37,0,2.53));add('Hand'+label,(side*.88,-.04,1.96),'Arm'+label)
            add('Leg'+label,(side*.39,.03,1.25));add('Foot'+label,(side*.42,-.08,.69),'Leg'+label)
        for ids in groups:
            ps=[raw(mesh.vertices[i].co)for i in ids];c=sum(ps,Vector())/len(ps);width=max(v.x for v in ps)-min(v.x for v in ps)
            label='L' if c.x<0 else 'R'
            if c.z>2.82:rigid(ids,'Head')
            elif abs(c.x)>.6 and c.z>1.32:bend(ids,'Arm'+label,'Hand'+label,1.96)
            elif c.z<1.1 and width<.9:bend(ids,'Leg'+label,'Foot'+label,.69)
            elif c.z<2.25:rigid(ids,'Dress')
            else:rigid(ids,'Root')
    elif id=='watching_eye':
        add('Gaze',(0,0,3.19));add('Iris',(0,-.50,3.18),'Gaze')
        add('LidUpper',(0,-.18,3.19),'Gaze');add('LidLower',(0,-.18,3.19),'Gaze')
        for side,label in [(-1,'L'),(1,'R')]:
            add('Arm'+label,(side*1.05,.04,3.33));add('Forearm'+label,(side*2.67,-.04,2.68),'Arm'+label)
            add('Hand'+label,(side*2.57,-.24,1.58),'Forearm'+label)
            for i in range(4):add('Finger'+label+str(i),(side*(2.31+i*.17),-.38,1.05),'Hand'+label)
            add('Thumb'+label,(side*2.26,-.32,1.30),'Hand'+label)
        for ids in groups:
            ps=[raw(mesh.vertices[i].co)for i in ids];c=sum(ps,Vector())/len(ps);low=min(v.z for v in ps);label='L' if c.x<0 else 'R'
            if abs(c.x)>1.7:
                if c.z<.9:
                    i=min(range(4),key=lambda i:abs(abs(c.x)-(2.31+i*.17)));rigid(ids,'Finger'+label+str(i))
                elif abs(c.x)<2.24 and c.z<1.4:rigid(ids,'Thumb'+label)
                elif c.z<1.87:rigid(ids,'Hand'+label)
                else:bend(ids,'Arm'+label,'Forearm'+label,2.70)
            elif c.y<-.42:rigid(ids,'Iris')
            elif len(ids)<180 and abs(c.z-3.19)>.16:rigid(ids,'LidUpper' if c.z>3.19 else 'LidLower')
            else:rigid(ids,'Gaze')
        # Two authored eyelid shutters sit behind the eye while open. They
        # rotate around its horizontal diameter and actually occlude it to blink.
        for upper,label in [(True,'LidUpper'),(False,'LidLower')]:
            lid=geo.Sculpt();verts=[];faces=[];n=18;rings=5
            for j in range(rings+1):
                theta=(math.pi/2)*(j/rings)
                if not upper:theta=-theta
                for i in range(n+1):
                    phi=math.pi*i/n
                    # Ellipsoidal half shell behind the open eye.
                    verts.append((1.265*math.cos(phi)*math.cos(theta),.61*math.sin(phi)*math.cos(theta),3.19+.92*math.sin(theta)))
            for j in range(rings):
                for i in range(n):
                    a=j*(n+1)+i;faces.append((a,a+1,a+n+2,a+n+1))
            lid.vertices=verts;lid.faces=faces;lid.face_materials=['violet']*len(faces)
            lobj=lid.object(id+'_'+label);offset=Vector(lid.offset)
            bm=bmesh.new();bm.from_mesh(lobj.data)
            bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
            degenerate=[f for f in bm.faces if f.calc_area()<1e-10]
            if degenerate:bmesh.ops.delete(bm,geom=degenerate,context='FACES')
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
            bm.to_mesh(lobj.data);bm.free();lobj.data.update()
            for v in lobj.data.vertices:v.co=point(v.co+offset)
            vg=lobj.vertex_groups.new(name=label);vg.add(list(range(len(lobj.data.vertices))),1,'REPLACE')
            bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);lobj.select_set(True);bpy.context.view_layer.objects.active=obj
            # Existing groups are assigned below; preserve joined shutter group.
            bpy.ops.object.join()
        mesh=obj.data
    elif id=='soul_chains':
        add('Core',(0,-.15,2.76));add('CuffL',(-1.26,.16,3.72));add('CuffR',(1.26,.16,3.72));add('Hook',(1.47,-.05,.93))
        for side,label in [(-1,'L'),(1,'R')]:
            for i in range(6):add('Chain'+label+str(i),(side*(1.03-.13*i),-.38,3.59-i*.46))
        for i in range(7):add('CrownLink'+str(i),(-1.22+i*.40,-.16,4.22+math.sin(i*.55)*.51))
        for ids in groups:
            ps=[raw(mesh.vertices[i].co)for i in ids];c=sum(ps,Vector())/len(ps);label='L' if c.x<0 else 'R';height=max(v.z for v in ps)-min(v.z for v in ps)
            if c.z>4.02 and height<.9:bone=min(('CrownLink'+str(i)for i in range(7)),key=lambda b:(c-Vector(bones[b][0])).length)
            elif c.y<-.22 and .8<c.z<3.8 and height<.9:bone=min(('Chain'+label+str(i)for i in range(6)),key=lambda b:(c-Vector(bones[b][0])).length)
            elif c.z<1.2 and c.x>1.3:bone='Hook'
            elif abs(c.x)>.9:bone='Cuff'+label
            else:bone='Core'
            rigid(ids,bone)
    elif id=='plague_monarch':
        add('Mask',(0,-.31,2.28));add('Crown',(0,.3,2.0));add('Breath',(0,0,1.55))
        origins=[(-.65,-.25),(.66,-.24),(-.58,.58),(.57,.58)]
        for i,(x,y)in enumerate(origins):
            add('Leg'+str(i),(x*.68,y*.60,1.31));add('Shin'+str(i),(x*1.36,y,1),'Leg'+str(i))
        for ids in groups:
            ps=[raw(mesh.vertices[i].co)for i in ids];c=sum(ps,Vector())/len(ps)
            if c.z<1.18 and abs(c.x)>.4:
                i=min(range(4),key=lambda i:(c-Vector((origins[i][0]*1.3,origins[i][1],.7))).length)
                bend(ids,'Leg'+str(i),'Shin'+str(i),.82)
            elif c.y<-.27 and c.z>1.48:rigid(ids,'Mask')
            elif c.z>2.53:rigid(ids,'Crown')
            else:rigid(ids,'Breath')
    elif id=='the_void':
        add('ArcL',(-1.7,.1,3.2));add('ArcR',(1.6,.1,3.6));add('ArcBase',(.1,.1,.4))
        shardCenters=[(-2.8,0,2.0),(-2.3,0,5.6),(2.6,0,5.4),(2.8,0,2.3),(.1,0,-.45)]
        for i,c in enumerate(shardCenters):add('Shard'+str(i),c)
        for ids in groups:
            c=sum((raw(mesh.vertices[i].co)for i in ids),Vector())/len(ids)
            if abs(c.x)>2.25 or c.z<0:bone=min(('Shard'+str(i)for i in range(5)),key=lambda b:(c-Vector(bones[b][0])).length)
            else:bone='ArcL' if c.x<-.6 else 'ArcR' if c.x>.6 else 'ArcBase'
            rigid(ids,bone)
    for name in bones:
        if not obj.vertex_groups.get(name):obj.vertex_groups.new(name=name)
    for index,weights in assignments.items():
        for name,weight in weights.items():
            if weight>0:obj.vertex_groups[name].add([index],weight,'REPLACE')
    # Any added geometry must already have explicit semantic weights.
    for v in mesh.vertices:assert v.groups,f'{id}: unweighted vertex {v.index}'
    armdata=bpy.data.armatures.new(id+'_Rig');arm=bpy.data.objects.new(id+'_Rig',armdata);bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for name,(p,parent)in bones.items():
        b=armdata.edit_bones.new(name);b.head=point(p) if name!='Root' else Vector();b.tail=b.head+Vector((0,0,max(.1,target.z*.025)))
        if parent:b.parent=armdata.edit_bones[parent]
        b.use_deform=True
    bpy.ops.object.mode_set(mode='OBJECT')
    modifier=obj.modifiers.new('Curse articulation','ARMATURE');modifier.object=arm;obj.parent=arm
    bpy.context.preferences.filepaths.save_version=0
    source=HERE/(id+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=obj
    fbx=EXPORT/(id+'.fbx')
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
        object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,
        bake_anim=False,use_mesh_modifiers=True,colors_type='SRGB')
    return {'id':id,'sourceReused':row['actualBlend'],'sourceReusedSHA256':hashlib.sha256((ROOT/row['actualBlend']).read_bytes()).hexdigest(),
        'blend':source.relative_to(ROOT).as_posix(),'fbx':fbx.relative_to(ROOT).as_posix(),'fbxSHA256':hashlib.sha256(fbx.read_bytes()).hexdigest(),
        'vertices':len(mesh.vertices),'triangles':len(mesh.polygons),'bones':list(bones),'targetSize':[target.x,target.z,target.y],
        'weightedVertices':len(mesh.vertices),'realImportRecorded':False,'playReviewed':False}

def main():
    requested=sys.argv[sys.argv.index('--')+1:] if '--'in sys.argv else ['cursed_doll','watching_eye','soul_chains','plague_monarch','the_void']
    rows=[]
    for row in sources():
        if row['id']in requested:
            result=rig(row);rows.append(result);print('RIG_EXPORTED',json.dumps(result),flush=True)
    manifest=HERE/'first-five-rigs.json'
    previous=json.loads(manifest.read_text(encoding='utf8'))if manifest.exists()else []
    merged={r['id']:r for r in previous};merged.update({r['id']:r for r in rows})
    manifest.write_text(json.dumps(list(merged.values()),indent=2),encoding='utf8')
if __name__=='__main__':main()
