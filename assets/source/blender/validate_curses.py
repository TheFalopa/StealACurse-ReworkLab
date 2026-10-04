"""Re-import and validate the six original Curse FBXs with Blender 5.2+."""

from pathlib import Path

import bpy
import bmesh
from mathutils import Vector


EXPORT = Path(__file__).resolve().parents[2] / "export" / "meshes"
# These are authoring dimensions in studs (X, Blender depth/Y, Blender height/Z).
# Blender's FBX round trip retains the established 0.01 export scale; Roblox's
# importer restores the corresponding stud-sized bounds, as with the map kit.
AUTHORING_DIMENSIONS = {
    "cursed_doll": (2.465, 1.047, 3.243),
    "haunted_mirror": (2.658, 0.595, 4.040),
    "crying_mask": (2.110, 0.865, 3.050),
    "watching_eye": (3.816, 1.152, 2.681),
    "soul_chains": (4.020, 0.919, 2.600),
    "the_void": (4.170, 1.667, 4.450),
}


def main():
    for name, authoring_dimensions in AUTHORING_DIMENSIONS.items():
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        path = EXPORT / f"{name}.fbx"
        if not path.is_file():
            raise RuntimeError(f"Missing original Curse export: {path}")
        bpy.ops.import_scene.fbx(filepath=str(path))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        if len(meshes) != 1:
            raise RuntimeError(f"{name}: expected exactly one imported Mesh, got {len(meshes)}")
        obj = meshes[0]
        if obj.name != name:
            raise RuntimeError(f"{name}: imported name was {obj.name}")
        check = bmesh.new()
        check.from_mesh(obj.data)
        open_edges = sum(not edge.is_manifold for edge in check.edges)
        check.free()
        if open_edges:
            raise RuntimeError(f"{name}: imported mesh has {open_edges} non-manifold edges")
        bounds = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        mins = [min(point[axis] for point in bounds) for axis in range(3)]
        maxs = [max(point[axis] for point in bounds) for axis in range(3)]
        center = tuple((lo+hi)/2 for lo, hi in zip(mins, maxs))
        if any(abs(component) > 0.005 for component in center):
            raise RuntimeError(f"{name}: world bounds are not origin-centered: {center}")
        triangles = sum(len(face.vertices)-2 for face in obj.data.polygons)
        dimensions = tuple(round(hi-lo, 3) for lo, hi in zip(mins, maxs))
        for actual, authoring in zip(dimensions, authoring_dimensions):
            if abs(actual-authoring*0.01) > 0.0015:
                raise RuntimeError(f"{name}: unexpected FBX scale {dimensions}")
        print(f"VALIDATED {name} mesh_parts=1 triangles={triangles} "
              f"fbx_dimensions={dimensions} intended_studs={authoring_dimensions} "
              f"center={center} materials={len(obj.data.materials)}")


if __name__ == "__main__":
    main()
