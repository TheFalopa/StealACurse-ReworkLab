"""Original curved, solid Halloween leaf clumps; no downloaded geometry.

Reuse the established closed-mesh exporter and scale convention, but never
overwrite the prior kit. Blender Z becomes Roblox Y; FBX global_scale=.01.
"""
from pathlib import Path
import importlib.util
import json
import math
import sys

import bpy
import bmesh
from mathutils import Vector

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[3]
EXPORT = ROOT / "assets/export/meshes/foliage_expansion"
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("original_environment_mesh", SOURCE.parent / "generate_final_environment.py")
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
Mesh = helpers.Mesh


def leaf(m, start, heading, length, width, arch, curl, torn=False):
    """Closed two-sided five-station blade with bowed midrib and curled edges.

    The narrow but nonzero ends avoid degenerate triangles. Each leaf is a
    manifold shell; overlapping leaf shells are harmless cosmetic clumps.
    """
    first = len(m.vertices)
    forward = Vector((math.cos(heading), math.sin(heading), 0))
    lateral = Vector((-math.sin(heading), math.cos(heading), 0))
    origin = Vector(start)
    widths = [.035, .74, 1.0, .61, .025]
    if torn:
        widths = [.035, .88, .59, .70, .025]
    for layer in (-1, 1):
        for station, t in enumerate((0, .24, .51, .78, 1)):
            center = origin + forward * length * t + lateral * (curl * t * t)
            center.z += arch * math.sin(math.pi * t) - .8 * t * t
            for edge in (-1, 0, 1):
                p = center + lateral * (edge * width * widths[station])
                p.z += abs(edge) * .24 * math.sin(math.pi*t) + layer * .085
                if torn and edge < 0 and station == 2:
                    p += lateral * (width*.20)
                m.vertices.append(tuple(p))
    # Top and bottom grids, with one continuous perimeter joining the layers.
    for station in range(4):
        for edge in range(2):
            a = first + station*3 + edge
            m.faces.append((a, a+1, a+4, a+3))
            m.faces.append((a+15, a+18, a+19, a+16))
    boundary = [0,1,2,5,8,11,14,13,12,9,6,3]
    for i, vertex in enumerate(boundary):
        nxt = boundary[(i+1)%len(boundary)]
        m.faces.append((first+vertex, first+nxt, first+nxt+15, first+vertex+15))


def crescent():
    m = Mesh()
    for i in range(9):
        angle = -.85 + i*.22
        leaf(m, (-1.4+i*.22, math.sin(i*.7)*.65, (i%3)*.32), angle,
             5.2+(i%3)*.65, .68+(i%2)*.13, .65+(i%3)*.23, .45)
    return m


def tattered():
    m = Mesh()
    for i in range(12):
        angle = i*math.tau/12 + (i%2)*.14
        leaf(m, (math.cos(angle)*.4, math.sin(angle)*.5, (i%3)*.30), angle,
             3.8+(i%4)*.58, .65+(i%3)*.11, .55+(i%3)*.28, (i%2*2-1)*.5, True)
    return m


def swept():
    m = Mesh()
    for i in range(7):
        leaf(m, (-2.0+i*.44, -1.0+i*.37, i*.17), -.12+i*.20,
             4.6+(i%3)*.75, .62+(i%2)*.15, 1.45-(i%3)*.15, -.75)
    return m


KIT = [
    ("foliage_crescent", crescent, (16,10,6), "Asymmetric crescent of nine curved tapered blades"),
    ("foliage_tattered", tattered, (14,12,7), "Twelve layered jagged blades with broken outer contour"),
    ("foliage_swept", swept, (15,9,8), "Sparse swept arch of seven curled blades"),
]


def main():
    EXPORT.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    material = bpy.data.materials.new("Original_Halloween_Foliage")
    material.diffuse_color = (.18,.38,.35,1)
    assets, objects = [], []
    for name, factory, dimensions, purpose in KIT:
        obj = factory().make(name, dimensions)
        obj.data.materials.append(material)
        helpers.verify(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.fbx(filepath=str(EXPORT/(name+".fbx")), use_selection=True,
            global_scale=.01, apply_unit_scale=True, bake_space_transform=False,
            object_types={"MESH"}, add_leaf_bones=False, path_mode="AUTO")
        triangles = len(obj.data.polygons)
        assets.append({"name":name,"fbx":str((EXPORT/(name+".fbx")).relative_to(ROOT)).replace("\\","/"),
            "triangles":triangles,"vertices":len(obj.data.vertices),
            "blender_dimensions":list(dimensions), "expected_roblox_size":[dimensions[0],dimensions[2],dimensions[1]],
            "origin":"bounds_center","materials":1,"purpose":purpose,
            "mesh_id":None,"import_status":"pending_actual_studio_import"})
        objects.append(obj)
        print("FOLIAGE_ASSET",name,"triangles=",triangles)
    manifest={"generator":"assets/source/blender/foliage_expansion/generate_foliage.py",
        "source":"assets/source/blender/foliage_expansion/steal_a_curse_foliage_expansion.blend",
        "original_project_assets":True,"fbx_global_scale":.01,"unique_mesh_count":3,
        "total_unique_triangles":sum(a["triangles"] for a in assets),"assets":assets}
    (SOURCE/"foliage_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    for i,obj in enumerate(objects):
        obj.location=(i*21,0,5)
        bpy.ops.object.text_add(location=(i*21-8,-.6,-1))
        text=bpy.context.object
        text.data.body=obj.name.replace("foliage_","")+f"\n{assets[i]['triangles']} triangles"
        text.data.size=1.05
        text.rotation_euler=(math.pi/2,0,0)
    bpy.ops.object.camera_add(location=(21,-57,39))
    camera=bpy.context.object
    camera.rotation_euler=(Vector((21,0,5))-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=65
    scene=bpy.context.scene
    scene.camera=camera
    scene.render.engine="BLENDER_WORKBENCH"
    scene.display.shading.light="STUDIO"
    scene.display.shading.color_type="MATERIAL"
    scene.display.shading.show_cavity=True
    scene.display.shading.show_shadows=True
    scene.display.shading.background_type="WORLD"
    scene.world.color=(.025,.029,.045)
    scene.render.resolution_x=1600
    scene.render.resolution_y=900
    scene.render.resolution_percentage=100
    scene.render.filepath=str(SOURCE/"foliage_preview.png")
    bpy.ops.render.render(write_still=True)
    gallery=bpy.data.collections.new("Preview_Only")
    scene.collection.children.link(gallery)
    for obj in list(scene.objects):
        if obj not in objects:
            for old in list(obj.users_collection): old.objects.unlink(obj)
            gallery.objects.link(obj)
    gallery.hide_viewport=True
    for index,obj in enumerate(objects):
        obj.location=(0,0,0)
        obj.scale=(1,1,1)
        collection=bpy.data.collections.new("Asset_"+obj.name)
        scene.collection.children.link(collection)
        for old in list(obj.users_collection): old.objects.unlink(obj)
        collection.objects.link(obj)
        collection.hide_viewport=index!=0
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"steal_a_curse_foliage_expansion.blend"))
    print("FOLIAGE_COMPLETE",manifest["total_unique_triangles"])


if __name__=="__main__": main()
