"""Validate each original final-kit FBX without making or uploading assets."""

from pathlib import Path
import json

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = Path(__file__).with_name("final_environment_manifest.json")


def main():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    total = 0
    for asset in manifest["assets"]:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        bpy.ops.import_scene.fbx(filepath=str(ROOT / asset["fbx"]))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        if len(meshes) != 1 or meshes[0].name != asset["name"]:
            raise RuntimeError(f"{asset['name']}: expected exactly one matching mesh")
        obj = meshes[0]
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bad_edges = sum(not edge.is_manifold for edge in bm.edges)
        degenerates = sum(face.calc_area() < 1e-12 for face in bm.faces)
        bm.free()
        if bad_edges or degenerates:
            raise RuntimeError(f"{obj.name}: bad_edges={bad_edges} degenerates={degenerates}")
        bounds = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        mins = [min(v[axis] for v in bounds) for axis in range(3)]
        maxs = [max(v[axis] for v in bounds) for axis in range(3)]
        dimensions = [hi-lo for lo, hi in zip(mins, maxs)]
        center = [(hi+lo)/2 for lo, hi in zip(mins, maxs)]
        if any(abs(v) > .0001 for v in center):
            raise RuntimeError(f"{obj.name}: FBX bounds are not centered {center}")
        for actual, intended in zip(dimensions, asset["blender_dimensions"]):
            if abs(actual-intended*.01) > .0001:
                raise RuntimeError(f"{obj.name}: export scale mismatch {dimensions}")
        triangles = sum(len(face.vertices)-2 for face in obj.data.polygons)
        if triangles != asset["triangles"]:
            raise RuntimeError(f"{obj.name}: triangle mismatch {triangles}")
        if len(obj.data.materials) != 1:
            raise RuntimeError(f"{obj.name}: expected one material")
        total += triangles
        print(f"VALIDATED_FINAL {obj.name} triangles={triangles} "
              f"fbx_dimensions={tuple(round(v,6) for v in dimensions)} "
              f"expected_studio_size={asset['expected_roblox_size']}")
    if total != manifest["total_unique_triangles"] or total > 8000:
        raise RuntimeError(f"Total triangle budget mismatch {total}")
    print(f"FINAL_VALIDATION_COMPLETE assets={len(manifest['assets'])} triangles={total}")


if __name__ == "__main__":
    main()
