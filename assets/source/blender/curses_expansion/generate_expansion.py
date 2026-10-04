"""Original, game-ready first wave from Steal A Curse's concept references.

Run: D:/blender.exe -b --factory-startup --python <this file>
Fifteen single-root meshes, shared original painted vertex-color materials, and
reproducible .blend sources. No existing source/export is overwritten.
Blender Z is height; all exported bounds are centered at the origin. The
established FBX .01 scale is retained and recorded, never guessed in Studio.
"""
from pathlib import Path
import importlib.util
import json
import math
import sys

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[4]
SOURCE = Path(__file__).resolve().parent
EXPORT = ROOT / "assets" / "export" / "meshes" / "curses"
EXPORT.mkdir(parents=True, exist_ok=True)
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("legacy_curse_geometry", SOURCE.parent / "generate_curses.py")
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)

PALETTE = {
    "bone": (0.79, 0.70, 0.48), "wax": (0.90, 0.77, 0.48),
    "stone": (0.38, 0.39, 0.43), "moss": (0.35, 0.45, 0.17),
    "iron": (0.20, 0.24, 0.30), "wood": (0.36, 0.19, 0.12),
    "paper": (0.81, 0.69, 0.45), "ink": (0.045, 0.055, 0.08),
    "gold": (0.70, 0.49, 0.21), "cyan": (0.25, 0.83, 0.91),
    "red": (0.60, 0.085, 0.14), "violet": (0.38, 0.25, 0.56),
    "green": (0.24, 0.42, 0.35), "cloth": (0.22, 0.20, 0.28),
    "glass": (0.28, 0.45, 0.49), "bark": (0.22, 0.27, 0.18),
}
NAMES = list(PALETTE)
WAVE = [
    ("candle_wisp", "Candle Wisp", "COMMON"),
    ("grave_hopper", "Grave Hopper", "COMMON"),
    ("grave_key", "Grave Key", "COMMON"),
    ("ink_imp", "Ink Imp", "COMMON"),
    ("ashen_book", "Ashen Book", "COMMON"),
    ("marrow_dice", "Marrow Dice", "RARE"),
    ("grave_compass", "Grave Compass", "RARE"),
    ("hollow_violin", "Hollow Violin", "RARE"),
    ("raven_quill", "Raven Quill", "RARE"),
    ("night_harp", "Night Harp", "LEGENDARY"),
    ("thorn_cathedral", "Thorn Cathedral", "LEGENDARY"),
    ("judgement_scales", "Judgement Scales", "LEGENDARY"),
    ("cathedral_heart", "Cathedral Heart", "MYTHIC"),
    ("hollow_throne", "Hollow Throne", "MYTHIC"),
    ("nameless_door", "Nameless Door", "SECRET"),
]


def create_material():
    """Preview the same original per-corner colors carried by the FBX meshes.

    The official Studio Importer supports FBX vertex colors. Actual import
    appearance must still be checked before claiming production readiness.
    No texture ID is needed or invented by this source pipeline.
    """
    material = bpy.data.materials.new("SAC_CursePaintedVertexColor")
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 0.83
    paint = material.node_tree.nodes.new("ShaderNodeVertexColor")
    paint.layer_name = "SACPaintedColor"
    material.node_tree.links.new(paint.outputs["Color"], shader.inputs["Base Color"])
    material.diffuse_color = (1, 1, 1, 1)
    return material


class Builder(legacy.MeshBuilder):
    """Closed shells with beveled masses, authored ribbons and volume profiles."""
    def bevel_box(self, center, size, material, bevel=0.10):
        # Small applied bevels on closed cuboids, no expensive runtime modifiers.
        start_face = len(self.faces)
        start_vertex = len(self.vertices)
        self.box(center, size, material)
        verts = self.vertices[start_vertex:]
        faces = [tuple(i-start_vertex for i in f) for f in self.faces[start_face:]]
        bm = bmesh.new()
        bv = [bm.verts.new(v) for v in verts]
        for f in faces:
            bm.faces.new([bv[i] for i in f])
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size)*0.22), segments=1, affect="EDGES")
        bm.verts.ensure_lookup_table()
        bm.verts.index_update()
        del self.vertices[start_vertex:]
        del self.faces[start_face:]
        del self.face_materials[start_face:]
        self.vertices.extend(tuple(v.co) for v in bm.verts)
        for f in bm.faces:
            self.face((start_vertex+v.index for v in f.verts), material)
        bm.free()

    def lathe(self, center, profile, material, sides=12, wobble=0):
        cx, cy, cz = center
        start = len(self.vertices)
        for level, (height, radius) in enumerate(profile):
            for spoke in range(sides):
                angle = spoke * math.tau / sides
                varied = radius * (1 + wobble * math.sin(spoke*2.1 + level*0.7))
                self.vertices.append((cx+varied*math.cos(angle), cy+varied*math.sin(angle), cz+height))
        self.face((start+i for i in reversed(range(sides))), material)
        for level in range(len(profile)-1):
            for spoke in range(sides):
                nxt = (spoke+1) % sides
                self.face((start+level*sides+spoke, start+level*sides+nxt,
                           start+(level+1)*sides+nxt, start+(level+1)*sides+spoke), material)
        top = start+(len(profile)-1)*sides
        self.face((top+i for i in range(sides)), material)

    def ribbon(self, points, widths, material, thickness=0.07):
        # A curved cloth/leaf volume with closed edge walls, not a double-sided card.
        start = len(self.vertices)
        for (x, y, z), width in zip(points, widths):
            self.vertices.extend([(x-width/2, y-thickness/2, z), (x+width/2, y-thickness/2, z),
                                  (x-width/2, y+thickness/2, z), (x+width/2, y+thickness/2, z)])
        self.face((start, start+2, start+3, start+1), material)
        for level in range(len(points)-1):
            a, b = start+level*4, start+(level+1)*4
            for indices in ((a,a+1,b+1,b), (a+3,a+2,b+2,b+3),
                            (a+2,a,b,b+2), (a+1,a+3,b+3,b+1)):
                self.face(indices, material)
        a = start+(len(points)-1)*4
        self.face((a,a+1,a+3,a+2), material)

    def object(self, name, material):
        mins = [min(v[a] for v in self.vertices) for a in range(3)]
        maxs = [max(v[a] for v in self.vertices) for a in range(3)]
        self.offset = [(lo+hi)*0.5 for lo, hi in zip(mins, maxs)]
        positions = [tuple(v[a]-self.offset[a] for a in range(3)) for v in self.vertices]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(positions, [], self.faces)
        mesh.update()
        mesh.materials.append(material)
        uv = mesh.uv_layers.new(name="CurseMaterialUV")
        colors = mesh.color_attributes.new(name="SACPaintedColor",type="BYTE_COLOR",domain="CORNER")
        mesh.color_attributes.active_color = colors
        for polygon, key in zip(mesh.polygons, self.face_materials):
            tile = NAMES.index(key)
            # Dominant-normal planar unwrap within each material tile. Broad
            # painted changes span whole surfaces, not one repeated tiny fleck.
            normal = polygon.normal
            dominant = max(range(3), key=lambda a: abs(normal[a]))
            axes = [a for a in range(3) if a != dominant]
            for loop_index in polygon.loop_indices:
                vertex = mesh.vertices[mesh.loops[loop_index].vertex_index].co
                u = (vertex[axes[0]]+self.offset[axes[0]]-mins[axes[0]]) / max(0.001,maxs[axes[0]]-mins[axes[0]])
                v = (vertex[axes[1]]+self.offset[axes[1]]-mins[axes[1]]) / max(0.001,maxs[axes[1]]-mins[axes[1]])
                uv.data[loop_index].uv = ((tile % 4 + 0.04 + u*0.92)/4, (tile // 4 + 0.04 + v*0.92)/4)
                height = (vertex.z+self.offset[2]-mins[2]) / max(.001,maxs[2]-mins[2])
                broad = .88+.17*height+.035*math.sin(u*4.2+v*2.7+tile)
                edge = .04*max(0,normal.z) if key in {"bone","gold","stone","wood","paper","iron"} else 0
                colors.data[loop_index].color_srgb = tuple(min(1,c*broad+edge) for c in PALETTE[key])+(1,)
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


def eyes(m, x, y, z, spacing=0.25, radius=0.16, material="bone"):
    for side in (-1,1):
        m.ellipsoid((x+side*spacing,y,z), (radius,0.07,radius*1.18), material, 4,10)


def candle_wisp(m):
    m.lathe((0,0,0), [(0,0.70),(0.12,0.79),(0.4,0.60),(0.85,0.53),(1.35,0.56),(1.75,0.43),(2.0,0.27)], "wax", 14,0.10)
    for side in (-1,1):
        m.tube([(side*.4,0,1.3),(side*.76,-.02,.95),(side*.9,-.12,.45)], [.23,.20,.14],"wax",8)
        m.ellipsoid((side*.49,-.05,.15),(.34,.31,.16),"wax",4,10)
    eyes(m,0,-.48,1.24,.23,.15,"ink")
    # Irregular melted crown and asymmetrical hanging drips.
    for x,z,depth in [(-.36,1.68,.43),(.25,1.80,.33),(.48,1.40,.28),(-.09,1.86,.24)]:
        m.tube([(x,-.25,z+.20),(x-.05,-.49,z),(x+.02,-.50,z-depth)], [.13,.12,.07],"wax",7)
    m.tube([(0,0,1.97),(.14,0,2.19),(.25,0,2.40),(.16,.02,2.67),(.30,0,2.99)], [.15,.23,.18,.10,.012],"cyan",9)
    return {"profile":"ghost_flame","glow":"cyan","hook":(0,-.03,2.43)}


def grave_hopper(m):
    m.ellipsoid((0,0,.74),(.95,.65,.67),"stone",6,14)
    m.profile([(-.63,.65),(-.56,.30),(.36,.24),(.69,.62),(.42,.80),(-.2,.73)],.08,"ink",-.59)
    for side in (-1,1):
        m.ellipsoid((side*.75,-.19,.23),(.39,.47,.27),"stone",5,10)
        m.tube([(side*.59,.18,.62),(side*1.0,.38,.38),(side*.97,-.12,.11)],[.23,.21,.17],"stone",7)
    m.profile([(-.70,1.04),(.70,1.04),(.77,1.91),(.56,2.35),(0,2.52),(-.52,2.32),(-.74,1.90)],.34,"stone",.26)
    m.bevel_box((0,.05,1.86),(.17,.13,.68),"moss",.03)
    m.bevel_box((0,-.025,1.97),(.56,.13,.14),"moss",.03)
    for x,y,z in [(-.60,-.12,1.04),(.55,.01,1.25),(-.43,.10,2.22),(.46,.10,2.1)]:
        m.ellipsoid((x,y,z),(.24,.18,.13),"moss",3,7)
    m.tube([(-.45,-.46,1.16),(-.52,-.62,1.03),(-.68,-.52,.94)],[.034]*3,"iron",4)
    return {"profile":"moss_relic","glow":"green","hook":(0,-.38,.90)}


def grave_key(m):
    m.ring((0,0,2.2),(.61,.64),.15,"iron",16,6,start=.1,sweep=5.8)
    m.tube([(.18,0,1.7),(.49,0,.95),(.67,0,.27)],[.13,.15,.14],"iron",8)
    for x,z,width in [(.45,.48,.35),(.73,.26,.43)]:
        m.bevel_box((x,-.01,z),(width,.24,.16),"iron",.03)
    m.tube([(-.15,0,1.65),(.17,0,1.72),(.41,0,1.55)],[.18,.20,.13],"glass",7)
    m.ribbon([(.16,-.16,1.63),(-.09,-.22,1.31),(-.32,-.12,.96),(-.62,-.05,.78)],[.34,.3,.24,.05],"glass")
    m.ribbon([(.30,.12,1.57),(.10,.18,1.15),(.34,.14,.79),(.28,.10,.58)],[.27,.26,.14,.06],"glass")
    m.bevel_box((-.26,-.145,2.54),(.22,.06,.11),"gold",.02)
    return {"profile":"relic_glint","glow":"cyan","hook":(0,-.04,2.2)}


def ink_imp(m):
    m.bevel_box((0,0,.56),(1.73,.41,1.10),"paper",.055)
    m.profile([(-.87,.12),(0,.66),(.87,.12)],.05,"paper",-.26)
    m.profile([(-.82,1.04),(.82,1.04),(0,.42)],.04,"bone",-.245)
    m.ellipsoid((0,-.295,.54),(.16,.045,.16),"red",4,10)
    m.ellipsoid((0,.03,1.30),(.60,.41,.54),"ink",6,14)
    eyes(m,0,-.36,1.34,.25,.145)
    for side in (-1,1):
        m.profile([(side*.26,1.70),(side*.74,2.16),(side*.66,1.55)],.21,"paper",.10)
        m.tube([(side*.48,.06,1.11),(side*.83,-.01,1.07),(side*.97,-.18,1.24)],[.13,.14,.035],"ink",7)
    m.tube([(-.47,.21,1.40),(-.78,.16,1.71),(-1.0,.08,1.76),(-1.12,.01,1.54),(-1.02,-.01,1.40)],[.16,.12,.10,.08,.02],"ink",7)
    m.ellipsoid((.97,0,.55),(.12,.16,.25),"ink",4,8)
    return {"profile":"ink_eyes","glow":"bone","hook":(0,-.42,1.34)}


def ashen_book(m):
    m.bevel_box((0,0,.71),(1.76,1.10,.53),"paper",.05)
    m.bevel_box((0,0,.44),(1.91,1.22,.13),"iron",.04)
    # Open angular roof/book cover; legs built from stacked page scraps.
    m.profile([(-.98,.90),(0,1.69),(.89,1.04),(.87,.86),(0,1.43),(-.94,.70)],.92,"iron",.17)
    m.profile([(-.13,1.44),(.21,1.77),(.45,1.53),(.81,1.74),(.67,1.24),(.46,1.02),(.20,1.22)],.10,"paper",-.43)
    m.profile([(-.62,.83),(.58,.83),(.12,1.30),(-.20,1.36)],.055,"ink",-.58)
    eyes(m,0,-.63,.99,.23,.13)
    for side in (-1,1):
        for i in range(3):
            m.bevel_box((side*.56,-.22-i*.015,.15+i*.09),(.43+.04*i,.61,.075),"paper",.02)
    for z in (.61,.73,.83):
        m.tube([(-.80,-.56,z),(-.3,-.58,z+.01),(.67,-.57,z-.015)],[.016]*3,"wood",4)
    m.tube([(-.60,-.43,1.17),(-.20,-.44,1.51),(.01,-.45,1.4)],[.027]*3,"gold",4)
    return {"profile":"page_spark","glow":"gold","hook":(0,-.65,1.05)}


def marrow_dice(m):
    for center,size in [((-.58,0,.66),(1.13,.98,1.14)),((.56,.05,1.22),(1.24,1.08,1.3))]:
        m.bevel_box(center,size,"bone",.14)
    for x,y,z in [(-.84,-.50,.77),(-.40,-.5,.77),(.18,-.51,1.54),(.91,-.51,1.54),(.19,-.51,.9),(.90,-.51,.9),(.55,-.51,1.24)]:
        m.ellipsoid((x,y,z),(.135,.065,.16),"ink",4,10)
        m.ellipsoid((x,y-.055,z),(.055,.025,.072),"cyan",3,7)
    for x,y,z in [(-.84,.1,1.35),(.50,.07,2.02),(1.0,.08,1.84)]:
        m.tube([(x,y,z),(x-.09,y,z+.17),(x+.02,y,z+.38)],[.09,.08,.006],"cyan",6)
    for x in (-.84,-.36,.31,.88):
        m.tube([(x,.12,.38),(x-.11,-.1,.08)],[.10,.08],"iron",6)
    return {"profile":"spirit_pips","glow":"cyan","hook":(.53,-.59,1.24)}


def grave_compass(m):
    m.lathe((0,0,.48),[(0,.6),(.12,.8),(.28,.68)],"iron",12)
    m.ring((.20,-.04,1.60),(.83,.92),.14,"gold",18,6)
    m.ellipsoid((.20,.04,1.60),(.69,.11,.76),"stone",6,16)
    m.ellipsoid((.20,-.15,1.53),(.26,.045,.28),"ink",4,10)
    m.profile([(.11,2.16),(.29,2.16),(.32,1.59),(.53,1.53),(.20,1.15),(-.06,1.59),(.08,1.60)],.10,"gold",-.23)
    # Real hinged open lid with a different silhouette, not a copy of the mirror.
    m.ring((-.96,.15,1.63),(.50,.89),.13,"green",16,6)
    m.ellipsoid((-.96,.23,1.63),(.42,.06,.77),"green",5,12)
    m.tube([(-.44,.10,.92),(-.42,.10,2.21)],[.085,.085],"gold",7)
    m.ring((.21,0,2.63),(.16,.22),.065,"gold",10,5)
    for x,z in [(-.16,2.17),(.75,1.84),(.53,.95),(-.41,1.57)]:
        m.bevel_box((x,-.145,z),(.10,.055,.15),"green",.01)
    return {"profile":"compass_well","glow":"violet","hook":(.20,-.25,1.53)}


def hollow_violin(m):
    outline=[(-.43,.09),(.40,.09),(.78,.39),(.69,.78),(.35,.98),(.51,1.2),(.45,1.47),(.18,1.6),(-.32,1.55),(-.57,1.23),(-.43,.98),(-.75,.73),(-.76,.35)]
    m.profile(outline,.36,"wood")
    m.profile([(x*.83,z*.91+.06) for x,z in outline],.06,"gold",-.22)
    m.tube([(0,0,1.45),(.08,.0,2.20),(.22,0,2.7)],[.16,.13,.12],"wood",8)
    m.bevel_box((.12,-.10,2.03),(.24,.14,1.02),"iron",.035)
    m.ring((.17,0,2.70),(.13,.18),.07,"wood",10,5,start=.0,sweep=5.7)
    for side in (-1,1):
        m.profile([(side*.38,.97),(side*.58,.88),(side*.42,.72),(side*.57,.54),(side*.35,.44),(side*.39,.62),(side*.26,.82)],.055,"ink",-.27)
        m.ellipsoid((side*.27,-.09,.13),(.19,.25,.12),"iron",4,8)
        for z in (2.38,2.59):
            m.tube([(side*.10,.0,z),(side*.34,0,z)],[.065,.065],"gold",6)
    for x in (-.065,0,.065):
        m.tube([(x,-.31,.43),(x+.08,-.24,2.57)],[.018,.018],"cyan",4)
    m.bevel_box((.0,-.30,.5),(.36,.09,.13),"bone",.02)
    return {"profile":"hollow_strings","glow":"cyan","hook":(0,-.31,.95)}


def raven_quill(m):
    m.ellipsoid((.05,0,.54),(.43,.27,.44),"cloth",5,10)
    m.profile([(-.09,.29),(-.38,.15),(-.40,.6),(-.11,1.63),(.0,2.20),(.19,2.62),(.26,2.87),(.39,2.55),(.58,2.3),(.63,1.85),(.38,1.26),(.18,.56)],.16,"iron",.10)
    m.tube([(-.22,-.04,.35),(.05,-.02,1.20),(.23,.01,2.60)],[.065,.06,.012],"bone",5)
    for x,z in [(.3,.91),(.41,1.3),(.46,1.7),(.42,2.05),(.35,2.3)]:
        m.ribbon([(x-.11,.01,z-.09),(x+.35,.01,z+.18),(x+.43,.04,z+.32)],[.16,.13,.01],"cloth",.08)
    m.profile([(-.13,.82),(-.82,.74),(-.56,1.04),(-.29,1.17)],.17,"cloth",.0)
    m.profile([(-.40,.89),(-.80,.63),(-.78,.34),(-.15,.62)],.12,"bone",-.11)
    m.ellipsoid((-.28,-.15,.9),(.07,.025,.085),"bone",3,8)
    for x in (-.18,.20):
        m.tube([(x,0,.28),(x,-.01,.06),(x+.21,-.12,.055)],[.06,.045,.025],"gold",5)
    return {"profile":"quill_eye","glow":"bone","hook":(-.28,-.19,.9)}


def night_harp(m):
    m.tube([(-1.11,0,.12),(-1.04,0,.52),(-1.0,0,1.07),(-1.37,0,1.84),(-1.31,0,2.59),(-.87,0,3.33),(-.09,0,3.66),(.56,0,3.76)],[.18,.30,.20,.17,.18,.17,.16,.12],"violet",9)
    m.tube([(-1.08,0,.60),(-.59,0,.33),(.14,0,.42),(.71,0,.80),(.81,0,1.13)],[.17,.24,.22,.21,.17],"gold",8)
    m.tube([(.72,0,.68),(.70,0,1.75),(.62,0,2.77),(.56,0,3.76)],[.12,.105,.09,.09],"iron",7)
    m.ellipsoid((.42,-.025,3.65),(.35,.19,.31),"bone",4,10)
    m.ellipsoid((.48,-.205,3.65),(.085,.035,.11),"ink",3,8)
    for x,top,bottom in [(-.83,3.29,.44),(-.47,3.50,.40),(-.11,3.60,.52),(.25,3.68,.67)]:
        m.tube([(x,-.05,top),(x-.28,-.055,bottom)],[.025,.025],"gold",5)
    for x in (-.89,.49):
        m.tube([(x,.11,.42),(x-.21,.11,.08),(x+.1,-.1,.0)],[.14,.11,.065],"iron",6)
    for x,z in [(-1.30,1.9),(-1.10,2.81),(-.56,3.54),(.5,.81)]:
        m.diamond((x,-.16,z),(.12,.045,.17),"gold")
    return {"profile":"harp_strings","glow":"gold","hook":(-.20,-.10,1.9)}


def thorn_cathedral(m):
    m.bevel_box((0,0,1.02),(1.62,1.25,1.42),"iron",.07)
    m.profile([(-.93,1.66),(0,2.35),(.93,1.66),(.87,1.48),(-.90,1.45)],1.43,"cloth",.03)
    m.bevel_box((.68,.17,2.10),(.55,.62,2.45),"iron",.06)
    m.profile([(.31,3.32),(.97,3.32),(.78,4.09)],.81,"cloth",.17)
    m.ring((-.15,-.71,1.35),(.54,.58),.10,"gold",16,6)
    m.ellipsoid((-.15,-.665,1.35),(.47,.055,.50),"red",5,14)
    for side in (-1,1):
        m.tube([(-.15,-.755,1.35),(-.15+side*.35,-.755,1.64)],[.024,.024],"iron",4)
        m.tube([(-.15,-.755,1.35),(-.15+side*.38,-.755,1.12)],[.024,.024],"iron",4)
        m.tube([(side*.67,.26,.61),(side*1.0,.39,.26),(side*1.15,.04,.08)],[.19,.17,.11],"iron",7)
    m.tube([(-.74,0,.88),(-1.11,.10,1.72),(-1.01,.15,2.59),(-.55,.17,2.73),(.16,.04,2.1),(.48,-.25,1.57)],[.095]*6,"bark",6)
    for x,y,z in [(-1.04,.1,2.08),(-.89,.12,2.61),(-.41,.10,2.55),(.45,-.24,1.78),(.73,.15,3.76),(.93,.0,2.67)]:
        m.diamond((x,y,z),(.12,.10,.32),"red")
    m.bevel_box((.68,-.18,2.64),(.14,.05,.72),"red",.02)
    return {"profile":"rose_window","glow":"red","hook":(-.15,-.80,1.35)}


def judgement_scales(m):
    m.tube([(0,0,.48),(0,0,1.77),(0,0,2.7)],[.15,.17,.12],"iron",8)
    m.profile([(-.30,2.02),(.30,2.02),(.44,2.71),(0,3.30),(-.42,2.69)],.30,"bone")
    for x in (-.14,.14):
        m.ellipsoid((x,-.19,2.71),(.055,.04,.27),"ink",4,8)
    m.ring((0,.04,2.75),(.54,.57),.063,"gold",16,5)
    m.tube([(-1.39,0,2.12),(-.62,0,2.39),(0,0,2.21),(.73,0,2.5),(1.43,0,2.58)],[.10]*5,"gold",7)
    for side,top,low in [(-1,2.12,.97),(1,2.58,1.35)]:
        x=side*1.33
        for dx in (-.25,.25):
            m.tube([(x,0,top),(x+dx,0,low+.13)],[.024,.024],"gold",4)
        m.lathe((x,0,low),[(0,.43),(.14,.50),(.26,.47)],"gold" if side>0 else "iron",12)
        m.lathe((x,0,low+.22),[(0,.39),(.07,.30)],"bone" if side>0 else "ink",10)
    for side in (-1,1):
        m.tube([(0,.03,.6),(side*.36,0,.15),(side*.57,-.09,.02)],[.17,.16,.1],"iron",7)
        m.diamond((side*.43,-.03,.18),(.21,.18,.17),"gold")
    return {"profile":"balanced_soul","glow":"gold","hook":(1.33,-.02,1.70)}


def cathedral_heart(m):
    m.bevel_box((0,.0,.48),(2.02,1.35,.50),"iron",.08)
    for side in (-1,1):
        m.tube([(side*.80,.12,.56),(side*1.05,.18,1.4),(side*.83,.20,2.28),(side*.51,.16,3.35),(side*.14,.18,3.95)],[.21,.18,.15,.12,.035],"gold",8)
        m.bevel_box((side*.82,.10,1.47),(.31,.43,1.92),"iron",.05)
        m.profile([(side*.51,2.37),(side*1.1,2.37),(side*.83,3.04)],.47,"iron",.13)
        m.ellipsoid((side*.67,.04,.20),(.28,.34,.25),"iron",4,8)
    # Modeled volumetric split heart; the glow is a narrow seam, not a sphere.
    m.ellipsoid((-.32,-.06,1.95),(.58,.39,.66),"bone",6,12)
    m.ellipsoid((.32,-.06,1.95),(.58,.39,.66),"bone",6,12)
    m.profile([(-.62,1.84),(.63,1.84),(.43,1.29),(0,.93),(-.44,1.29)],.67,"bone",-.05)
    m.tube([(-.13,-.44,2.46),(.08,-.45,2.1),(-.1,-.46,1.79),(.05,-.42,1.41),(0,-.42,1.13)],[.035]*5,"gold",5)
    m.tube([(-.84,-.20,.62),(-1.25,-.25,1.05),(-1.11,-.19,1.73),(-.85,-.10,2.5)],[.09]*4,"iron",6)
    m.tube([(.79,-.19,.68),(1.20,-.15,1.12),(1.04,-.10,1.82),(.83,-.08,2.63)],[.09]*4,"iron",6)
    for x,z in [(-1.17,1.04),(1.09,1.82),(-.79,2.82),(.78,2.86)]:
        m.diamond((x,-.08,z),(.15,.14,.26),"gold")
    return {"profile":"heart_seam","glow":"gold","hook":(0,-.50,1.95)}


def hollow_throne(m):
    m.bevel_box((0,.08,.43),(2.16,1.28,.52),"iron",.07)
    m.bevel_box((0,.12,1.15),(1.74,.96,.20),"cloth",.05)
    m.profile([(-1.12,.47),(1.10,.47),(1.0,2.98),(.56,3.46),(0,3.97),(-.54,3.47),(-1.05,3.02)],.46,"iron",.47)
    m.profile([(-.61,1.44),(.61,1.44),(.59,2.94),(0,3.43),(-.61,2.95)],.055,"ink",.19)
    for side in (-1,1):
        m.bevel_box((side*.93,-.23,1.08),(.35,.88,.34),"stone",.08)
        m.tube([(side*.91,-.20,.37),(side*1.0,-.35,.08)],[.23,.18],"iron",7)
        m.tube([(side*.85,.42,.45),(side*.91,.39,3.10),(side*.63,.32,3.58)],[.11,.11,.035],"stone",6)
        m.tube([(side*.31,.155,1.56),(side*.14,.15,2.29),(side*.36,.15,2.77),(side*.11,.14,3.06)],[.026]*4,"bone",4)
    m.diamond((0,.11,3.39),(.16,.055,.29),"bone")
    m.tube([(-.45,-.55,.59),(.03,-.60,.70),(.42,-.56,.56)],[.038]*3,"bone",5)
    return {"profile":"hollow_silence","glow":"bone","hook":(0,.12,2.18)}


def nameless_door(m):
    # Nested genuine open portal frame volumes. No black opaque screen plane.
    for half,height,depth in [(1.12,3.49,.38),(.83,2.95,.22),(.61,2.43,.12)]:
        material="iron" if half>1 else "green"
        for side in (-1,1):
            m.bevel_box((side*half,depth*.17,height*.5+.18),(.24,depth,height),material,.04)
        m.bevel_box((0,depth*.17,height+.18),(half*2+.20,depth,.27),material,.04)
    m.bevel_box((0,.12,.08),(2.65,1.04,.16),"iron",.05)
    # Impossible threshold rises into suspended steps, but they remain small.
    for i in range(4):
        m.bevel_box((-.02+i*.025,.28+i*.10,.29+i*.20),(1.12-i*.16,.25,.09),"green",.025)
    for side in (-1,1):
        m.tube([(side*1.12,.07,.44),(side*1.36,.08,1.10),(side*1.28,.08,2.10),(side*1.09,.08,2.60)],[.065]*4,"bark",6)
        for z in (.88,1.7,2.71):
            m.diamond((side*1.13,-.22,z),(.095,.065,.23),"cyan")
    m.diamond((0,-.23,3.68),(.21,.085,.40),"green")
    m.diamond((0,-.28,3.69),(.09,.035,.23),"cyan")
    return {"profile":"threshold_veil","glow":"cyan","hook":(0,.0,1.8)}


def inspect_geometry(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    edges = sum(not edge.is_manifold for edge in bm.edges)
    loose = sum(not v.link_faces for v in bm.verts)
    degenerate = sum(face.calc_area() < 1e-9 for face in bm.faces)
    volume = bm.calc_volume(signed=True)
    bm.free()
    if edges or loose or degenerate or volume <= 0:
        raise RuntimeError(f"{obj.name}: manifold={edges} loose={loose} degenerate={degenerate} volume={volume}")
    dimensions = tuple(round(v,6) for v in obj.dimensions)
    if math.sqrt(sum(d*d for d in dimensions)) >= 6.8:
        raise RuntimeError(f"{obj.name} does not fit the existing <7-stud Curse bounds contract: {dimensions}")
    return {"triangles":len(obj.data.polygons),"vertices":len(obj.data.vertices),"nonManifoldEdges":edges,
            "looseVertices":loose,"degenerateFaces":degenerate,"signedVolume":round(volume,6),
            "blenderDimensions":dimensions,"robloxIntendedSize":[dimensions[0],dimensions[2],dimensions[1]],
            "uvLayers":len(obj.data.uv_layers),"vertexColorLayers":len(obj.data.color_attributes),"materialSlots":len(obj.data.materials)}


def render_gallery(objects, filename, indices):
    selected = [objects[i] for i in indices]
    for obj in objects:
        obj.hide_render = obj not in selected
    cols = 5 if len(selected)>5 else len(selected)
    for index,obj in enumerate(selected):
        rows=(len(selected)+cols-1)//cols
        obj.location = ((index%cols)*4.1,0,(rows-1-index//cols)*4.6)
    bpy.ops.object.camera_add(location=(8.8,-27,11))
    camera=bpy.context.object
    target=Vector(((cols-1)*2.05,0,5.0 if len(selected)>5 else 1.0))
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=24 if len(selected)>5 else 18
    scene=bpy.context.scene
    scene.camera=camera
    scene.render.engine="CYCLES"
    scene.cycles.samples=20
    scene.cycles.use_denoising=True
    scene.world.color=(.11,.12,.16)
    for location,power,color in [((3,-10,14),1800,(.75,.84,1)),((15,0,10),1350,(1,.66,.41)),((-6,4,8),1400,(.32,.80,1))]:
        bpy.ops.object.light_add(type="AREA",location=location)
        light=bpy.context.object
        light.data.energy=power
        light.data.color=color
        light.data.shape="DISK"
        light.data.size=8
        light.rotation_euler=(target-light.location).to_track_quat("-Z","Y").to_euler()
    scene.render.resolution_x=1800
    scene.render.resolution_y=1150 if len(selected)>5 else 700
    scene.render.resolution_percentage=100
    scene.render.filepath=str(SOURCE/filename)
    scene.view_settings.view_transform="Standard"
    bpy.ops.render.render(write_still=True)
    for obj in objects:
        obj.hide_render=False


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    material=create_material()
    objects=[]
    records=[]
    for id,name,rarity in WAVE:
        builder=Builder()
        hook=globals()[id](builder)
        obj=builder.object(id,material)
        record=inspect_geometry(obj)
        record.update({"id":id,"displayName":name,"rarity":rarity,"export":f"assets/export/meshes/curses/{id}.fbx",
                       "implementationStatus":"EXPORTED","enabled":False,"meshId":None,"textureId":None,
                       "colorPipeline":"FBX per-corner BYTE_COLOR SACPaintedColor, white Roblox tint; importer appearance unverified","fbxGlobalScale":.01,
                       "vfxProfile":hook["profile"],"glowPalette":hook["glow"],
                       "vfxHookRoblox":[round(hook["hook"][0]-builder.offset[0],6),round(hook["hook"][2]-builder.offset[2],6),round(hook["hook"][1]-builder.offset[1],6)],
                       "requiresImportedTexture":False})
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.export_scene.fbx(filepath=str(EXPORT/f"{id}.fbx"),use_selection=True,global_scale=.01,
                                 apply_unit_scale=True,bake_space_transform=False,object_types={"MESH"},
                                 add_leaf_bones=False,path_mode="AUTO",colors_type="SRGB")
        records.append(record)
        objects.append(obj)
        print("CURSE_EXPANSION_ASSET",json.dumps(record))
    (SOURCE/"first_wave_geometry.json").write_text(json.dumps({"schemaVersion":1,"waveCount":15,
        "totalSourceTriangles":sum(r["triangles"] for r in records),"paintedPalette":PALETTE,
        "colorPipeline":"Original broad per-corner vertex gradients, one neutral material, no texture assets",
        "assets":records},indent=2)+"\n",encoding="utf-8")
    render_gallery(objects,"first_wave_gallery.png",range(15))
    # Keep one editable authored asset per object in a labeled gallery; export
    # centers are separate from source-only display layout and lighting.
    for i,obj in enumerate(objects):
        obj.location=((i%5)*4.1,0,(2-i//5)*4.6)
        obj["CurseId"]=WAVE[i][0]
        obj["ImportStatus"]="EXPORTED_NOT_IMPORTED"
        obj["TemplateStudSizeXYZ"]=records[i]["robloxIntendedSize"]
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"steal_a_curse_expansion_wave1.blend"))
    print("CURSE_EXPANSION_GENERATED",len(objects),sum(r["triangles"] for r in records))


if __name__=="__main__":
    if "--preview-only" in sys.argv:
        bpy.ops.wm.open_mainfile(filepath=str(SOURCE/"steal_a_curse_expansion_wave1.blend"))
        for obj in list(bpy.context.scene.objects):
            if obj.type in {"CAMERA","LIGHT"}:
                bpy.data.objects.remove(obj,do_unlink=True)
        objects=[bpy.data.objects[id] for id,_,_ in WAVE]
        render_gallery(objects,"first_wave_gallery.png",range(15))
        bpy.context.preferences.filepaths.save_version=0
        bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"steal_a_curse_expansion_wave1.blend"))
    else:
        main()
