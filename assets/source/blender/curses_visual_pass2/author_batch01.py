"""Second visual pass. Original authored geometry; reuse seven editable .blend sources.
Run in Blender: --background --factory-startup --python author_batch01.py
Local FBX validation never implies a Roblox import or a Play approval.
"""
from pathlib import Path
import sys, math, json, hashlib
import bpy
from mathutils import Vector, Matrix

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OLD = ROOT / 'assets/source/blender/curses_expansion/rework'
sys.path.insert(0, str(OLD))
import rework_geometry as geo
import common_models as common
import high_generate as high
geo.SOURCE = HERE
geo.EXPORT = ROOT / 'assets/export/meshes/curses/visual-pass2'
geo.EXPORT.mkdir(parents=True, exist_ok=True)
geo.PALETTE.update({
    'rag': (.78,.63,.42), 'rag_light': (.95,.83,.62), 'seam': (.29,.15,.11),
    'plum': (.36,.16,.28), 'plum_edge': (.65,.32,.45), 'hair': (.24,.13,.10),
    'button': (.065,.075,.095), 'brass': (.60,.43,.22), 'brass_edge': (.88,.70,.40),
    'glass': (.25,.52,.62), 'glass_shadow': (.095,.22,.30), 'silver': (.61,.72,.75),
    'mirror_ghost': (.66,.84,.80), 'porcelain': (.91,.88,.80), 'porcelain_shadow': (.61,.68,.71),
    'tear': (.34,.77,.82), 'violet': (.29,.18,.42), 'violet_edge': (.57,.37,.65),
    'iris': (.58,.32,.79), 'eye_white': (.90,.91,.84), 'iron': (.22,.24,.28),
    'iron_edge': (.49,.48,.44), 'rust': (.56,.24,.11), 'ember': (.96,.35,.10),
    'ember_core': (1,.83,.48), 'void': (.04,.05,.075), 'void_edge': (.34,.39,.46),
    'void_silver': (.85,.90,.94), 'shadow_readable': (.19,.24,.29),
})

def part(m, name): m.begin_part(name)
def line(m, points, r, key): m.tube(points, [r]*len(points), key, 6)
def plate(m, outline, depth, key, y=0): m.profile(outline, depth, key, y)
def link(m, center, radii, thickness, key, turn=0):
    start=len(m.vertices)
    m.ring(center,radii,thickness,key,18,6)
    if turn:
        c=Vector(center)
        m.transform_since(start,Matrix.Translation(c)@Matrix.Rotation(turn,4,'Z')@Matrix.Translation(-c))

def doll(m):
    part(m,'Stuffed rag head, crooked patchwork dress and articulated soft limbs')
    m.ellipsoid((-.10,0,3.38),(.97,.57,.90),'rag',9,20)
    m.lathe((0,0,1.14),[(0,.91),(.14,.97),(.52,.71),(1.01,.43),(1.15,.42)],'plum',14)
    m.ellipsoid((0,0,2.50),(.46,.31,.34),'rag',6,14)
    for side in (-1,1):
        m.tube([(side*.37,0,2.53),(side*.88,-.04,1.96),(side*1.12,-.20,1.69)], [.20,.17,.22],'rag',9)
        m.ellipsoid((side*1.12,-.21,1.64),(.24,.22,.27),'rag_light',6,12)
        m.tube([(side*.39,.03,1.25),(side*.42,-.08,.69),(side*.49,-.16,.23)],[.21,.18,.22],'rag',9)
        m.ellipsoid((side*.50,-.28,.20),(.29,.37,.18),'plum',6,12)
        line(m,[(side*.45,-.23,.65),(side*.51,-.29,.47)],.027,'seam')
    part(m,'Unequal sewn button eyes, smile stitches, fabric ear and side patch')
    for x,z,r in [(-.40,3.54,.23),(.30,3.50,.18)]:
        m.ellipsoid((x,-.525,z),(r,.11,r),'button',6,14)
        for dx,dz in [(-.06,-.06),(.06,.06)]:
            m.ellipsoid((x+dx,-.63,z+dz),(.027,.020,.027),'rag_light',4,8)
        line(m,[(x-.075,-.646,z-.07),(x+.075,-.646,z+.07)],.021,'rag_light')
    line(m,[(-.41,-.49,3.12),(-.12,-.57,2.99),(.21,-.50,3.10)],.035,'seam')
    for x in (-.28,-.11,.07): line(m,[(x-.02,-.566,2.98),(x+.02,-.57,3.12)],.026,'rag_light')
    plate(m,[(.51,3.02),(.88,3.10),(.92,3.41),(.63,3.38)],.035,'plum_edge',-.46)
    for x,z in [(.56,3.07),(.65,3.14),(.75,3.17),(.85,3.28)]: line(m,[(x-.06,-.495,z+.03),(x+.05,-.495,z-.05)],.024,'rag_light')
    m.ellipsoid((-.93,0,3.45),(.18,.20,.28),'rag_light',5,10)
    part(m,'Uneven wool hair and stitched hem, broad readable dress panels')
    for x,z in [(-.79,3.79),(-.44,4.05),(-.07,4.19),(.34,4.07),(.69,3.89)]:
        m.tube([(x,.02,z),(x-.06,-.28,z+.06),(x-.10,-.46,z-.27)],[.18,.20,.11],'hair',7)
    m.rotated_box((-.52,-.17,4.18),(.62,.25,.33),'plum_edge',(0,.23,0),.09)
    for x in (-.65,-.30,.10,.45):
        line(m,[(x,-.61,1.39),(x*.73,-.48,1.91)],.035,'plum_edge')
    for a in range(12):
        t=math.tau*a/12
        line(m,[(.90*math.cos(t),.90*math.sin(t),1.15),(.88*math.cos(t),.88*math.sin(t),1.31)],.031,'rag_light')
    return ((-.40,-.62,3.54),'rag_whisper','Warm rag doll with unequal sewn eyes, wool locks, repaired cheek and plum patchwork dress; no whole-model tint.')

def mirror(m):
    part(m,'Deep pointed brass frame with open glazing aperture and curved feet')
    outer=[(-1.35,.80),(-1.54,1.30),(-1.52,4.75),(-1.03,5.51),(0,6.05),(1.10,5.53),(1.51,4.66),(1.45,1.19),(1.13,.77)]
    inner=[(-1.00,1.15),(-1.15,1.48),(-1.14,4.60),(-.79,5.10),(0,5.56),(.77,5.08),(1.13,4.51),(1.09,1.49),(.81,1.14)]
    common.ring_shell(m,outer,inner,.46,'brass',0)
    common.ring_shell(m,[(x*.95,z*.975+.08) for x,z in outer],[(x*.98,z*.987+.035) for x,z in inner],.08,'brass_edge',-.27)
    plate(m,inner,.12,'glass_shadow',.23)
    plate(m,[(-1.06,1.49),(-1.07,4.48),(-.72,5.02),(.28,5.14),(.73,4.87),(.72,1.57)],.018,'glass',.15)
    for side in (-1,1):
        m.tube([(side*.69,.05,1.15),(side*.74,.12,.60),(side*1.13,-.03,.20),(side*1.30,-.22,.15)],[.20,.17,.18,.12],'brass',9)
        line(m,[(side*1.32,-.25,1.45),(side*1.30,-.27,3.30),(side*1.31,-.24,4.73)],.050,'brass_edge')
        m.ellipsoid((side*1.39,-.23,2.31),(.13,.09,.30),'brass_edge',6,12)
    part(m,'Ghost reflection crosses the glass, fractured highlights and oxidized joinery')
    m.ellipsoid((.18,.02,3.50),(.45,.16,.58),'mirror_ghost',8,16)
    plate(m,[(-.39,2.02),(-.33,2.75),(-.15,3.18),(.47,3.19),(.61,2.45),(.35,2.15),(.17,2.38),(-.08,2.04)],.22,'mirror_ghost',.015)
    for x in (-.02,.28): m.ellipsoid((x,-.145,3.57),(.057,.03,.14),'glass_shadow',5,10)
    for points in [[(-.79,.068,4.97),(-.57,.06,4.59),(-.65,.06,4.21),(-.42,.06,3.99)],[(.76,.06,1.61),(.41,.06,2.20),(.68,.06,2.63)]]: line(m,points,.025,'silver')
    line(m,[(-.92,.05,1.82),(-.94,.05,2.34)],.039,'silver')
    line(m,[(.84,.04,4.08),(.83,.04,4.47)],.032,'silver')
    return ((.18,-.14,3.50),'reversed_reflection','Tall dimensional pointed brass mirror; recessed cool glazing with an embodied pale reflection, slender cracks and substantial open frame.')

def mask(m):
    part(m,'Sculpted tragic porcelain with genuinely empty eye apertures')
    # Separate shaped forehead, cheeks, bridge and chin preserve two real holes.
    plate(m,[(-1.13,2.84),(-1.27,3.80),(-.75,4.32),(0,4.49),(.80,4.30),(1.28,3.78),(1.10,2.84),(.68,3.13),(-.65,3.13)],.50,'porcelain',.10)
    for side in (-1,1):
        outer=[(side*.18,2.72),(side*.22,3.46),(side*.82,3.55),(side*1.15,3.10),(side*.96,2.58)]
        inner=[(side*.37,2.85),(side*.39,3.22),(side*.74,3.26),(side*.91,3.06),(side*.77,2.81)]
        common.ring_shell(m,outer,inner,.52,'porcelain',-.03)
        m.ellipsoid((side*.85,-.01,2.27),(.37,.34,.43),'porcelain',7,14)
        line(m,[(side*.64,-.34,2.90),(side*.72,-.35,2.44),(side*.81,-.32,1.92),(side*.64,-.30,1.36)],[.09] if False else .080,'tear')
        m.ellipsoid((side*.64,-.31,1.19),(.14,.12,.24),'tear',6,12)
    m.tube([(0,-.14,3.44),(0,-.44,2.96),(0,-.53,2.62)],[.17,.17,.24],'porcelain_shadow',8)
    part(m,'Open sorrowful mouth and long asymmetric cloth ties')
    common.oval_shell(m,0,-.03,1.91,.38,.54,.12,.38,'porcelain_shadow',20)
    common.oval_shell(m,0,-.09,1.93,.32,.45,.13,.42,'porcelain',20)
    m.ellipsoid((0,.06,1.34),(.49,.32,.34),'porcelain',7,16)
    for side in (-1,1):
        m.ribbon([(side*1.0,.27,3.55),(side*1.64,.26,3.19),(side*1.83,.13,2.64),(side*1.57,-.07,1.49),(side*1.89,-.04,.42)], [.17,.26,.22,.21,.04],'blue_cloth',.10)
    line(m,[(-.51,-.18,4.24),(-.37,-.20,3.92),(-.47,-.20,3.73)],.027,'porcelain_shadow')
    return ((0,-.32,2.05),'porcelain_tears','Tragic faceted porcelain, empty eye holes, projecting nose and open downturned mouth; long blue ties, shaped turquoise tears instead of neon stripes.')

def eye(m):
    part(m,'Single sculpted eye with brow lids, vertical pupil and long articulated arms')
    m.ellipsoid((0,0,3.19),(1.23,.58,.89),'eye_white',10,24)
    m.ellipsoid((0,-.51,3.18),(.59,.17,.65),'iris',9,20)
    m.ellipsoid((0,-.66,3.18),(.095,.08,.49),'button',8,16)
    m.ellipsoid((-.20,-.73,3.43),(.12,.028,.17),'eye_white',6,12)
    for up in (-1,1):
        m.tube([(-1.11,-.16,3.19),(-.64,-.30,3.19+up*.72),(0,-.27,3.19+up*.91),(.73,-.28,3.19+up*.65),(1.14,-.13,3.19)], [.18,.17,.19,.17,.14],'violet',9)
        line(m,[(-.93,-.25,3.19+up*.30),(-.49,-.39,3.19+up*.76),(.20,-.37,3.19+up*.79)],.040,'violet_edge')
    for side in (-1,1):
        m.tube([(side*1.05,.04,3.33),(side*1.92,.06,3.65),(side*2.67,-.04,2.68),(side*2.57,-.24,1.58)],[.25,.24,.20,.24],'violet',10)
        for x,y,z in [(side*1.83,.05,3.67),(side*2.66,-.01,2.76),(side*2.60,-.20,1.83)]:
            m.ellipsoid((x,y,z),(.27,.27,.24),'violet_edge',6,12)
        m.bevel_box((side*2.57,-.25,1.66),(.59,.50,.22),'brass',.08)
        m.ellipsoid((side*2.57,-.28,1.20),(.38,.29,.44),'violet',7,14)
        # Exactly two hands, with individual curled slender fingers and thumbs.
        for i in range(4):
            x=side*(2.31+i*.17); z=1.05-abs(i-1.5)*.035
            m.tube([(x,-.38,z),(x+side*.025,-.50,.57),(x-side*.05,-.57,.33+(i%2)*.06)], [.095,.082,.060],'violet_edge',7)
        m.tube([(side*2.26,-.32,1.30),(side*2.02,-.45,1.04),(side*2.05,-.55,.79)],[.13,.11,.075],'violet',8)
    return ((0,-.72,3.18),'unblinking_gaze','A single white violet eye supported by long asymmetrically bent violet arms, bronze wrist cuffs and exactly two articulated hands; tall negative space beneath.')

def chains(m):
    part(m,'Heavy rusted shoulder manacles around an empty captive silhouette')
    for side in (-1,1):
        m.bevel_box((side*1.26,.16,3.72),(.90,.87,1.14),'iron',.18)
        m.bevel_box((side*1.27,-.31,3.91),(.93,.18,.31),'rust',.07)
        for z in (3.42,4.00): m.ellipsoid((side*1.29,-.40,z),(.12,.10,.12),'iron_edge',5,10)
        m.tube([(side*1.18,.15,3.35),(side*1.49,.14,2.22),(side*1.01,.20,.51)],[.32,.26,.20],'iron',8)
        m.tube([(side*1.11,.03,3.45),(side*.78,.13,2.66),(side*.99,.12,1.46)],[.12,.15,.17],'iron_edge',7)
    part(m,'Three actual alternating linked chains, dangling broken iron hook')
    for side in (-1,1):
        for i in range(6):
            link(m,(side*(1.03-.13*i),-.38,3.59-i*.46),(.25,.35),.083,'iron_edge' if i%3==0 else 'iron',math.pi/2 if i%2 else 0)
    for i in range(7):
        link(m,(-1.22+i*.40,-.16,4.22+math.sin(i*.55)*.51),(.23,.31),.078,'rust' if i in (0,5) else 'iron_edge',math.pi/2 if i%2 else 0)
    link(m,(1.47,-.05,.93),(.22,.29),.09,'rust')
    m.ring((1.51,-.07,.40),(.25,.37),.11,'iron_edge',16,6,start=.24,sweep=4.7)
    part(m,'Captive ember rib cage, empty head and tapered forge flame')
    common.oval_shell(m,0,.18,4.26,.43,.57,.11,.36,'iron',20)
    for side in (-1,1):
        for z in (2.45,2.90,3.33):
            m.tube([(side*.91,.17,z+.22),(side*.72,-.18,z),(side*.29,-.27,z-.11)],[.10,.105,.065],'rust',7)
    m.ellipsoid((0,-.15,2.76),(.37,.27,.49),'ember_core',8,16)
    for i in range(5):
        x=(i-2)*.19
        m.tube([(x,.05,1.25),(x-.12,.03,1.72),(x+.12,.07,2.20),(x+.04,.07,2.44+i%2*.28)],[.16,.17,.11,.018],'ember',8)
    return ((0,-.29,2.75),'bound_embers','Rusted forge entity with an empty iron head, massive shoulder manacles, three genuine linked chains and restrained bone-colored captive ember; no purple orb.')

def void(m):
    part(m,'Asymmetric fractured void rift surrounding a genuinely empty aperture')
    # Broken irregular arcs, not a circular symmetric ornament or a filled ball.
    paths=[([(-1.29,.20,.46),(-2.14,.07,1.98),(-2.33,.05,3.82),(-1.76,.12,5.23),(-.79,.11,6.02)],[.28,.35,.32,.27,.12]),
           ([(.34,.17,6.25),(1.61,.02,5.49),(2.12,-.02,4.20),(1.73,.14,2.37),(.91,.14,1.01)],[.16,.37,.35,.29,.13]),
           ([(-.51,.15,.25),(.35,.10,.48),(.90,.12,1.06)],[.12,.25,.16])]
    for pts,radii in paths:
        m.tube(pts,radii,'void',8)
        m.tube([(x,y-.17,z) for x,y,z in pts],[r*.19 for r in radii],'void_silver',5)
    part(m,'Five nonidentical black shards with cold shaped bevel faces')
    shards=[([(-2.82,.95),(-2.40,2.24),(-3.10,3.07),(-3.00,1.92)],.73),
            ([(-2.59,4.65),(-1.74,6.33),(-2.07,7.05),(-3.20,5.50)],.61),
            ([(1.92,5.44),(2.70,6.35),(3.35,5.21),(2.58,4.67)],.83),
            ([(2.34,2.93),(3.42,3.20),(3.09,1.45),(2.34,1.76)],.64),
            ([(-.37,-.40),(.41,.11),(.83,-.62),(.17,-1.10)],.53)]
    for index,(outline,depth) in enumerate(shards):
        high.plate(m,outline,depth,'void',(.12,-.16,.23,-.04,.15)[index],'void_edge',.80)
        points=[(x,-depth*.5-.18,z) for x,z in outline[:3]]
        line(m,points,.035,'void_silver')
    part(m,'Thin unconnected cold boundary wisps around negative space')
    for pts in [[(-1.37,-.10,2.20),(-1.45,-.17,3.27),(-1.18,-.15,4.44)],[(1.01,-.16,4.72),(1.39,-.21,4.06),(1.38,-.19,3.15)], [(-.48,-.20,5.47),(.14,-.19,5.58)]]:
        line(m,pts,.026,'void_silver')
    return ((0,-.20,3.14),'empty_rift','Secret: towering empty fractured oval rift; five asymmetrical layered dark shards and narrow silver boundaries. The center remains literally empty, never a purple ball.')

ORIGINALS={
 'cursed_doll':('Cursed Doll','COMMON',doll,4.8,'assets/reference/cursed-doll-approved-v1.png'),
 'haunted_mirror':('Haunted Mirror','RARE',mirror,7.0,'assets/reference/curses-six-roblox-v2.png'),
 'crying_mask':('Crying Mask','RARE',mask,5.8,'assets/reference/crying-mask-roblox-rework-v2.png'),
 'watching_eye':('Watching Eye','LEGENDARY',eye,6.5,'assets/reference/watching-eye-long-arms-v4.png'),
 'soul_chains':('Soul Chains','MYTHIC',chains,9.5,'assets/reference/soul-chains-mythic-rework-v3.png'),
 'the_void':('The Void','SECRET',void,12.6,'assets/reference/the-void-rift-aura-v3.png'),
}

def export_existing(id, height, width=None, depth=None):
    """Load and preserve the editable actual first-pass sculpt rather than discard it."""
    source=OLD/(id+'.blend')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    obj=bpy.data.objects[id]
    old=json.loads((OLD/(id+'_metrics.json')).read_text(encoding='utf-8'))
    # Local spatial edits reinforce the concept; no triangles added for their own sake.
    if id=='coin_crawler':
        for v in obj.data.vertices:
            v.co.z *= 1.48
    if id=='pale_gramophone':
        for v in obj.data.vertices:
            if v.co.z>.20:
                v.co.x *= 1.16; v.co.y *= 1.10
    if id=='pale_guest':
        for v in obj.data.vertices:
            if v.co.y<-.14: v.co.y-=.16
    if id=='cold_teacup':
        for v in obj.data.vertices:
            if v.co.z>.14: v.co.x *= 1.10
    obj.data.update()
    dims=obj.dimensions.copy()
    factors=Vector((width/dims.x if width else height/dims.z,depth/dims.y if depth else height/dims.z,height/dims.z))
    for v in obj.data.vertices: v.co *= factors
    # Center by authored bounds; irregular reshaping may move the bounding center.
    lo=Vector(tuple(min(v.co[a] for v in obj.data.vertices) for a in range(3)))
    hi=Vector(tuple(max(v.co[a] for v in obj.data.vertices) for a in range(3)))
    center=(lo+hi)/2
    for v in obj.data.vertices: v.co -= center
    colors=obj.data.color_attributes.get('SACPaintedColor')
    for c in colors.data:
        r,g,b,a=c.color_srgb
        # Lift dark form colors without filling true ink apertures or flattening hues.
        maximum=max(r,g,b)
        if .045<maximum<.38:
            uplift=.10 if id in ('coin_crawler','cathedral_heart','thorn_cathedral') else .065
            c.color_srgb=(min(1,r+uplift*.83),min(1,g+uplift*.89),min(1,b+uplift),a)
    obj.data.update(); bpy.context.view_layer.update()
    qa=geo.check_mesh(obj)
    dims=list(obj.dimensions)
    hook=Vector((old['vfxHook'][0],-old['vfxHook'][2],old['vfxHook'][1]))*factors-center
    row={**old,'source':f'assets/source/blender/curses_visual_pass2/{id}.blend','blendSource':f'assets/source/blender/curses_visual_pass2/{id}.blend',
         'export':f'assets/export/meshes/curses/visual-pass2/{id}.fbx','sourceReused':str(source.relative_to(ROOT)).replace('\\','/'),
         'sourceReusedSha256':hashlib.sha256(source.read_bytes()).hexdigest(),
         'blenderDimensions':dims,'intendedRobloxSize':[dims[0],dims[2],dims[1]],'robloxIntendedSize':[dims[0],dims[2],dims[1]],
         'vfxHook':[hook.x,hook.z,-hook.y],'vfxHookRoblox':[hook.x,hook.z,-hook.y],
         'diagonal':math.sqrt(sum(d*d for d in dims)),'localValidation':qa,
         'realImportRecorded':False,'appearanceChecked':False,'gameplayChecked':False,'enabled':False,
         'designNotes':old['designNotes']+['Pass 2: concept-specific proportions and silhouette, lifted dark materials, expanded authored dimensions; preserves actual editable .blend.']}
    obj['VFXHook_Blender']=list(hook); obj['Pass2BaselineSource']=row['sourceReused']
    # Stale render lights/cameras in first-pass scenes are excluded from FBX.
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.fbx(filepath=str(ROOT/row['export']),use_selection=True,global_scale=.01,apply_unit_scale=True,
                            object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
    row['sha256']=hashlib.sha256((ROOT/row['export']).read_bytes()).hexdigest()
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/row['source']))
    return obj,row

def main():
    rows=[]
    requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    for id,(display,rarity,fn,height,ref) in ORIGINALS.items():
        if requested and id not in requested: continue
        geo.reset(); m=geo.Sculpt(); hook,profile,notes=fn(m)
        lo=min(v[2] for v in m.vertices); hi=max(v[2] for v in m.vertices)
        scale=height/(hi-lo)
        m.vertices=[tuple(c*scale for c in v) for v in m.vertices]
        hook=tuple(c*scale for c in hook)
        obj,row=m.finish(id,display,rarity,ref,hook,profile,notes,diagonal_limit=19)
        rows.append(row)
        geo.render(obj,HERE/(id+'_preview.png'),azimuth=.48 if id=='the_void' else -.30)
        row['roundtripValidation']=geo.validate_asset(row)
        (HERE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
        print('PASS2_SOURCE_READY',id,row['triangles'],row['intendedRobloxSize'],flush=True)
    for id,h,w,d in [('pale_guest',4.8,3.8,None),('cold_teacup',4.9,5.0,None),('coin_crawler',2.8,5.2,3.8),
                     ('pale_gramophone',6.2,5.2,None),('thorn_cathedral',8.2,5.6,None),
                     ('cathedral_heart',9.6,6.6,None),('the_last_star',11.4,8.5,4.8)]:
        if requested and id not in requested: continue
        obj,row=export_existing(id,h,w,d)
        rows.append(row)
        geo.render(obj,HERE/(id+'_preview.png'),azimuth=.42)
        row['roundtripValidation']=geo.validate_asset(row)
        (HERE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
        print('PASS2_SOURCE_READY',id,row['triangles'],row['intendedRobloxSize'],flush=True)
    (HERE/'batch01-local-geometry.json').write_text(json.dumps({'assets':rows,'studioImportPending':True},indent=2)+'\n',encoding='utf-8')
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for index,row in enumerate(rows):
        with bpy.data.libraries.load(str(ROOT/row['source']),link=False) as (a,b): b.objects=[row['id']]
        obj=b.objects[0]; bpy.context.collection.objects.link(obj)
        obj.location=((index%4)*16,(index//4)*16,0)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(filepath=str(geo.EXPORT/'batch01-13.fbx'),use_selection=True,global_scale=.01,apply_unit_scale=True,
                            object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
    print('PASS2_BATCH_LOCAL_DONE',len(rows),flush=True)

if __name__=='__main__':
    if '--aggregate' in sys.argv:
        rows=json.loads((HERE/'batch01-local-geometry.json').read_text(encoding='utf-8'))['assets']
        bpy.ops.wm.read_factory_settings(use_empty=True)
        for index,row in enumerate(rows):
            with bpy.data.libraries.load(str(ROOT/row['source']),link=False) as (a,b): b.objects=[row['id']]
            obj=b.objects[0]; bpy.context.collection.objects.link(obj)
            obj.location=((index%4)*16,(index//4)*16,0)
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.fbx(filepath=str(geo.EXPORT/'batch01-13.fbx'),use_selection=True,global_scale=.01,apply_unit_scale=True,
                                object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
        print('PASS2_BATCH_LOCAL_DONE',len(rows),flush=True)
    else: main()
