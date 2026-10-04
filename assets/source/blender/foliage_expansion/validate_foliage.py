"""Read-only original foliage FBX reimport and geometry-contract validation."""
from pathlib import Path
import json
import bpy
import bmesh
from mathutils import Vector

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[3]

def main():
    manifest=json.loads((SOURCE/"foliage_manifest.json").read_text(encoding="utf-8"))
    total=0
    for asset in manifest["assets"]:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        bpy.ops.import_scene.fbx(filepath=str(ROOT/asset["fbx"]))
        objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
        assert len(objects)==1 and objects[0].name==asset["name"],asset["name"]
        obj=objects[0]
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        assert all(e.is_manifold for e in bm.edges),asset["name"]+" nonmanifold"
        assert all(f.calc_area()>1e-12 for f in bm.faces),asset["name"]+" degenerate"
        bm.free()
        bounds=[obj.matrix_world@Vector(c) for c in obj.bound_box]
        for axis,wanted in enumerate(asset["blender_dimensions"]):
            lo=min(p[axis] for p in bounds)
            hi=max(p[axis] for p in bounds)
            assert abs(hi-lo-wanted*.01)<.0001,(asset["name"],axis,lo,hi)
            assert abs((hi+lo)*.5)<.0001,asset["name"]+" origin"
        triangles=sum(len(f.vertices)-2 for f in obj.data.polygons)
        assert triangles==asset["triangles"] and len(obj.data.materials)==1,asset["name"]
        total+=triangles
        print("VALIDATED_FOLIAGE",asset["name"],triangles)
    assert total==manifest["total_unique_triangles"] and total<3000,total
    print("FOLIAGE_VALIDATION_COMPLETE",len(manifest["assets"]),total)

if __name__=="__main__": main()
