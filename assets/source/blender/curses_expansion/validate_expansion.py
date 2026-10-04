"""Read-only FBX round-trip checks for wave1; generated reports are evidence.

Run with D:/blender.exe -b --factory-startup --python <this file>.
Checks exact one root, names, manifold shells, finite/centered/scale bounds,
triangle/vertex counts, UVs and exported painted colors. Imported Roblox IDs
are not inferred from these local checks, nor are models enabled by them.
"""
from pathlib import Path
import hashlib
import json
import math

import bpy
import bmesh
from mathutils import Vector

SOURCE=Path(__file__).resolve().parent
ROOT=Path(__file__).resolve().parents[4]


def main():
    source=json.loads((SOURCE/"first_wave_geometry.json").read_text(encoding="utf-8"))
    results=[]
    for expected in source["assets"]:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        path=ROOT/expected["export"]
        if not path.is_file():
            raise RuntimeError(f"Missing export {path}")
        bpy.ops.import_scene.fbx(filepath=str(path))
        meshes=[obj for obj in bpy.context.scene.objects if obj.type=="MESH"]
        if len(meshes)!=1 or meshes[0].name!=expected["id"]:
            raise RuntimeError(f"{expected['id']}: unexpected object roots {[o.name for o in meshes]}")
        obj=meshes[0]
        if obj.parent or obj.modifiers or obj.constraints:
            raise RuntimeError(f"{obj.name}: unexpected parent/modifier/constraint")
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        bad=sum(not edge.is_manifold for edge in bm.edges)
        loose=sum(not v.link_faces for v in bm.verts)
        degenerate=sum(face.calc_area()<1e-13 for face in bm.faces)
        bm.free()
        if bad or loose or degenerate:
            raise RuntimeError(f"{obj.name}: non-manifold={bad} loose={loose} degenerate={degenerate}")
        bounds=[obj.matrix_world@Vector(p) for p in obj.bound_box]
        lower=[min(p[a] for p in bounds) for a in range(3)]
        upper=[max(p[a] for p in bounds) for a in range(3)]
        center=[(lo+hi)*.5 for lo,hi in zip(lower,upper)]
        dimensions=[hi-lo for lo,hi in zip(lower,upper)]
        if not all(math.isfinite(v) for v in dimensions+center) or max(abs(v) for v in center)>1e-5:
            raise RuntimeError(f"{obj.name}: not finite/origin-centered {center}")
        for actual,wanted in zip(dimensions,expected["blenderDimensions"]):
            if abs(actual-wanted*.01)>1e-5:
                raise RuntimeError(f"{obj.name}: unexpected FBX scale {dimensions}")
        triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
        if triangles!=expected["triangles"] or len(obj.data.vertices)!=expected["vertices"]:
            raise RuntimeError(f"{obj.name}: topology changed during FBX export/import")
        if len(obj.data.uv_layers)!=1 or len(obj.data.materials)!=1 or len(obj.data.color_attributes)!=1:
            raise RuntimeError(f"{obj.name}: missing UV/material/painted vertex colors")
        colors=obj.data.color_attributes[0]
        distinct={tuple(round(v,3) for v in c.color_srgb[:3]) for c in colors.data}
        if len(distinct)<10:
            raise RuntimeError(f"{obj.name}: authored color variation was lost ({len(distinct)})")
        result={"id":obj.name,"status":"FBX_ROUND_TRIP_PASS","meshObjects":1,"triangles":triangles,
                "fbxSha256":hashlib.sha256(path.read_bytes()).hexdigest(),
                "vertices":len(obj.data.vertices),"nonManifoldEdges":bad,"looseVertices":loose,
                "degenerateFaces":degenerate,"fbxWorldDimensions":[round(v,8) for v in dimensions],
                "intendedRobloxSize":expected["robloxIntendedSize"],"center":[round(v,9) for v in center],
                "uvLayers":1,"materialSlots":1,"vertexColorLayer":colors.name,
                "distinctQuantizedPaintedColors":len(distinct),"robloxImporterAppearanceVerified":False}
        results.append(result)
        print("CURSE_EXPANSION_VALIDATED",json.dumps(result))
    report={"schemaVersion":1,"status":"FBX_ROUND_TRIP_PASS","assetCount":len(results),
            "sourceTriangles":sum(r["triangles"] for r in results),
            "method":"Blender FBX reimport, actual topology/bounds/color inspection; not Roblox upload or gameplay validation",
            "assets":results}
    (SOURCE/"first_wave_validation.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print("CURSE_EXPANSION_ROUND_TRIP_PASS",len(results),report["sourceTriangles"])


if __name__=="__main__":
    main()
