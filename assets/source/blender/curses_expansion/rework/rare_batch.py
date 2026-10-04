"""Exact Rare component batching, round-trip verification and geometry gallery.

Loads the final individual FBXs, compensates their established .01 export
scale, and exports a real 14-object FBX. Does not join roots or re-export any
individual file. Gallery is rendered from the editable final model geometry.
"""
from pathlib import Path
import hashlib
import json
import math
import sys

import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from rework_geometry import ROOT, EXPORT, reset, check_mesh


def bounds(obj):
    points = [obj.matrix_world @ Vector(point) for point in obj.bound_box]
    low = [min(p[axis] for p in points) for axis in range(3)]
    high = [max(p[axis] for p in points) for axis in range(3)]
    return [hi - lo for lo, hi in zip(low, high)], [(lo + hi) / 2 for lo, hi in zip(low, high)]


def mesh_stats(obj):
    dims, center = bounds(obj)
    colors = obj.data.color_attributes.get('SACPaintedColor')
    if not colors:
        raise RuntimeError(obj.name + ' lacks authored colors')
    painted = len({tuple(round(float(c) * 255) for c in pixel.color_srgb) for pixel in colors.data})
    return dict(check_mesh(obj), dimensions=dims, center=center, triangles=len(obj.data.polygons),
                vertices=len(obj.data.vertices), paintedColors=painted, uvLayers=len(obj.data.uv_layers))


def geometry_signature(obj):
    vertices = sorted(tuple(round(float(c), 7) for c in obj.matrix_world @ v.co) for v in obj.data.vertices)
    return hashlib.sha256(json.dumps(vertices, separators=(',', ':')).encode()).hexdigest()


def create_batch(rows):
    reset()
    roots = []; individual = {}
    vertex_coordinates = {}
    for row in rows:
        bpy.ops.import_scene.fbx(filepath=str(ROOT / row['export']))
        obj = bpy.data.objects[row['id']]
        individual[row['id']] = dict(mesh_stats(obj), geometrySignature=geometry_signature(obj),
            individualFBXSha256=hashlib.sha256((ROOT / row['export']).read_bytes()).hexdigest(),
            intendedRobloxSize=row['robloxIntendedSize'])
        vertex_coordinates[row['id']] = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
        # Undo only the individual file's .01 exporter scaling. Batch exports
        # with the same .01 convention exactly once.
        obj.scale *= 100
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        roots.append(obj)
    if len(roots) != 14:
        raise RuntimeError('Rare batch requires exactly 14 final roots')
    bpy.ops.object.select_all(action='DESELECT')
    for obj in roots:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = roots[0]
    path = EXPORT / 'rare_import_batch.fbx'
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, global_scale=.01,
        apply_unit_scale=True, bake_space_transform=False, object_types={'MESH'}, add_leaf_bones=False,
        path_mode='AUTO', use_mesh_modifiers=True, colors_type='SRGB')
    reset(); bpy.ops.import_scene.fbx(filepath=str(path))
    imported = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    if {obj.name for obj in imported} != {row['id'] for row in rows}:
        raise RuntimeError('Batch names or root count differ from individual source files')
    components = []
    for obj in imported:
        after = mesh_stats(obj); before = individual[obj.name]
        if any(abs(a - b) > .0000001 for a, b in zip(after['dimensions'], before['dimensions'])):
            raise RuntimeError(obj.name + ' batch dimensions differ')
        if any(abs(c) > .0000001 for c in after['center']):
            raise RuntimeError(obj.name + ' batch origin is displaced')
        for key in ['triangles', 'vertices', 'paintedColors', 'uvLayers']:
            if after[key] != before[key]:
                raise RuntimeError(obj.name + ' batch ' + key + ' differs')
        signature = geometry_signature(obj)
        # FBX uses float32; the scale restore/export can move a coordinate by
        # a few nanometers at its file scale. Compare the actual full vertex
        # set at 1e-7 rather than comparing rounded strings at a boundary.
        tree = KDTree(len(vertex_coordinates[obj.name]))
        for index, vertex in enumerate(vertex_coordinates[obj.name]):
            tree.insert(vertex, index)
        tree.balance()
        max_delta = max(tree.find(obj.matrix_world @ vertex.co)[2] for vertex in obj.data.vertices)
        if max_delta > .0000001:
            raise RuntimeError(obj.name + ' batch vertex geometry differs by ' + str(max_delta))
        components.append(dict(after, id=obj.name, status='EXACT_COMPONENT_ROUND_TRIP_PASS',
            individualFBXSha256=before['individualFBXSha256'], sourceGeometrySignature=before['geometrySignature'],
            batchGeometrySignature=signature, maximumWorldVertexDelta=max_delta, vertexComparisonTolerance=.0000001,
            intendedRobloxSize=before['intendedRobloxSize']))
    report = {'status': 'BATCH_ROUND_TRIP_PASS', 'batch': str(path.relative_to(ROOT)).replace('\\', '/'),
        'batchSha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'componentCount': len(components),
        'scaleConvention': 'Individual .01 export restored by 100 before one .01 batch export; exact world dimensions compared.',
        'components': components, 'realImportRecorded': False}
    (HERE / 'rare_import_batch_validation.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print('RARE_BATCH_PASS ' + str(len(components)) + ' exact components', flush=True)


def create_gallery(rows, rear=False):
    reset()
    text_mat = bpy.data.materials.new('Rare gallery caption')
    text_mat.diffuse_color = (.72, .71, .64, 1)
    text_mat.use_nodes = True
    text_mat.node_tree.nodes.clear()
    shader = text_mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    output = text_mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    text_mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    shader.inputs['Base Color'].default_value = (.72, .71, .64, 1)
    shader.inputs['Emission Color'].default_value = (.72, .71, .64, 1)
    shader.inputs['Emission Strength'].default_value = .5
    order = ['marrow_dice', 'veil_mourner', 'grave_compass', 'hollow_violin', 'chime_triplets',
             'thimble_spider', 'music_box_dancer', 'raven_quill', 'sorrow_chalice', 'pale_gramophone',
             'thorn_reliquary', 'anchor_crab', 'sundial_sentinel', 'sleepwalker_shoes']
    rows_by_id = {row['id']: row for row in rows}
    for index, identity in enumerate(order):
        row = rows_by_id[identity]
        with bpy.data.libraries.load(str(ROOT / row['blendSource']), link=False) as (available, requested):
            requested.objects = [identity]
        obj = requested.objects[0]
        bpy.context.collection.objects.link(obj)
        x = (index % 4) * 5.4
        base = (3 - index // 4) * 5.3 + .75
        obj.rotation_euler.z = .27
        obj.location = (x, 0, base + obj.dimensions.z / 2)
        bpy.ops.object.text_add(location=(x, .9 if rear else -.9, base - .42),
            rotation=(math.pi / 2, 0, math.pi if rear else 0))
        caption = bpy.context.object
        caption.data.body = row['displayName']
        caption.data.size = .26; caption.data.align_x = 'CENTER'
        caption.data.materials.append(text_mat)
    center = Vector((8.1, 0, 10.2))
    bpy.ops.object.camera_add(location=center+Vector((0, 60 if rear else -60, .01)))
    camera = bpy.context.object
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'; camera.data.ortho_scale = 22.8
    scene = bpy.context.scene; scene.camera = camera
    for position, energy, size in [((1,-12,25),25000,14), ((22,-10,12),18000,14), ((8,9,22),25000,15)]:
        if rear:
            position = (position[0], -position[1], position[2])
        bpy.ops.object.light_add(type='AREA', location=position)
        light = bpy.context.object
        light.data.energy = energy; light.data.size = size
        light.rotation_euler = (center-light.location).to_track_quat('-Z', 'Y').to_euler()
    scene.world.color = (.035, .035, .045)
    scene.render.engine = 'CYCLES'; scene.cycles.samples = 32
    scene.render.resolution_x = 2200; scene.render.resolution_y = 2100
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'Standard'; scene.view_settings.exposure = -.65
    name = 'rare_gallery_rear' if rear else 'rare_gallery'
    scene.render.filepath = str(HERE / (name + '.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / (name + '.blend')))
    bpy.ops.render.render(write_still=True)
    print('RARE_GEOMETRY_GALLERY_RENDERED', flush=True)


if __name__ == '__main__':
    rows = json.loads((HERE / 'rare_geometry.json').read_text(encoding='utf-8'))['assets']
    if '--gallery' not in sys.argv:
        create_batch(rows)
    create_gallery(rows, rear='--rear' in sys.argv)
