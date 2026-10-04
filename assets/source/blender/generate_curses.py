"""Generate six original low-poly Curse relics for Steal A Curse.

Run with Blender 5.2.2 LTS:
    D:\\blender.exe -b --factory-startup --python assets/source/blender/generate_curses.py

Each FBX contains exactly one named, closed Mesh object. Mesh vertices are
centered on the origin; geometry dimensions are in Roblox studs and exported
with the same 0.01 FBX scale used by the existing environment kit. Preview
materials are intentionally simple: gameplay applies Roblox-native color,
surface material, lights and VFX to the imported MeshPart templates.
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

PALETTE = {
    "rag": (0.47, 0.36, 0.55, 1),
    "wood": (0.25, 0.16, 0.28, 1),
    "dark": (0.095, 0.055, 0.17, 1),
    "stone": (0.41, 0.41, 0.58, 1),
    "silver": (0.55, 0.66, 0.82, 1),
    "mirror": (0.17, 0.57, 0.67, 1),
    "cyan": (0.3, 0.9, 1, 1),
    "violet": (0.64, 0.25, 1, 1),
    "gold": (0.7, 0.51, 0.79, 1),
}


class MeshBuilder:
    """Append closed geometric shells into one efficient Roblox mesh."""

    def __init__(self):
        self.vertices = []
        self.faces = []
        self.face_materials = []

    def face(self, indices, material):
        self.faces.append(tuple(indices))
        self.face_materials.append(material)

    def box(self, center, size, material):
        x, y, z = center
        a, b, c = (dimension / 2 for dimension in size)
        first = len(self.vertices)
        self.vertices.extend([
            (x-a, y-b, z-c), (x+a, y-b, z-c),
            (x+a, y+b, z-c), (x-a, y+b, z-c),
            (x-a, y-b, z+c), (x+a, y-b, z+c),
            (x+a, y+b, z+c), (x-a, y+b, z+c),
        ])
        for indices in (
            (3, 2, 1, 0), (4, 5, 6, 7),
            (0, 1, 5, 4), (1, 2, 6, 5),
            (2, 3, 7, 6), (3, 0, 4, 7),
        ):
            self.face((first+i for i in indices), material)

    def profile(self, outline, depth, material, center_y=0):
        """Extrude an X/Z silhouette; outline is counter-clockwise from front."""
        first = len(self.vertices)
        count = len(outline)
        for y in (center_y-depth/2, center_y+depth/2):
            self.vertices.extend((x, y, z) for x, z in outline)
        self.face((first+i for i in range(count)), material)
        self.face((first+count+i for i in reversed(range(count))), material)
        for i in range(count):
            j = (i+1) % count
            self.face((first+i, first+count+i, first+count+j, first+j), material)

    def tube(self, points, radii, material, sides=6):
        """Closed faceted tube following a polyline."""
        assert len(points) == len(radii) and len(points) >= 2
        first = len(self.vertices)
        centers = [Vector(point) for point in points]
        for index, center in enumerate(centers):
            tangent = centers[min(index+1, len(centers)-1)] - centers[max(index-1, 0)]
            tangent.normalize()
            guide = Vector((0, 1, 0)) if abs(tangent.y) < 0.88 else Vector((1, 0, 0))
            axis_a = tangent.cross(guide).normalized()
            axis_b = tangent.cross(axis_a).normalized()
            for spoke in range(sides):
                theta = 2*math.pi*spoke/sides
                point = center + radii[index]*(math.cos(theta)*axis_a + math.sin(theta)*axis_b)
                self.vertices.append(tuple(point))
        self.face((first+i for i in reversed(range(sides))), material)
        for ring in range(len(points)-1):
            for spoke in range(sides):
                nxt = (spoke+1) % sides
                self.face((first+ring*sides+spoke, first+ring*sides+nxt,
                           first+(ring+1)*sides+nxt, first+(ring+1)*sides+spoke), material)
        last = first+(len(points)-1)*sides
        self.face((last+i for i in range(sides)), material)

    def ellipsoid(self, center, radii, material, rings=5, sides=10):
        x, y, z = center
        rx, ry, rz = radii
        first = len(self.vertices)
        self.vertices.append((x, y, z-rz))
        for ring in range(1, rings):
            latitude = -math.pi/2 + math.pi*ring/rings
            for spoke in range(sides):
                longitude = 2*math.pi*spoke/sides
                self.vertices.append((
                    x+rx*math.cos(latitude)*math.cos(longitude),
                    y+ry*math.cos(latitude)*math.sin(longitude),
                    z+rz*math.sin(latitude),
                ))
        top = len(self.vertices)
        self.vertices.append((x, y, z+rz))
        for spoke in range(sides):
            nxt = (spoke+1) % sides
            self.face((first, first+1+nxt, first+1+spoke), material)
        for ring in range(rings-2):
            start = first+1+ring*sides
            for spoke in range(sides):
                nxt = (spoke+1) % sides
                self.face((start+spoke, start+nxt,
                           start+sides+nxt, start+sides+spoke), material)
        last = first+1+(rings-2)*sides
        for spoke in range(sides):
            nxt = (spoke+1) % sides
            self.face((last+spoke, last+nxt, top), material)

    def diamond(self, center, radii, material):
        x, y, z = center
        a, b, c = radii
        first = len(self.vertices)
        self.vertices.extend([
            (x-a, y, z), (x+a, y, z), (x, y-b, z),
            (x, y+b, z), (x, y, z-c), (x, y, z+c),
        ])
        for indices in ((4, 2, 0), (4, 1, 2), (4, 3, 1), (4, 0, 3),
                        (5, 0, 2), (5, 2, 1), (5, 1, 3), (5, 3, 0)):
            self.face((first+i for i in indices), material)

    def ring(self, center, major, minor, material, segments=12, sides=5, start=0, sweep=2*math.pi):
        """Faceted elliptical ring in X/Z plane, optionally with open arc ends."""
        cx, cy, cz = center
        closed = abs(sweep-2*math.pi) < 1e-5
        count = segments if closed else segments+1
        first = len(self.vertices)
        for step in range(count):
            t = start + sweep*step/segments
            radial = Vector((math.cos(t)/major[0], 0, math.sin(t)/major[1])).normalized()
            c = Vector((cx+major[0]*math.cos(t), cy, cz+major[1]*math.sin(t)))
            for spoke in range(sides):
                phi = 2*math.pi*spoke/sides
                point = c + minor*(math.cos(phi)*radial + math.sin(phi)*Vector((0, 1, 0)))
                self.vertices.append(tuple(point))
        if not closed:
            self.face((first+i for i in reversed(range(sides))), material)
        for step in range(segments):
            nstep = (step+1) % count
            for spoke in range(sides):
                nxt = (spoke+1) % sides
                self.face((first+step*sides+spoke, first+step*sides+nxt,
                           first+nstep*sides+nxt, first+nstep*sides+spoke), material)
        if not closed:
            last = first+(count-1)*sides
            self.face((last+i for i in range(sides)), material)

    def object(self, name):
        if not self.vertices or not self.faces:
            raise RuntimeError(f"{name} has no geometry")
        mins = [min(v[axis] for v in self.vertices) for axis in range(3)]
        maxs = [max(v[axis] for v in self.vertices) for axis in range(3)]
        midpoint = [(lo+hi)/2 for lo, hi in zip(mins, maxs)]
        centered = [tuple(v[axis]-midpoint[axis] for axis in range(3)) for v in self.vertices]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(centered, [], self.faces)
        mesh.update()
        used = list(dict.fromkeys(self.face_materials))
        for key in used:
            material = bpy.data.materials.get(key)
            if material is None:
                material = bpy.data.materials.new(key)
                material.diffuse_color = PALETTE[key]
            mesh.materials.append(material)
        indices = {key: index for index, key in enumerate(used)}
        for polygon, key in zip(mesh.polygons, self.face_materials):
            polygon.material_index = indices[key]
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def cursed_doll():
    m = MeshBuilder()
    # Button-eyed rag doll: oversized head and uneven stitched skirt.
    m.profile([(-0.59, 0.22), (0.62, 0.22), (0.75, 0.67), (0.45, 1.38),
               (0.25, 1.48), (-0.39, 1.42), (-0.65, 0.65)], 0.48, "rag")
    m.ellipsoid((0, 0, 2.1), (0.78, 0.48, 0.72), "rag", 5, 10)
    m.tube([(-0.48, 0, 1.34), (-1.07, 0.03, 0.96), (-1.12, -0.02, 0.62)],
           [0.18, 0.15, 0.1], "wood", 6)
    m.tube([(0.47, 0, 1.32), (0.98, 0.05, 0.99), (1.17, 0.02, 0.77)],
           [0.18, 0.16, 0.1], "wood", 6)
    m.tube([(-0.29, 0, 0.29), (-0.34, -0.01, -0.22)], [0.18, 0.14], "wood", 6)
    m.tube([(0.27, 0, 0.29), (0.36, 0.01, -0.24)], [0.18, 0.14], "wood", 6)
    m.box((-0.36, -0.51, 2.23), (0.27, 0.13, 0.27), "dark")
    m.ellipsoid((0.34, -0.48, 2.18), (0.19, 0.07, 0.19), "violet", 3, 8)
    for x in (-0.42, -0.3):
        m.tube([(x-0.06, -0.59, 2.16), (x+0.06, -0.59, 2.28)],
               [0.023, 0.023], "silver", 4)
    for a, b in [((-0.3, -0.5, 1.75), (-0.08, -0.56, 1.68)),
                 ((-0.08, -0.56, 1.68), (0.16, -0.56, 1.72)),
                 ((0.16, -0.56, 1.72), (0.35, -0.48, 1.82))]:
        m.tube([a, b], [0.028, 0.028], "dark", 4)
    m.profile([(-0.42, 2.52), (-0.56, 2.91), (-0.19, 2.72),
               (0.02, 2.98), (0.23, 2.7), (0.51, 2.88), (0.49, 2.53)],
              0.34, "wood", 0.18)
    m.diamond((-0.22, -0.32, 0.89), (0.15, 0.06, 0.2), "violet")
    return m.object("cursed_doll")


def haunted_mirror():
    m = MeshBuilder()
    # Crooked gothic handheld relic: frame, inset face, cracks and crown.
    m.profile([(-1.02, 0.52), (1.03, 0.58), (1.22, 2.42),
               (0.69, 3.13), (0.05, 3.47), (-0.74, 3.16), (-1.22, 2.42)],
              0.32, "wood")
    m.profile([(-0.74, 0.82), (0.73, 0.86), (0.91, 2.34),
               (0.54, 2.85), (0.03, 3.14), (-0.55, 2.82), (-0.92, 2.35)],
              0.07, "mirror", -0.21)
    m.tube([(-1.04, -0.24, 0.62), (-1.21, -0.24, 2.41), (-0.71, -0.24, 3.19),
            (0.04, -0.24, 3.5), (0.72, -0.24, 3.18), (1.23, -0.24, 2.42),
            (1.05, -0.24, 0.64)], [0.11]*7, "silver", 6)
    m.tube([(-0.98, -0.24, 0.58), (0.98, -0.24, 0.58)], [0.11, 0.11], "silver", 6)
    m.profile([(-0.2, 0.54), (0.2, 0.54), (0.14, -0.15),
               (0.35, -0.43), (-0.29, -0.43), (-0.1, -0.14)], 0.35, "wood")
    m.diamond((0.04, -0.31, 3.31), (0.19, 0.11, 0.24), "violet")
    for points in [
        [(-0.37, -0.27, 2.86), (-0.1, -0.28, 2.39), (0.15, -0.28, 2.13)],
        [(0.15, -0.28, 2.13), (0.57, -0.28, 1.93), (0.23, -0.28, 1.56)],
        [(-0.1, -0.28, 2.39), (-0.53, -0.28, 2.13), (-0.65, -0.28, 1.69)],
    ]:
        m.tube(points, [0.024]*len(points), "cyan", 4)
    return m.object("haunted_mirror")


def crying_mask():
    m = MeshBuilder()
    # Asymmetric ceremonial face with two highly legible cold tears.
    m.profile([(-0.83, 0.71), (-1.04, 1.58), (-0.88, 2.64),
               (-0.42, 3.08), (0.18, 3.22), (0.84, 2.87), (1.07, 1.75),
               (0.78, 0.78), (0.2, 0.19), (-0.34, 0.25)], 0.55, "stone")
    for x, z, width in [(-0.43, 2.25, 0.3), (0.43, 2.35, 0.27)]:
        m.profile([(x-width, z-0.12), (x, z+0.09), (x+width, z-0.1),
                   (x, z-0.22)], 0.09, "dark", -0.33)
    m.diamond((0.05, -0.41, 1.75), (0.2, 0.18, 0.31), "silver")
    m.profile([(-0.31, 0.98), (0.3, 0.93), (0.13, 0.63), (-0.1, 0.65)],
              0.07, "dark", -0.33)
    for x, high, low in [(-0.46, 2.0, 0.85), (0.47, 2.1, 0.58)]:
        m.tube([(x, -0.38, high), (x-0.04, -0.41, high-0.42),
                (x+0.06, -0.37, low)], [0.08, 0.09, 0.025], "cyan", 5)
    for x in (-0.86, 0.82):
        m.diamond((x, -0.02, 2.94), (0.18, 0.17, 0.3), "violet")
    return m.object("crying_mask")


def watching_eye():
    m = MeshBuilder()
    # Floating neutral eye, not anatomical; interrupted watch-ring silhouette.
    m.ellipsoid((0, 0, 1.46), (1.35, 0.48, 0.71), "stone", 5, 12)
    m.ellipsoid((0.13, -0.47, 1.46), (0.45, 0.13, 0.45), "violet", 4, 10)
    m.ellipsoid((0.13, -0.57, 1.46), (0.2, 0.1, 0.2), "dark", 4, 8)
    m.diamond((0.02, -0.67, 1.59), (0.09, 0.025, 0.11), "cyan")
    for start, sweep in [(-0.18, 1.1), (1.15, 1.0), (2.37, 1.05), (3.72, 1.0), (4.97, 0.99)]:
        m.ring((0, 0.17, 1.46), (1.8, 1.12), 0.085, "silver",
               segments=4, sides=5, start=start, sweep=sweep)
    for x, z in [(-1.79, 1.23), (1.67, 2.21), (0.23, 0.21)]:
        m.diamond((x, 0.08, z), (0.15, 0.11, 0.23), "violet")
    return m.object("watching_eye")


def soul_chains():
    m = MeshBuilder()
    # Three thick oversized links and a central ward, never tiny chain spam.
    m.ring((-1.08, 0, 1.55), (0.69, 1.02), 0.16, "silver", segments=12, sides=6)
    m.ring((0.1, -0.2, 1.55), (0.64, 1.02), 0.17, "stone", segments=12, sides=6)
    m.ring((1.24, 0.03, 1.55), (0.69, 1.02), 0.16, "silver", segments=12, sides=6)
    m.profile([(-0.42, 0.73), (0.43, 0.73), (0.54, 1.45), (0, 2.09),
               (-0.55, 1.43)], 0.49, "wood", -0.35)
    m.diamond((0, -0.66, 1.32), (0.24, 0.09, 0.38), "cyan")
    m.diamond((-0.17, -0.46, 2.4), (0.12, 0.11, 0.3), "violet")
    m.diamond((0.32, -0.42, 0.39), (0.13, 0.09, 0.25), "violet")
    return m.object("soul_chains")


def the_void():
    m = MeshBuilder()
    # Broken obsidian shell around an impossible violet core.
    m.ellipsoid((0, 0, 1.92), (0.93, 0.87, 0.93), "dark", 5, 10)
    m.ellipsoid((0, -0.68, 1.9), (0.42, 0.2, 0.51), "violet", 4, 8)
    for start, sweep in [(-0.13, 1.06), (1.27, 0.85), (2.46, 0.93),
                         (3.72, 0.84), (4.92, 1.0)]:
        m.ring((0, 0.13, 1.92), (1.58, 1.44), 0.13, "stone",
               segments=4, sides=5, start=start, sweep=sweep)
    for x, y, z, radii in [
        (-1.62, -0.16, 3.22, (0.22, 0.22, 0.39)),
        (1.45, 0.3, 0.58, (0.26, 0.2, 0.42)),
        (0.11, 0.2, 3.7, (0.3, 0.2, 0.48)),
        (-1.85, 0.25, 1.45, (0.2, 0.17, 0.32)),
        (1.88, -0.12, 2.65, (0.24, 0.19, 0.34)),
    ]:
        m.diamond((x, y, z), radii, "dark")
    for x in (-0.38, 0.37):
        m.diamond((x, -0.47, 0.15), (0.19, 0.14, 0.42), "violet")
    return m.object("the_void")


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
        (cursed_doll, "cursed_doll.fbx"),
        (haunted_mirror, "haunted_mirror.fbx"),
        (crying_mask, "crying_mask.fbx"),
        (watching_eye, "watching_eye.fbx"),
        (soul_chains, "soul_chains.fbx"),
        (the_void, "the_void.fbx"),
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
        triangles = sum(len(face.vertices)-2 for face in obj.data.polygons)
        dims = tuple(round(value, 3) for value in obj.dimensions)
        print(f"CURSE_ASSET {obj.name} triangles={triangles} dimensions={dims} "
              f"materials={len(obj.data.materials)}")

    # Gallery layout exists only in the source .blend, after origin-centered exports.
    for index, obj in enumerate(objects):
        obj.location = ((index % 3)*5, 0, (1-index // 3)*5)
    bpy.ops.object.camera_add(location=(7.5, -25, 11))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((5, 0, 2)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 17
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.render.resolution_x = 1500
    scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(Path(tempfile.gettempdir()) / "sac_curse_kit_preview.png")
    bpy.ops.render.render(write_still=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "steal_a_curse_curses.blend"))


if __name__ == "__main__":
    main()
