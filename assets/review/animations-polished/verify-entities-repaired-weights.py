"""Meaningful Blender deformation checks of the 3 repaired bindings.
These tests establish weight isolation; root must still verify imported Play.
"""
import bpy, json
from pathlib import Path
from mathutils import Vector

ROOT=Path(r'C:\RobloxProjects\StealACurse')
results=[]
for identity in ('silent_choir','night_harp','the_last_funeral'):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/source/blender/curse_animation'/(identity+'.blend')))
    mesh=next(o for o in bpy.data.objects if o.type=='MESH' and o.vertex_groups)
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    group_names={g.index:g.name for g in mesh.vertex_groups}
    bpy.context.view_layer.update()
    def points():
        evaluation=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        data=evaluation.to_mesh()
        result=[v.co.copy()for v in data.vertices]
        evaluation.to_mesh_clear()
        return result
    rest=points()
    bones=['Bell1','Bell2'] if identity=='silent_choir' else ['String0','String1','String2','String3','Head'] if identity=='night_harp' else ['Leg0','Leg1','Leg2','Leg3']
    for name in bones:
        for bone in rig.pose.bones:bone.matrix_basis.identity()
        bone=rig.pose.bones[name]
        if name.startswith('String'):bone.location=Vector((.1,0,0))
        else:bone.rotation_mode='XYZ';bone.rotation_euler.y=.3
        bpy.context.view_layer.update();deformed=points()
        distances=[(a-b).length for a,b in zip(rest,deformed)]
        affected={i for i,d in enumerate(distances)if d>1e-5}
        controlled={name}|{child.name for child in rig.data.bones[name].children_recursive}
        expected={v.index for v in mesh.data.vertices if any(group_names[g.group] in controlled and g.weight>1e-4 for g in v.groups)}
        assert affected and affected<=expected,(identity,name,len(affected),len(expected),affected-expected)
        other_robes={v.index for v in mesh.data.vertices if any(group_names[g.group].startswith('Singer') and g.weight>.99 for g in v.groups)} if identity=='silent_choir' else set()
        assert not(affected & other_robes),(identity,name,'head alters robes')
        results.append({'id':identity,'bone':name,'affectedVertices':len(affected),'expectedWeightedVertices':len(expected),'maximumLocalDisplacement':max(distances),'unexpectedAffectedVertices':len(affected-expected),'otherRobeVerticesMoved':len(affected & other_robes),'status':'PASS_BLENDER_WEIGHT_ISOLATION_ONLY'})
out=ROOT/'assets/review/animations-polished/entities-deformation-verification.json'
out.write_text(json.dumps(results,indent=2),encoding='utf-8')
print('BLENDER_WEIGHT_ISOLATION_PASS',len(results),'NOT_A_PLAY_APPROVAL')
