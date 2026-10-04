import bpy, json
from pathlib import Path
from collections import Counter
ROOT=Path(r'C:\RobloxProjects\StealACurse')
rows=[]
for identity in ('night_harp','silent_choir'):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/source/blender/curse_animation'/(identity+'.blend')))
    obj=next(o for o in bpy.data.objects if o.type=='MESH' and o.vertex_groups)
    mesh=obj.data
    adj=[[] for _ in mesh.vertices]
    for edge in mesh.edges:
        a,b=edge.vertices;adj[a].append(b);adj[b].append(a)
    groups={g.index:g.name for g in obj.vertex_groups}
    seen=set();parts=[]
    for i in range(len(adj)):
        if i in seen:continue
        todo=[i];seen.add(i);indices=[]
        while todo:
            a=todo.pop();indices.append(a)
            for b in adj[a]:
                if b not in seen:seen.add(b);todo.append(b)
        lo=[min(mesh.vertices[v].co[a] for v in indices) for a in range(3)]
        hi=[max(mesh.vertices[v].co[a] for v in indices) for a in range(3)]
        weights=Counter()
        for v in indices:
            for g in mesh.vertices[v].groups:
                if g.weight>.15:weights[groups[g.group]]+=1
        parts.append({'index':len(parts),'vertices':len(indices),'min':lo,'max':hi,'weights':dict(weights)})
    rows.append({'id':identity,'components':parts})
(ROOT/'assets/review/animations-polished/entities-components-audit.json').write_text(json.dumps(rows,indent=2))
