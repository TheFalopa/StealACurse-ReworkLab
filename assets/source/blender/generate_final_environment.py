"""Original final haunted-world modular kit for Steal A Curse.

Blender 5.2+: blender -b --factory-startup --python THIS_FILE
One origin-centered single-material mesh per FBX. Blender dimensions are studs;
the established Studio importer consumes global_scale=.01 exports, Z becoming Y.
No downloaded models, textures, or existing source files are used or overwritten.
"""

from pathlib import Path
import json
import math

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets" / "source" / "blender"
EXPORT = ROOT / "assets" / "export" / "meshes"
SOURCE.mkdir(parents=True, exist_ok=True)
EXPORT.mkdir(parents=True, exist_ok=True)


class Mesh:
    """Closed faceted shells combined into one lightweight reusable module."""

    def __init__(self):
        self.vertices = []
        self.faces = []

    def box(self, center, size):
        x, y, z = center
        a, b, c = (v / 2 for v in size)
        first = len(self.vertices)
        self.vertices.extend([(x-a, y-b, z-c), (x+a, y-b, z-c),
                              (x+a, y+b, z-c), (x-a, y+b, z-c),
                              (x-a, y-b, z+c), (x+a, y-b, z+c),
                              (x+a, y+b, z+c), (x-a, y+b, z+c)])
        self.faces.extend(tuple(first+i for i in f) for f in (
            (3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4),
            (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)))

    def profile(self, outline, depth, y=0):
        first = len(self.vertices)
        count = len(outline)
        for cy in (y-depth/2, y+depth/2):
            self.vertices.extend((x, cy, z) for x, z in outline)
        self.faces.append(tuple(first+i for i in reversed(range(count))))
        self.faces.append(tuple(first+count+i for i in range(count)))
        for i in range(count):
            j = (i+1) % count
            self.faces.append((first+i, first+j, first+count+j, first+count+i))

    def ring_profile(self, outer, inner, depth, y=0):
        """Closed extruded ring; genuinely empty center, no hidden filler."""
        assert len(outer) == len(inner)
        first = len(self.vertices)
        count = len(outer)
        for cy in (y-depth/2, y+depth/2):
            for outline in (outer, inner):
                self.vertices.extend((x, cy, z) for x, z in outline)
        for i in range(count):
            j = (i+1) % count
            a, b = first+i, first+j
            ai, bi = first+count+i, first+count+j
            back = 2*count
            self.faces.extend([(a, ai, bi, b), (a+back, b+back, bi+back, ai+back),
                               (a, b, b+back, a+back), (ai, ai+back, bi+back, bi)])

    def tube(self, points, radii, sides=6, phase=0):
        first = len(self.vertices)
        centers = [Vector(p) for p in points]
        for i, center in enumerate(centers):
            tangent = centers[min(i+1, len(centers)-1)]-centers[max(i-1, 0)]
            tangent.normalize()
            guide = Vector((0, 1, 0)) if abs(tangent.y) < .88 else Vector((1, 0, 0))
            a = tangent.cross(guide).normalized()
            b = tangent.cross(a).normalized()
            for spoke in range(sides):
                theta = phase+math.tau*spoke/sides
                self.vertices.append(tuple(center+radii[i]*(math.cos(theta)*a+math.sin(theta)*b)))
        self.faces.append(tuple(first+i for i in reversed(range(sides))))
        for ring in range(len(points)-1):
            for spoke in range(sides):
                a = first+ring*sides+spoke
                b = first+ring*sides+(spoke+1) % sides
                self.faces.append((a, b, b+sides, a+sides))
        last = first+(len(points)-1)*sides
        self.faces.append(tuple(last+i for i in range(sides)))

    def lathe(self, rings, sides=8, ribbing=0, phase=0):
        """rings = (height, radius), no zero-radius rings to avoid degeneracy."""
        first = len(self.vertices)
        for z, radius in rings:
            for spoke in range(sides):
                theta = phase+math.tau*spoke/sides
                r = radius*(1+ribbing*(1 if spoke % 2 == 0 else -1))
                self.vertices.append((math.cos(theta)*r, math.sin(theta)*r, z))
        self.faces.append(tuple(first+i for i in reversed(range(sides))))
        for ring in range(len(rings)-1):
            for spoke in range(sides):
                a = first+ring*sides+spoke
                b = first+ring*sides+(spoke+1) % sides
                self.faces.append((a, b, b+sides, a+sides))
        last = first+(len(rings)-1)*sides
        self.faces.append(tuple(last+i for i in range(sides)))

    def chain_ring(self, center, major, minor=.14, segments=10, sides=4, twist=False):
        first = len(self.vertices)
        for step in range(segments):
            t = math.tau*step/segments
            radial = Vector((math.cos(t)/major[0], 0, math.sin(t)/major[1])).normalized()
            c = Vector((major[0]*math.cos(t), 0, major[1]*math.sin(t)))
            for spoke in range(sides):
                phi = math.tau*spoke/sides
                p = c+minor*(math.cos(phi)*radial+math.sin(phi)*Vector((0, 1, 0)))
                if twist:
                    p.x, p.y = p.y, p.x
                p += Vector(center)
                self.vertices.append(tuple(p))
        for step in range(segments):
            nxt_step = (step+1) % segments
            for spoke in range(sides):
                nxt = (spoke+1) % sides
                self.faces.append((first+step*sides+spoke, first+step*sides+nxt,
                                   first+nxt_step*sides+nxt, first+nxt_step*sides+spoke))

    def make(self, name, target):
        mins = [min(v[axis] for v in self.vertices) for axis in range(3)]
        maxs = [max(v[axis] for v in self.vertices) for axis in range(3)]
        midpoint = [(lo+hi)/2 for lo, hi in zip(mins, maxs)]
        factors = [target[i]/(maxs[i]-mins[i]) for i in range(3)]
        vertices = [tuple((v[i]-midpoint[i])*factors[i] for i in range(3)) for v in self.vertices]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], self.faces)
        mesh.update()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def gothic_doorway():
    m = Mesh()
    # One continuous U-shaped shell: the open doorway reaches the ground.
    m.profile([(-10, 0), (-10, 16.8), (-7.3, 21), (0, 25), (7.3, 21),
               (10, 16.8), (10, 0), (6.6, 0), (6.6, 15.1), (4.6, 18.3),
               (0, 21.3), (-4.6, 18.3), (-6.6, 15.1), (-6.6, 0)], 2.35)
    # Chunky facets on each column and a proud pointed keystone.
    for x in (-8.3, 8.3):
        m.box((x, -.4, 1.4), (3.4, 3, 2.8))
        m.box((x, -.2, 13.9), (3.25, 2.8, 1.1))
    m.profile([(-1.2, 22), (0, 24.8), (1.2, 22), (0, 21.5)], 3)
    return m


def gothic_window():
    m = Mesh()
    m.ring_profile([(-3, 0), (3, 0), (3, 9), (2.05, 11), (0, 13), (-2.05, 11), (-3, 9)],
                   [(-2.35, .65), (2.35, .65), (2.35, 8.75), (1.55, 10.45),
                    (0, 12.05), (-1.55, 10.45), (-2.35, 8.75)], .8)
    m.box((0, 0, 5.65), (.28, .75, 10))
    m.box((0, 0, 4.5), (4.75, .65, .26))
    m.tube([(-2.2, 0, 8.3), (-1.1, 0, 9.7), (0, 0, 10.1),
            (1.1, 0, 9.7), (2.2, 0, 8.3)], [.13]*5, 4)
    m.box((0, 0, .2), (6, 1, .4))
    return m


def crooked_roof():
    m = Mesh()
    # Canted ridge and overhanging eaves, a reusable silhouette rather than a castle mesh.
    lo = [(-14, -13, 0), (14, -13, 0), (14, 13, 0), (-14, 13, 0)]
    ridge = [(-2, -12, 16.5), (1.6, 9.7, 18)]
    m.vertices.extend(lo+ridge)
    m.faces.extend([(3, 2, 1, 0), (0, 1, 4), (3, 5, 2), (0, 4, 5, 3), (1, 2, 5, 4)])
    # Pronounced rear finial adds a crooked point from any approach.
    m.tube([(1.6, 9.7, 15.7), (2.3, 10.1, 17.4), (2.9, 10.4, 18)], [.5, .27, .035], 5)
    return m


def buttress():
    m = Mesh()
    m.profile([(-2, 0), (2, 0), (2, 4), (1.4, 5), (1.4, 12.5),
               (.8, 14.2), (.8, 18), (-.8, 18), (-.8, 14.2),
               (-1.4, 12.5), (-1.4, 5), (-2, 4)], 3)
    # Projection shaped as a sloped, tapering brace. Blender depth becomes Roblox Z.
    m.vertices.extend([(-1.5, -3.5, 0), (1.5, -3.5, 0),
                       (1.5, .5, 0), (-1.5, .5, 0),
                       (-1.2, -.8, 10), (1.2, -.8, 10),
                       (1.2, .5, 10), (-1.2, .5, 10)])
    n = len(m.vertices)-8
    m.faces.extend(tuple(n+i for i in f) for f in ((3,2,1,0), (4,5,6,7),
                   (0,1,5,4), (1,2,6,5), (2,3,7,6), (3,0,4,7)))
    m.box((0, 0, 16.1), (2.6, 3.6, .8))
    return m


def collection_pedestal():
    m = Mesh()
    m.lathe([(0, 3), (.45, 3), (.6, 2.65), (.7, 2.2),
             (1.8, 2.2), (1.95, 2.65), (2.3, 2.65), (2.5, 3)], 8, phase=math.pi/8)
    # Four projecting ward stones preserve an obvious, broad collection surface.
    for x, y in ((2.5, 0), (-2.5, 0), (0, 2.5), (0, -2.5)):
        m.box((x, y, 1.75), (.55, .55, 1))
    return m


def iron_fence():
    m = Mesh()
    for x in (-5.6, -3.75, -1.9, 0, 1.9, 3.75, 5.6):
        m.tube([(x, 0, .25), (x, 0, 5.65), (x, 0, 6.45), (x, 0, 7)],
               [.14, .14, .33, .018], 4, math.pi/4)
    for z in (1.45, 4.65):
        m.box((0, 0, z), (12, .28, .34))
    for x in (-5.6, 5.6):
        m.box((x, 0, .2), (.7, 1, .4))
    return m


def pumpkin():
    m = Mesh()
    m.lathe([(0, .4), (.22, 1.1), (.65, 1.58), (1.3, 1.72),
             (1.9, 1.55), (2.35, 1.05), (2.5, .36)], 16, .065)
    m.tube([(0, 0, 2.35), (.14, .03, 2.74), (.32, -.08, 3)], [.2, .15, .1], 5)
    return m


def giant_tree():
    m = Mesh()
    m.tube([(0, 0, 0), (1, -.5, 6), (-1.6, .8, 18),
            (-4.4, .1, 31), (-2.3, -1.4, 41), (-5.6, -2.5, 51)],
           [4.8, 3.9, 2.5, 1.8, 1, .16], 8, .15)
    branches = [
        ([(-.7, .4, 17), (7.5, -1, 24), (15, -4.5, 24.5), (20, -5.5, 32), (18.5, -5, 40)], [2.3, 1.65, .9, .46, .07]),
        ([(-3.7, 0, 29), (-11, 1.5, 34), (-16.4, 4, 33.2), (-21, 6, 42), (-19.5, 6, 48)], [1.6, 1.15, .65, .37, .06]),
        ([(-2.4, 0, 32), (-1.5, 6, 38), (4.7, 11, 37), (8.2, 15, 47)], [1.45, 1, .52, .065]),
        ([(-1, 0, 20), (-6.7, -5, 24), (-9.7, -10.5, 30), (-6, -16, 36)], [1.6, 1.05, .55, .065]),
        ([(12, -3.5, 24.3), (12.6, -8, 29), (9.7, -10.5, 34)], [.7, .36, .045]),
        ([(-13, 2.5, 33.5), (-14, -1.7, 41), (-11.5, -3, 45)], [.67, .32, .04]),
        ([(-4.2, .2, 36), (-9, 2, 43), (-10.5, 3, 50)], [1, .44, .045]),
    ]
    for points, radii in branches:
        m.tube(points, radii, 5, .3)
    for x, y in [(10, 2), (-12, -3), (3, -11), (-4, 10), (8, 9)]:
        m.tube([(0, 0, 3), (x*.5, y*.5, .9), (x, y, .07)], [2.15, 1.1, .06], 5)
    return m


def cliff_cluster():
    m = Mesh()
    for cx, cy, height, rx, ry in [(-11, 0, 11, 8, 8), (0, 2, 15, 11, 10),
                                   (12, -1, 9, 7, 8), (-3, -8, 5, 12, 5)]:
        first = len(m.vertices)
        sides = 7
        for z, factor in [(-2, 1), (height*.55, .88), (height, .54)]:
            for i in range(sides):
                t = math.tau*i/sides
                irregular = 1+(i % 3-1)*.11
                m.vertices.append((cx+math.cos(t)*rx*factor*irregular,
                                   cy+math.sin(t)*ry*factor, z-(i % 2)*.7))
        m.faces.append(tuple(first+i for i in reversed(range(sides))))
        for ring in range(2):
            for i in range(sides):
                j = (i+1) % sides
                m.faces.append((first+ring*sides+i, first+ring*sides+j,
                                first+(ring+1)*sides+j, first+(ring+1)*sides+i))
        m.faces.append(tuple(first+2*sides+i for i in range(sides)))
    return m


def hero_grave():
    m = Mesh()
    m.box((0, 0, .6), (7, 3, 1.2))
    m.profile([(-2.7, 1), (2.7, 1), (2.55, 7.7), (1.5, 8.6),
               (0, 11), (-1.5, 8.6), (-2.55, 7.7)], 1.55)
    # Raised ward rune with an actual open eye; can be recolored as one stone module.
    m.ring_profile([(-1.6, 5.9), (0, 7.3), (1.6, 5.9), (0, 4.5)],
                   [(-.9, 5.9), (0, 6.7), (.9, 5.9), (0, 5.1)], .38, -1.02)
    m.box((0, -.94, 3.6), (.38, .34, 2.3))
    for x in (-2.4, 2.4):
        m.tube([(x, -.3, 1.1), (x*.94, -.3, 7.1), (x*.7, -.2, 8.5)], [.27, .21, .06], 4)
    return m


def lantern():
    m = Mesh()
    m.lathe([(0, 1.3), (.2, 1.5), (.4, 1.3)], 6)
    m.lathe([(3.3, 1.3), (3.55, 1.5), (4.4, .4)], 6)
    for i in range(6):
        t = math.tau*i/6
        x, y = math.cos(t)*1.22, math.sin(t)*1.22
        m.tube([(x, y, .35), (x*.95, y*.95, 1.8), (x, y, 3.4)], [.075]*3, 4)
    m.chain_ring((0, 0, 4.62), (.29, .34), .065, 8, 4)
    return m


def chain():
    m = Mesh()
    for i in range(6):
        m.chain_ring((0, 0, .85+i*1.48), (.65, 1), .16, 10, 4, i % 2 == 1)
    return m


KIT = [
    ("final_gothic_doorway", gothic_doorway, (20, 3, 25), "Open pointed manor entrance; clear 13.2-stud opening"),
    ("final_gothic_window", gothic_window, (6, 1, 13), "Hollow lancet frame and restrained tracery"),
    ("final_crooked_roof", crooked_roof, (28, 26, 18), "Steep canted roof with rear finial"),
    ("final_buttress", buttress, (4, 7, 18), "Tiered projecting gothic support"),
    ("final_collection_pedestal", collection_pedestal, (6, 6, 2.5), "Broad octagonal collection dais"),
    ("final_iron_fence", iron_fence, (12, 1, 7), "Open pointed cemetery railing"),
    ("final_pumpkin", pumpkin, (3.5, 3.5, 3), "Ribbed low-poly pumpkin and bent stem"),
    ("final_giant_tree", giant_tree, (40, 30, 52), "Twisted hero tree with silhouette branches and roots"),
    ("final_cliff_cluster", cliff_cluster, (38, 25, 15), "Layered faceted embankment cluster"),
    ("final_hero_grave", hero_grave, (7, 3, 11), "Pointed memorial with open carved ward"),
    ("final_lantern", lantern, (3, 3, 5), "Open hexagonal cage; native flame placed separately"),
    ("final_chain", chain, (2, 1.5, 10), "Six alternating oversized links"),
]


def verify(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    errors = sum(not edge.is_manifold for edge in bm.edges)
    tiny = sum(face.calc_area() < 1e-8 for face in bm.faces)
    bm.free()
    if errors or tiny:
        raise RuntimeError(f"{obj.name}: non_manifold={errors} degenerate_faces={tiny}")
    if obj.location.length > 1e-7 or any(abs(v-1) > 1e-7 for v in obj.scale):
        raise RuntimeError(f"{obj.name}: unapplied transforms")


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    preview_mat = bpy.data.materials.new("FinalKit_PreviewStone")
    preview_mat.diffuse_color = (.45, .47, .63, 1)
    objects, assets, geometry = [], [], {}
    for name, make, dimensions, purpose in KIT:
        obj = make().make(name, dimensions)
        obj.data.materials.append(preview_mat)
        verify(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.fbx(filepath=str(EXPORT / (name+".fbx")),
                                 use_selection=True, global_scale=.01,
                                 apply_unit_scale=True, bake_space_transform=False,
                                 object_types={"MESH"}, add_leaf_bones=False, path_mode="AUTO")
        size = [round(float(v), 6) for v in obj.dimensions]
        triangles = len(obj.data.polygons)
        assets.append({"name": name, "fbx": "assets/export/meshes/"+name+".fbx",
                       "triangles": triangles, "vertices": len(obj.data.vertices),
                       "blender_dimensions": size, "expected_roblox_size": [size[0], size[2], size[1]],
                       "origin": "bounds_center", "materials": 1, "purpose": purpose,
                       "mesh_id": None, "import_status": "pending_actual_studio_import"})
        geometry[name] = {"vertices": [[round(float(v), 7) for v in vertex.co] for vertex in obj.data.vertices],
                          "triangles": [list(face.vertices) for face in obj.data.polygons],
                          "coordinate_system": "Blender_Z_up_studs"}
        objects.append(obj)
        print(f"FINAL_ASSET {name} triangles={triangles} dimensions={size}")
    total = sum(asset["triangles"] for asset in assets)
    if total > 8000:
        raise RuntimeError(f"Kit budget exceeded: {total}")
    manifest = {"generator": "assets/source/blender/generate_final_environment.py",
                "source": "assets/source/blender/steal_a_curse_final_environment.blend",
                "fbx_global_scale": .01, "unique_mesh_count": len(assets),
                "total_unique_triangles": total, "original_project_assets": True, "assets": assets}
    (SOURCE / "final_environment_manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    (SOURCE / "final_environment_geometry.json").write_text(json.dumps(geometry, separators=(",", ":"))+"\n", encoding="utf-8")
    # Render an actual-geometry gallery. Each module is uniformly scaled to fit
    # a common cell; source asset dimensions and exported transforms stay recorded.
    for i, obj in enumerate(objects):
        scale = 15/max(obj.dimensions)
        obj.scale = (scale, scale, scale)
        obj.location = ((i % 4)*22, 0, (2-i // 4)*24+8)
        bpy.ops.object.text_add(location=((i % 4)*22-9, -.6, (2-i // 4)*24-2))
        label = bpy.context.object
        label.name = "PreviewLabel_"+obj.name
        label.data.body = obj.name.removeprefix("final_").replace("_", " ")+f"\n{assets[i]['triangles']} triangles"
        label.data.size = 1.3
        label.rotation_euler = (math.pi/2, 0, 0)
    bpy.ops.object.camera_add(location=(35, -150, 52))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((33, 0, 31))-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 90
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.background_type = "WORLD"
    scene.world.color = (.018, .022, .045)
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 1800
    scene.render.resolution_y = 1550
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(SOURCE / "final_environment_preview.png")
    bpy.ops.render.render(write_still=True)
    # Each source module has its own collection at clean authoring transforms.
    # Show the doorway initially; choose another collection in the Outliner to
    # inspect a different mesh without overlapping modules obscuring its form.
    preview_collection = bpy.data.collections.new("Preview_Only")
    scene.collection.children.link(preview_collection)
    for obj in list(scene.objects):
        if obj not in objects:
            for old in list(obj.users_collection):
                old.objects.unlink(obj)
            preview_collection.objects.link(obj)
    preview_collection.hide_viewport = True
    for index, obj in enumerate(objects):
        obj.location = (0, 0, 0)
        obj.scale = (1, 1, 1)
        obj.hide_render = False
        collection = bpy.data.collections.new("Asset_"+obj.name)
        scene.collection.children.link(collection)
        for old in list(obj.users_collection):
            old.objects.unlink(obj)
        collection.objects.link(obj)
        collection.hide_viewport = index != 0
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = objects[0]
    objects[0].select_set(True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "steal_a_curse_final_environment.blend"))
    print(f"FINAL_KIT_COMPLETE unique_meshes={len(assets)} total_triangles={total}")


if __name__ == "__main__":
    main()
