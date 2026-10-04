import bpy,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for id in ['watching_eye','soul_chains','plague_monarch','the_void']:
    with bpy.data.libraries.load(str(HERE/(id+'.blend')),link=False) as (src,dst):
        dst.objects=[id,id+'_Rig']
    for obj in dst.objects:bpy.context.collection.objects.link(obj)
    obj=bpy.data.objects[id];arm=bpy.data.objects[id+'_Rig']
    print('BINDINGS',id,[(m.object.name,m.object==arm)for m in obj.modifiers if m.type=='ARMATURE'],obj.parent.name,[(g.name,len([v for v in obj.data.vertices if any(x.group==g.index for x in v.groups)]))for g in obj.vertex_groups],flush=True)
