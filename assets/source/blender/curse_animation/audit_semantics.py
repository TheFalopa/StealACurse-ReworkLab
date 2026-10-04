import json,sys
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(HERE));from inspect_sources import sources
sys.path.insert(0,str(ROOT/'assets/source/blender/curses_visual_pass2'))
import author_batch01 as original
sys.path.insert(0,str(ROOT/'assets/source/blender/curses_expansion/rework'))
import rare_models,common_models
def author(id):
    if id in original.ORIGINALS:return original.ORIGINALS[id][2]
    if hasattr(common_models,id):return getattr(common_models,id)
    if id in rare_models.MODELS:return rare_models.MODELS[id]
    return original.high.MODELS[id][3]
def main():
    result=[]
    for row in sources():
        m=original.geo.Sculpt();author(row['id'])(m)
        lo=[min(v[i]for v in m.vertices)for i in range(3)];hi=[max(v[i]for v in m.vertices)for i in range(3)]
        parts=[]
        for i,p in enumerate(m.parts):
            end=m.parts[i+1]['first_face']if i+1<len(m.parts)else len(m.faces)
            inds=set(v for f in m.faces[p['first_face']:end]for v in f)
            if not inds:continue
            vs=[m.vertices[j]for j in inds]
            parts.append({'name':p['name'],'min':[min(v[a]for v in vs)for a in range(3)],'max':[max(v[a]for v in vs)for a in range(3)],'first':p['first_face'],'last':end})
        result.append({'id':row['id'],'min':lo,'max':hi,'parts':parts})
        print(row['id'],json.dumps(parts),flush=True)
    (HERE/'prototype-semantics-56.json').write_text(json.dumps(result,indent=2),encoding='utf8')
if __name__=='__main__':main()
