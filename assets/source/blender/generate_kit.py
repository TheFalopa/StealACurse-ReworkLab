"""Generate the original, low-poly Steal A Curse environment mesh kit.

Run with Blender 5.2+ in background mode:
    blender -b --factory-startup --python assets/source/blender/generate_kit.py

One named mesh is exported per file. Dimensions are authored in Roblox studs;
the placement code specifies the final MeshPart size after Studio import.
"""

from pathlib import Path
import math
import tempfile

import bpy
import bmesh
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets" / "source" / "blender"
EXPORT = ROOT / "assets" / "export" / "meshes"
EXPORT.mkdir(parents=True, exist_ok=True)


class Solid:
    def __init__(self):
        self.vertices = []
        self.faces = []

    def tube(self, points, radii, sides=6, phase=0.0):
        """A faceted, tapered tube following a bent polyline."""
        assert len(points) == len(radii) and len(points) >= 2
        first = len(self.vertices)
        centers = [Vector(p) for p in points]
        for index, center in enumerate(centers):
            tangent = centers[min(index + 1, len(centers) - 1)] - centers[max(index - 1, 0)]
            tangent.normalize()
            guide = Vector((0, 1, 0)) if abs(tangent.y) < 0.88 else Vector((1, 0, 0))
            axis_a = tangent.cross(guide).normalized()
            axis_b = tangent.cross(axis_a).normalized()
            for spoke in range(sides):
                theta = phase + 2 * math.pi * spoke / sides
                point = center + radii[index] * (math.cos(theta) * axis_a + math.sin(theta) * axis_b)
                self.vertices.append(tuple(point))
        self.faces.append(tuple(first + spoke for spoke in reversed(range(sides))))
        for ring in range(len(points) - 1):
            for spoke in range(sides):
                a = first + ring * sides + spoke
                b = first + ring * sides + (spoke + 1) % sides
                self.faces.append((a, b, b + sides, a + sides))
        last = first + (len(points) - 1) * sides
        self.faces.append(tuple(last + spoke for spoke in range(sides)))

    def profile(self, outline, depth):
        """Extrude an X/Z silhouette into a closed low-poly stone form."""
        first = len(self.vertices)
        count = len(outline)
        for y in (-depth / 2, depth / 2):
            for x, z in outline:
                self.vertices.append((x, y, z))
        self.faces.append(tuple(first + index for index in reversed(range(count))))
        self.faces.append(tuple(first + count + index for index in range(count)))
        for index in range(count):
            next_index = (index + 1) % count
            self.faces.append((first + index, first + next_index,
                               first + count + next_index, first + count + index))

    def rock(self, lower, upper):
        """A closed, uneven faceted boulder from two matched vertex rings."""
        assert len(lower) == len(upper)
        first = len(self.vertices)
        self.vertices.extend(lower)
        self.vertices.extend(upper)
        count = len(lower)
        self.faces.append(tuple(first + index for index in reversed(range(count))))
        self.faces.append(tuple(first + count + index for index in range(count)))
        for index in range(count):
            nxt = (index + 1) % count
            self.faces.append((first + index, first + nxt, first + count + nxt,
                               first + count + index))

    def add_object(self, name):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def tree_widow():
    solid = Solid()
    solid.tube(
        [(0, 0, 0), (0.3, -0.1, 3.1), (-0.7, 0.5, 8.8),
         (-1.5, 0.2, 14.9), (-2.0, -0.4, 20.7)],
        [2.4, 1.8, 1.25, 0.83, 0.25], 7, 0.12,
    )
    claws = [
        ([(-0.6, 0.2, 8.5), (3.0, 0.7, 12.4), (7.1, -0.7, 14.8),
          (9.5, -1.5, 19.3)], [1.13, 0.78, 0.45, 0.08]),
        ([(-1.0, 0.3, 12.6), (-5.5, 1.2, 15.5), (-9.3, 3.5, 17.0),
          (-10.3, 4.0, 21.7)], [1.08, 0.7, 0.36, 0.07]),
        ([(-1.6, 0.0, 15.4), (-0.5, -4.8, 18.0), (2.0, -7.6, 17.8),
          (2.8, -9.1, 21.4)], [0.9, 0.59, 0.32, 0.06]),
        ([(-1.1, 0.4, 10.6), (-4.4, -4.2, 11.8), (-5.8, -6.5, 15.1)],
         [0.9, 0.53, 0.08]),
    ]
    for points, radii in claws:
        solid.tube(points, radii, 5, 0.32)
    roots = [
        ([(0, 0, 2.0), (3.1, 1.3, 0.55), (6.9, 2.3, 0.05)], [1.23, 0.75, 0.08]),
        ([(0, 0, 1.9), (-3.0, -1.6, 0.45), (-6.8, -2.4, 0.05)], [1.18, 0.7, 0.08]),
        ([(0, 0, 1.8), (0.8, -3.3, 0.55), (2.0, -7.2, 0.05)], [1.09, 0.62, 0.08]),
        ([(0, 0, 1.9), (-1.4, 3.0, 0.45), (-2.2, 6.0, 0.05)], [1.06, 0.57, 0.08]),
    ]
    for points, radii in roots:
        solid.tube(points, radii, 5, 0.16)
    return solid.add_object("Tree_Widow")


def tree_claw():
    solid = Solid()
    solid.tube([(0, 0, 0), (-0.3, 0.3, 3.2), (1.2, 0, 8.2),
                (2.9, -0.7, 12.8), (3.4, -1.4, 16.0)],
               [2.6, 2.0, 1.35, 0.7, 0.14], 7)
    for points, radii in [
        ([(0.4, 0, 6), (-4.2, -0.6, 9.1), (-9.0, -1, 9.5),
          (-13.0, -1.5, 14.8)], [1.4, 0.9, 0.52, 0.06]),
        ([(0.8, 0, 8), (5.6, 0.7, 10.5), (11.2, 1.4, 9.6),
          (14.0, 2.2, 13.8)], [1.28, 0.88, 0.44, 0.06]),
        ([(1.6, 0, 10.7), (-0.2, 4.0, 13.9), (-2.7, 8.2, 14.1),
          (-3.7, 9.1, 18.7)], [1.0, 0.65, 0.37, 0.05]),
        ([(2.1, -0.4, 11), (5.1, -4.6, 12.5), (8.2, -7.4, 11.7),
          (10.4, -8.1, 16.6)], [0.9, 0.61, 0.34, 0.05]),
    ]:
        solid.tube(points, radii, 5, 0.2)
    for points in [
        [(0, 0, 2), (-4, 1.2, 0.6), (-7, 2.0, 0.04)],
        [(0, 0, 2), (4.4, 1.7, 0.5), (8, 2.0, 0.04)],
        [(0, 0, 2), (0.6, -4.1, 0.6), (0.8, -8.0, 0.04)],
    ]:
        solid.tube(points, [1.2, 0.65, 0.07], 5)
    return solid.add_object("Tree_Claw")


def tree_sundered():
    solid = Solid()
    solid.tube([(0, 0, 0), (0.1, 0.1, 3.1), (-0.7, 0, 7.9),
                (-1.5, 0.3, 11.5)], [2.3, 1.8, 1.14, 0.33], 7, 0.15)
    solid.tube([(-0.3, 0, 5.5), (3.4, -1.0, 8.7), (6.9, -0.2, 8.3),
                (8.0, 0, 12.5)], [1.1, 0.62, 0.31, 0.05], 5)
    solid.tube([(-0.7, 0, 8.3), (-4.3, 1.1, 10.2), (-6.2, 2.5, 13.8)],
               [0.93, 0.5, 0.05], 5)
    solid.tube([(0, 0, 1.8), (-3.1, -1.7, 0.5), (-6.5, -2.1, 0.04)],
               [1.1, 0.6, 0.05], 5)
    solid.tube([(0, 0, 1.8), (2.1, 2.6, 0.5), (3.8, 5.1, 0.04)],
               [1.0, 0.55, 0.05], 5)
    return solid.add_object("Tree_Sundered")


def grave_arched():
    solid = Solid()
    solid.profile([(-1.85, 0), (1.85, 0), (1.85, 3.2), (1.5, 4.35),
                   (0.65, 5.0), (-0.55, 5.15), (-1.55, 4.4), (-1.85, 3.2)], 0.9)
    return solid.add_object("Grave_Arched")


def grave_spire():
    solid = Solid()
    solid.profile([(-1.4, 0), (1.45, 0), (1.25, 4.4), (0.95, 5.2),
                   (0.65, 5.7), (0, 7.4), (-0.5, 5.9), (-1.15, 5.1)], 1.25)
    return solid.add_object("Grave_Spire")


def grave_broken():
    solid = Solid()
    solid.profile([(-2.1, 0), (2.0, 0), (1.9, 2.5), (0.9, 3.45),
                   (0.4, 2.9), (-0.4, 3.7), (-1.25, 3.15), (-1.9, 3.4)], 1.1)
    return solid.add_object("Grave_Broken")


def rock_crag():
    solid = Solid()
    lower = []
    upper = []
    for index in range(7):
        angle = 2 * math.pi * index / 7
        radius = 3.2 + (index * 3 % 4) * 0.37
        lower.append((math.cos(angle) * radius, math.sin(angle) * radius * 0.8, 0))
        upper.append((math.cos(angle) * radius * 0.66 + (index % 2) * 0.3,
                      math.sin(angle) * radius * 0.6, 3.8 + index % 3 * 0.55))
    solid.rock(lower, upper)
    return solid.add_object("Rock_Crag")


def root_serpent():
    solid = Solid()
    solid.tube([(-5, 0, 0.1), (-3.3, 0.3, 1.6), (-0.7, -0.3, 2.4),
                (2, 0.8, 1.45), (5.2, 1.3, 0.1)],
               [0.1, 0.65, 1.0, 0.67, 0.07], 6)
    solid.tube([(-0.6, -0.2, 2.1), (0.1, -2.4, 2.6), (2.2, -4.7, 0.07)],
               [0.65, 0.36, 0.05], 5)
    return solid.add_object("Root_Serpent")


def ruin_arch():
    solid = Solid()
    solid.tube([(-6.7, 0, 0), (-6.3, 0, 5.8), (-5.9, 0, 12.4)],
               [1.7, 1.45, 1.2], 4, math.pi / 4)
    solid.tube([(6.7, 0, 0), (6.2, 0, 6.8), (5.8, 0, 12.0)],
               [1.8, 1.42, 1.1], 4, math.pi / 4)
    solid.tube([(-5.9, 0, 12.3), (-3.1, 0, 14.8), (0.2, 0, 17.2)],
               [1.28, 1.07, 0.72], 4, math.pi / 4)
    solid.tube([(5.8, 0, 12.0), (3.2, 0, 14.6), (0.2, 0, 17.2)],
               [1.23, 1.0, 0.72], 4, math.pi / 4)
    return solid.add_object("Ruin_PointArch")


def shrine_reliquary():
    solid = Solid()
    solid.profile([(-5.7, 0), (5.7, 0), (5.8, 2), (4.2, 3),
                   (4.1, 11.2), (2.3, 14.6), (0, 16.4),
                   (-2.6, 14.4), (-4.2, 11.0), (-4.4, 3), (-5.8, 2)], 1.4)
    for x in (-4.9, 4.9):
        solid.tube([(x, -0.3, 0.4), (x, -0.3, 8.8),
                    (x * 0.85, -0.3, 13.4)], [0.95, 0.74, 0.26], 4, math.pi / 4)
    solid.profile([(-1.7, 1.2), (1.7, 1.2), (1.6, 7.9),
                   (0, 9.6), (-1.6, 7.8)], 1.8)
    return solid.add_object("Shrine_Reliquary")


def temple_crest():
    solid = Solid()
    solid.profile([(-4.5, 0), (4.5, 0), (3.5, 4.5), (2.6, 14.5),
                   (1.0, 18.2), (0, 24.2), (-1.5, 18.1),
                   (-3.0, 14.5), (-3.7, 4.5)], 3.2)
    solid.profile([(-4.5, 4.6), (-11.0, 6.1), (-13.6, 12.7),
                   (-9.5, 11.0), (-6.4, 14.3), (-2.9, 13.2)], 1.3)
    solid.profile([(4.5, 4.6), (10.4, 5.7), (13.6, 12.8),
                   (9.5, 10.9), (6.4, 14.3), (2.9, 13.2)], 1.3)
    solid.tube([(0, 0, 23.7), (-0.5, 0, 28.3)], [0.95, 0.06], 5)
    return solid.add_object("Temple_WingCrest")


def stone_warden():
    solid = Solid()
    solid.profile([(-2.2, 0), (2.2, 0), (2.7, 6.8), (1.7, 9.4),
                   (0.9, 10.2), (0, 11.0), (-1.1, 10.2),
                   (-1.8, 9.2), (-2.7, 6.8)], 2.9)
    solid.profile([(-1.9, 7.1), (1.9, 7.1), (2.35, 9.7),
                   (0.3, 12.5), (-2.2, 9.8)], 3.4)
    return solid.add_object("Stone_Warden")


def export_one(obj, filename):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(EXPORT / filename),
        use_selection=True,
        global_scale=0.01,
        apply_unit_scale=True,
        bake_space_transform=False,
        object_types={"MESH"},
        add_leaf_bones=False,
        path_mode="AUTO",
    )


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    kit = [
        (tree_widow, "tree_widow.fbx"),
        (tree_claw, "tree_claw.fbx"),
        (tree_sundered, "tree_sundered.fbx"),
        (grave_arched, "grave_arched.fbx"),
        (grave_spire, "grave_spire.fbx"),
        (grave_broken, "grave_broken.fbx"),
        (rock_crag, "rock_crag.fbx"),
        (root_serpent, "root_serpent.fbx"),
        (ruin_arch, "ruin_point_arch.fbx"),
        (shrine_reliquary, "shrine_reliquary.fbx"),
        (temple_crest, "temple_wing_crest.fbx"),
        (stone_warden, "stone_warden.fbx"),
    ]
    objects = []
    for make, filename in kit:
        obj = make()
        check = bmesh.new()
        check.from_mesh(obj.data)
        open_edges = sum(not edge.is_manifold for edge in check.edges)
        check.free()
        if open_edges:
            raise RuntimeError(f"{obj.name} has {open_edges} non-manifold edges")
        export_one(obj, filename)
        objects.append(obj)
        triangles = sum(len(face.vertices) - 2 for face in obj.data.polygons)
        dims = tuple(round(value, 2) for value in obj.dimensions)
        print(f"ASSET {obj.name} triangles={triangles} dimensions={dims}")
    material = bpy.data.materials.new("Preview_ColdBark")
    material.diffuse_color = (0.22, 0.16, 0.26, 1)
    for obj in objects:
        obj.data.materials.append(material)
    for index, obj in enumerate(objects):
        obj.location.x = (index % 4) * 32
        obj.location.z = (2 - index // 4) * 27
    bpy.ops.object.camera_add(location=(48, -150, 39))
    camera = bpy.context.object
    direction = Vector((48, 0, 39)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 95
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(Path(tempfile.gettempdir()) / "sac_mesh_kit_preview.png")
    bpy.ops.render.render(write_still=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "steal_a_curse_kit.blend"))


if __name__ == "__main__":
    main()
