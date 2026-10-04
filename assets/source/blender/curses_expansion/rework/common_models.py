"""Reference-authored volumes for all fifteen Common Curse concepts."""
from pathlib import Path
import json
import math
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from rework_geometry import Sculpt, PALETTE, reset, render, validate_asset, SOURCE
# The same surface authoring used by the high rarity source subdivides broad
# panels for painted chips and grain. Preserve the Common palette while sharing
# its implementation; importing the source never runs its guarded batch.
_common_palette=dict(PALETTE)
from high_generate import PaintedSculpt
PALETTE.update(_common_palette)


def candle_wisp(m):
    m.begin_part('MeltedWaxBody')
    m.lathe((0,0,0),[(0,.68),(.14,.79),(.4,.65),(.92,.57),(1.5,.56),
                    (2.04,.6),(2.5,.52),(2.72,.39)],'wax',20,.06)
    m.ellipsoid((-.05,-.12,.79),(.67,.46,.72),'wax',7,16)
    for side in (-1,1):
        m.ellipsoid((side*.49,-.21,.16),(.41,.47,.19),'wax_light',6,14)
        m.ellipsoid((side*.20,.04,.07),(.56,.46,.09),'wax',4,14)
    # Heavy uneven crown and finger-like melt drips are actual round volumes.
    m.begin_part('WaxCrownAndDrips')
    m.lathe((0,-.01,2.38),[(0,.55),(.10,.62),(.24,.64),(.35,.48)],'wax_light',20,.10)
    for x,z,length,r in [(-.49,2.52,.42,.12),(-.28,2.62,.22,.105),
                          (.08,2.6,.33,.12),(.4,2.51,.56,.145),(.55,2.38,.39,.10)]:
        m.tube([(x,-.33,z),(x-.04,-.49,z-.10),(x+.02,-.53,z-length)],
               [r*1.1,r,r*.65],'wax_light',8)
        m.ellipsoid((x+.02,-.53,z-length),(r*.69,r*.72,r*.82),'wax_light',4,9)
    for x,y,length in [(-.3,.42,.30),(.31,.42,.49),(-.51,.15,.35)]:
        m.tube([(x,y,2.59),(x*1.03,y*1.08,2.45),(x*.98,y*1.06,2.59-length)],
               [.12,.1,.06],'wax',7)
    m.begin_part('DroopingHands')
    for side in (-1,1):
        m.tube([(side*.44,0,1.73),(side*.78,-.08,1.42),(side*1,-.19,.95)],
               [.27,.25,.19],'wax',12)
        m.ellipsoid((side*1,-.20,.85),(.26,.24,.36),'wax_light',6,12)
        for finger in range(3):
            x=side*(.87+finger*.11); z=.57-(finger%2)*.13
            m.tube([(x,-.27,.88),(x+side*.055,-.32,.65),(x+side*.035,-.33,z)],
                   [.08,.07,.045],'wax',7)
            m.ellipsoid((x+side*.035,-.33,z),(.053,.052,.064),'wax_light',4,8)
    m.begin_part('InsetBlackEyes')
    for x,z in [(-.23,1.88),(.27,1.73)]:
        m.ellipsoid((x,-.525,z),(.19,.075,.235),'wax_shadow',5,12)
        m.ellipsoid((x,-.579,z),(.152,.085,.183),'eye',7,14)
        m.ellipsoid((x-.03,-.652,z+.065),(.034,.014,.042),'iron_edge',3,8)
    # Narrow runnels give front and rear a poured-wax identity at game distance.
    for x,z,length in [(-.31,1.7,.8),(.08,1.5,.58),(.43,.98,.36),(-.1,.73,.37)]:
        m.tube([(x,-.46,z),(x-.025,-.54,z-.15),(x+.02,-.5,z-length)],
               [.07,.055,.025],'wax_light',6)
    m.begin_part('BlueGhostFlame')
    m.tube([(.0,0,2.69),(.06,-.015,2.92),(.18,0,3.18),(.10,.01,3.47),(.31,0,3.78),(.5,0,3.88)],
           [.12,.24,.27,.18,.09,.018],'flame',13)
    m.tube([(.05,-.14,2.82),(.14,-.21,3.05),(.21,-.18,3.22),(.18,-.11,3.45)],
           [.075,.13,.1,.012],'flame_core',10)
    m.tube([(-.08,.02,2.85),(-.23,0,3.12),(-.12,0,3.32)],
           [.13,.085,.008],'flame',9)
    return (0,-.06,3.21),'ghost_flame','Rebuilt from current rework01: substantial asymmetric wax volumes, melted crown, round hand drips, inset eyes and sculpted blue flame; replaces weak first-wave shape.'


def ring_shell(m,outer,inner,depth,key,y=0):
    """Closed extruded ring with a real opening, not a front black patch."""
    first=len(m.vertices); n=len(outer)
    for cy in (y-depth/2,y+depth/2):
        m.vertices.extend((x,cy,z) for x,z in outer)
        m.vertices.extend((x,cy,z) for x,z in inner)
    for i in range(n):
        j=(i+1)%n; a=first+i; b=first+j; ai=first+n+i; bi=first+n+j
        for face in ((a,ai,bi,b),(a+2*n,b+2*n,bi+2*n,ai+2*n),
                     (a,b,b+2*n,a+2*n),(ai,ai+2*n,bi+2*n,bi)):
            m.face(face,key)


def oval_shell(m,cx,y,cz,rx,rz,width,depth,key,sides=20):
    outer=[(cx+rx*math.cos(i*math.tau/sides),cz+rz*math.sin(i*math.tau/sides)) for i in range(sides)]
    inner=[(cx+(rx-width)*math.cos(i*math.tau/sides),cz+(rz-width)*math.sin(i*math.tau/sides)) for i in range(sides)]
    ring_shell(m,outer,inner,depth,key,y)


def hollow_lathe(m,center,profile,key,sides=20):
    """Revolve a closed radius/height boundary, giving bowls real wall depth."""
    start=len(m.vertices); cx,cy,cz=center
    for z,r in profile:
        m.vertices.extend((cx+math.cos(i*math.tau/sides)*r,cy+math.sin(i*math.tau/sides)*r,cz+z) for i in range(sides))
    for level in range(len(profile)):
        nextlevel=(level+1)%len(profile)
        for i in range(sides):
            j=(i+1)%sides
            m.face((start+level*sides+i,start+level*sides+j,
                    start+nextlevel*sides+j,start+nextlevel*sides+i),key)


def tiny_eyes(m,center,spacing=.23,rx=.11,rz=.17,key='white_glow'):
    x,y,z=center
    for side in (-1,1): m.ellipsoid((x+side*spacing,y,z),(rx,.045,rz),key,5,12)


def stone_cracks(m,paths,key='stone_dark',radius=.018):
    for path in paths: m.tube(path,[radius]*len(path),key,4)


def bulged_strip(m,points,widths,key,depth=.12):
    """Closed lenticular leaf/cloth volume with curved front and rear faces."""
    start=len(m.vertices); sides=8
    for (x,y,z),width in zip(points,widths):
        for i in range(sides):
            a=i*math.tau/sides
            m.vertices.append((x+math.cos(a)*width/2,y+math.sin(a)*depth/2,z))
    m.face((start+i for i in reversed(range(sides))),key)
    for row in range(len(points)-1):
        for i in range(sides):
            j=(i+1)%sides
            m.face((start+row*sides+i,start+row*sides+j,start+(row+1)*sides+j,start+(row+1)*sides+i),key)
    end=start+(len(points)-1)*sides; m.face((end+i for i in range(sides)),key)


def grave_hopper(m):
    m.begin_part('HollowAmphibianStoneShell')
    # Loft the outer frog body around an open yawning mouth, then a deep throat.
    rings=[(-.91,.83,.65,.32),(-.76,.89,1.0,.68),(-.15,.93,1.02,.81),(.5,.96,.87,.68),(.82,.96,.28,.29)]
    start=len(m.vertices); sides=20
    for y,z,rx,rz in rings:
        m.vertices.extend((rx*math.cos(i*math.tau/sides),y,z+rz*math.sin(i*math.tau/sides)) for i in range(sides))
    for level in range(len(rings)-1):
        for i in range(sides):
            j=(i+1)%sides
            m.face((start+level*sides+i,start+level*sides+j,start+(level+1)*sides+j,start+(level+1)*sides+i),'stone_light')
    last=start+(len(rings)-1)*sides; m.face((last+i for i in range(sides)),'stone')
    inner=len(m.vertices)
    m.vertices.extend((.5*math.cos(i*math.tau/sides),-.25,.83+.23*math.sin(i*math.tau/sides)) for i in range(sides))
    for i in range(sides):
        j=(i+1)%sides
        m.face((start+i,inner+i,inner+j,start+j),'ink')
    m.face((inner+i for i in reversed(range(sides))),'ink')
    m.begin_part('HeavyFrogFeet')
    for side in (-1,1):
        m.tube([(side*.77,-.15,.87),(side*1.13,-.23,.48),(side*1.04,-.6,.19)],
               [.26,.28,.20],'stone_light',9)
        m.ellipsoid((side*.91,.55,.38),(.47,.47,.33),'stone',6,12)
        m.tube([(side*.9,.52,.47),(side*1.27,.58,.27),(side*1.27,.1,.09)],[.27,.24,.14],'stone',8)
        for toe in range(3):
            m.ellipsoid((side*(.91+toe*.11),-.70,.11),(.11,.24,.10),'stone_light',4,9)
    m.begin_part('TombstoneCarapace')
    m.profile([(-.79,1.21),(.79,1.21),(.83,2.22),(.65,2.7),(.25,2.96),
               (-.22,2.98),(-.62,2.75),(-.8,2.24)],.50,'stone',.40)
    m.profile([(-.67,1.35),(.65,1.35),(.67,2.20),(.50,2.6),(0,2.80),(-.49,2.64),(-.64,2.20)],.08,'stone_light',.095)
    m.bevel_box((0,.025,2.23),(.16,.12,.78),'stone_dark',.035)
    m.bevel_box((0,-.01,2.36),(.56,.12,.15),'stone_dark',.025)
    m.begin_part('MossAndBrokenFace')
    for x,y,z,s in [(-.68,.04,2.67,.19),(.58,.10,2.64,.17),(-.82,-.32,1.43,.2),
                    (.78,-.3,1.5,.19),(.22,.67,1.56,.22),(-.35,.74,1.5,.21),(.8,.55,.64,.17)]:
        m.ellipsoid((x,y,z),(s,s*.9,s*.65),'moss',4,8)
    for side in (-1,1):
        m.tube([(side*.72,-.77,1.27),(side*.60,-.83,1.43),(side*.44,-.84,1.42)], [.037]*3,'stone_dark',5)
    stone_cracks(m,[[(-.68,-.07,2.34),(-.48,-.095,2.20),(-.5,-.09,1.99)],
                     [(.42,-.78,1.14),(.63,-.68,1.18),(.79,-.53,1.03)],
                     [(-.50,.88,1.11),(-.29,.87,1.34),(-.10,.88,1.31)]])
    return (0,-.64,.8),'moss_relic','Rebuilt thick amphibian stone body with real recessed hollow mouth, back tombstone carapace, crouched paws, stone fissures and moss.'


def grave_key(m):
    m.begin_part('BrokenIronKeyBow')
    m.ring((-.40,0,2.64),(.67,.73),.17,'iron',22,7,start=.20,sweep=5.65)
    m.ring((-.40,-.03,2.64),(.69,.75),.042,'iron_edge',22,4,start=.25,sweep=5.60)
    m.tube([(-.02,0,2.09),(.28,0,1.53),(.61,0,.95),(.85,0,.52)],[.20,.17,.17,.21],'iron',10)
    for x,z in [(.32,1.51),(.69,.80)]:
        m.ellipsoid((x,0,z),(.24,.23,.13),'iron_edge',5,10)
    m.begin_part('KeyTeethWalkingLegs')
    m.rotated_box((.91,0,.87),(.6,.31,.25),'iron',(0,.40,0),.045)
    m.rotated_box((1.06,0,.61),(.49,.31,.25),'iron',(0,.40,0),.045)
    for pts in [[(.66,0,.8),(.91,-.04,.38),(.92,-.27,.15),(1.17,-.39,.14)],
                [(.43,.08,1.1),(-.01,.1,.80),(-.11,-.1,.45),(-.38,-.39,.3)]]:
        m.tube(pts,[.1,.10,.10,.065],'iron',6)
        m.bevel_box(pts[-1],(.34,.24,.14),'iron_edge',.035)
    m.begin_part('BlueFuneraryScarf')
    m.ring((.06,0,2.06),(.26,.17),.14,'blue_cloth',12,6)
    m.ribbon([(.13,-.22,2.03),(.65,-.19,2.19),(1.20,-.02,2.10),(1.64,.06,2.28)],
             [.43,.38,.36,.09],'blue_cloth',.12)
    m.ribbon([(.05,-.19,1.98),(-.05,-.3,1.53),(.02,-.19,1.12),(-.17,-.1,.94)],
             [.4,.3,.23,.06],'blue_cloth',.10)
    stone_cracks(m,[[(-.91,-.10,2.92),(-.76,-.15,3.11)],[(.41,-.17,1.35),(.48,-.18,1.13)]],'rust',.023)
    return (-.40,-.04,2.64),'relic_glint','Substantially rebuilt dark fractured iron key, diagonal shaft, key-bit walking legs, substantial blue scarf knot and trailing torn cloth.'


def mourning_ribbon(m):
    m.begin_part('FuneralBowLoops')
    for side in (-1,1):
        m.ring((side*.86,.02,2.29 if side>0 else 2.39),(.82,.53 if side>0 else .65),.22,'cloth',20,8)
        m.ribbon([(side*.1,-.02,2.22),(side*.8,-.19,2.42),(side*1.47,.04,2.78)],
                 [.34,.55,.19],'cloth_edge',.09)
    m.ellipsoid((0,-.08,2.18),(.43,.35,.44),'cloth',7,16)
    m.begin_part('StitchedMouth')
    m.tube([(-.3,-.405,2.17),(0,-.44,2.22),(.3,-.40,2.16)],[.045,.035,.04],'ink',6)
    for i in range(6):
        x=-.30+i*.12; z=2.18+.04*math.cos(i*.8)
        m.tube([(x-.027,-.438,z-.10),(x+.035,-.449,z+.10)],[.02,.02],'bone',5)
    m.begin_part('FloatingTatteredTails')
    for side in (-1,1):
        lift=.32 if side<0 else 0
        bulged_strip(m,[(side*.17,.09,2.08),(side*.41,-.12,1.85),(side*.52,-.05,1.57),
                       (side*.72,.09,1.23),(side*.83,.14,.96+lift*.5),
                       (side*1.15,.02,.65+lift),(side*1.32,-.06,.55+lift),(side*1.77,-.01,.84+lift)],
                     [.52,.60,.60,.68,.75,.9,.85,.04],'cloth',.21)
        m.ribbon([(side*.30,-.16,1.89),(side*.61,-.25,1.38),(side*.95,-.09,.92),(side*1.47,-.20,.60)],
                 [.11,.13,.16,.07],'cloth_edge',.08)
        for j in range(3):
            m.ribbon([(side*(1.02+j*.18),-.02,.75),(side*(1.17+j*.20),-.1,.40-j*.08)],
                     [.25,.018],'cloth',.08)
    return (0,-.3,2.18),'mourning_stitch','Two volumetric funeral-bow loops, a stitched central knot and asymmetrically folded/frayed floating ribbon tails; no generic body.'


def wilted_sprout(m):
    m.begin_part('BentStemAndRootFeet')
    m.tube([(0,0,.2),(-.28,.0,.70),(.02,.03,1.25),(-.12,0,1.92),(.06,0,2.40)],
           [.27,.23,.17,.14,.16],'green',10)
    for side in (-1,1):
        m.tube([(0,0,.31),(side*.49,.06,.2),(side*.70,-.3,.05),(side*.92,-.35,.04)],
               [.2,.17,.09,.025],'bark',8)
        m.tube([(side*.51,.07,.2),(side*.69,.49,.05)],[.13,.025],'ochre',6)
    m.begin_part('ShadowFaceUnderOchrePetals')
    m.ellipsoid((-.1,-.24,2.53),(.62,.47,.58),'ink',8,18)
    tiny_eyes(m,(-.08,-.691,2.48),.20,.065,.14)
    for i in range(6):
        angle=i*math.tau/6
        x=math.cos(angle); y=math.sin(angle)
        final_z=2.46 if y<-.5 else 2.06
        pts=[(-.1+x*.16,y*.13,2.93),(-.1+x*.40,y*.35,3.05),(-.1+x*.60,y*.48,2.98),
             (-.1+x*.76,y*.61,2.73),(-.1+x*.83,y*.65,2.58),(-.1+x*.85,y*.63,final_z)]
        bulged_strip(m,pts,[.06,.5,.65,.64,.40,.03],'petal' if i%2 else 'ochre',.19)
        m.tube([(px,py-.09,pz) for px,py,pz in pts[1:-1]],[.018]*4,'ochre',5)
    m.begin_part('WiltedSideLeaf')
    m.tube([(-.12,0,1.18),(.49,.04,1.8),(.93,.03,1.83),(1.17,-.03,1.52)],
           [.10,.1,.08,.03],'green',7)
    bulged_strip(m,[(.9,.06,1.86),(1.13,.04,1.74),(1.19,.03,1.61),(1.28,-.10,1.13),(1.14,-.19,.71)],
                 [.06,.38,.48,.42,.025],'green',.17)
    m.tube([(-.28,.03,2.84),(-.43,.04,3.13),(-.22,.05,3.30),(.05,.03,3.22)],
           [.13,.11,.07,.025],'petal',8)
    return (-.10,-.55,2.52),'wilted_pollen','Distinct wilted plant: twisted stem, branching root feet, dark face nested below overlapping ochre petals, dying drooping side leaf.'


def ink_imp(m):
    m.begin_part('SealedLetter')
    m.rotated_box((0,0,.61),(2.40,.45,1.32),'paper',(0,.04,0),.07)
    m.profile([(-1.17,.06),(0,.80),(1.17,.06)],.08,'paper_light',-.265)
    m.profile([(-1.16,1.22),(1.16,1.22),(0,.52)],.08,'paper_light',-.31)
    m.ellipsoid((0,-.386,.59),(.24,.07,.24),'red',6,14)
    m.ring((0,-.46,.59),(.14,.14),.025,'ochre',14,4)
    m.begin_part('GlossyInkEntity')
    m.ellipsoid((0,.02,1.69),(.74,.47,.72),'ink',9,20)
    tiny_eyes(m,(0,-.435,1.86),.29,.135,.215)
    for side in (-1,1):
        m.profile([(side*.36,2.17),(side*.91,2.90),(side*.73,2.27),(side*.64,1.98)],.27,'paper_light',.1)
        m.profile([(side*.40,2.25),(side*.76,2.69),(side*.65,2.26)],.045,'paper',-.06)
        m.tube([(side*.56,.04,1.45),(side*.94,-.05,1.65),(side*1.16,-.2,1.4),
                (side*1.1,-.3,1.06)],[.16,.14,.1,.035],'ink',10)
        m.tube([(side*.55,-.27,1.35),(side*.74,-.32,1.14),(side*.87,-.3,1.29)], [.15,.12,.03],'ink',8)
    m.tube([(-.55,.27,1.92),(-.98,.17,2.06),(-1.18,.05,2.28),(-.98,-.01,2.36),(-.83,.0,2.26)],
           [.16,.13,.09,.05,.02],'ink',8)
    for x,y,z in [(-1.29,-.14,.31),(1.26,.02,.16),(-.9,.21,2.44)]:
        m.ellipsoid((x,y,z),(.1,.11,.13),'ink',5,10)
    stone_cracks(m,[[(-.94,-.317,.16),(-.72,-.325,.35),(-.64,-.32,.27)],
                     [(.85,-.365,.78),(.64,-.35,.96),(.49,-.34,.99)]],'ochre',.012)
    return (0,-.45,1.85),'ink_splatter','Substantially reworked letter-born ink entity: deep ink head with cream eyes, folded parchment ears, crawling ink tendrils and thick sealed envelope.'


def lost_locket(m):
    m.begin_part('OpenedBrassLocket')
    for x,y,rx in [(0.55,0,.72),(-.83,.10,.57)]:
        oval_shell(m,x,y,1.43,rx,1.08,.13,.20,'gold_edge')
        m.ellipsoid((x,y+.03,1.43),(rx-.10,.13,.97),'gold',7,18)
        if x>0: m.ellipsoid((x,-.15,1.43),(.57,.042,.90),'ink',7,18)
    m.tube([(-.15,.02,.57),(-.15,.02,2.37)],[.13,.13],'gold',9)
    for z in (.7,1.2,1.7,2.2): m.ellipsoid((-.15,-.01,z),(.145,.14,.08),'gold_edge',4,8)
    m.ring((.55,.02,2.75),(.25,.29),.075,'gold',16,6)
    m.begin_part('GhostHandprint')
    m.ellipsoid((.57,-.225,1.40),(.17,.022,.23),'ghost',6,12)
    for x,z,height in [(.38,1.66,.27),(.52,1.75,.35),(.67,1.71,.30),(.79,1.57,.22)]:
        m.ellipsoid((x,-.225,z),(.042,.019,height/2),'ghost',4,10)
    m.ellipsoid((.33,-.225,1.4),(.07,.02,.14),'ghost',4,9)
    m.begin_part('EngravedLeftPortrait')
    m.tube([(-.84,-.043,.74),(-.80,-.045,1.27),(-.88,-.044,1.92)], [.025]*3,'ochre',5)
    for side in (-1,1):
        for i in range(3):
            x=-.82+side*.14; z=1.1+i*.25
            m.ellipsoid((x,-.052,z),(.13,.03,.07),'gold_edge',4,9)
    for x,z in [(1.18,2.00),(.92,.46),(-1.26,1.91)]:
        m.bevel_box((x,-.08,z),(.22,.25,.18),'gold',.04)
    return (.57,-.24,1.45),'ghost_handprint','Open paired brass locket with substantial metal depth, hinged asymmetry, recessed dark portrait and authored pale spectral handprint; no pet body.'


def ashen_book(m):
    m.begin_part('CharredBookAndPageBlock')
    m.bevel_box((0,0,.65),(2.50,1.50,.5),'paper',.08)
    m.bevel_box((0,0,.35),(2.68,1.66,.19),'iron',.07)
    m.profile([(-1.37,.82),(-.1,2.00),(1.2,1.45),(1.17,1.26),(-.08,1.75),(-1.28,.64)],
              1.35,'cloth',.07)
    m.profile([(-.96,.84),(.97,.89),(.16,1.50),(-.27,1.65)],.10,'ink',-.8)
    tiny_eyes(m,(0,-.865,1.07),.30,.11,.15)
    for side in (-1,1):
        for i in range(5):
            m.rotated_box((side*.77,-.14,.10+i*.07),(.58+.04*i,.72,.055),'paper',(0,0,side*.07),.018)
    m.begin_part('RaisedBurntPageWing')
    m.profile([(.67,.96),(1.14,1.18),(1.13,1.42),(1.32,1.54),(1.19,1.77),(1.47,1.95),
               (1.4,2.19),(1.78,2.72),(1.80,2.50),(1.96,2.39),(1.85,2.22),
               (1.94,2.09),(1.72,1.97),(1.84,1.81),(1.58,1.52),(1.57,1.27),(1.31,1.03)],
              .12,'paper_light',.17)
    m.ribbon([(1.11,.08,1.09),(1.45,.01,1.66),(1.62,.10,2.12),(1.79,.17,2.68)],
             [.045,.07,.06,.02],'paper',.07)
    for i in range(3):
        m.ribbon([(1.22+i*.09,.10,1.47+i*.19),(1.64+i*.08,.03,1.51+i*.26)],
                 [.24,.028],'paper',.08)
    m.begin_part('BurnScarsAndBinding')
    for z in (.49,.59,.72):
        m.tube([(-1.10,-.78,z),(-.20,-.79,z-.018),(.95,-.76,z)],[.016]*3,'ochre',4)
    stone_cracks(m,[[(-1.10,-.64,1.02),(-.69,-.64,1.15),(-.64,-.64,1.44),(-.14,-.64,1.71)],
                     [(.23,-.65,1.7),(.75,-.65,1.52),(.77,-.65,1.32)]],'rust',.021)
    return (0,-.9,1.05),'ember_pages','Remodeled charred walking book with deep page-block, angular opening, visible dark eyes, layered page feet, raised torn parchment wing and burnt gilding.'


def lantern_lurker(m):
    m.begin_part('CageWithTrappedGreenLight')
    m.lathe((0,0,.46),[(0,.58),(.1,.79),(.25,.81),(.34,.65)],'iron',14,.04)
    m.lathe((0,0,1.78),[(0,.75),(.15,.94),(.28,.93),(.58,.37)],'iron_edge',14,.04)
    m.ellipsoid((0,.01,1.30),(.53,.49,.68),'green_glow',8,18)
    for i in range(8):
        a=i*math.tau/8; x=math.cos(a); y=math.sin(a)
        m.tube([(x*.70,y*.63,.67),(x*.67,y*.62,1.35),(x*.73,y*.65,1.94)],
               [.08,.065,.08],'iron',7)
    m.begin_part('CrookedHandleAndWalkingClaws')
    m.ring((-.23,0,2.37),(.74,.61),.10,'rust',20,7,start=-.1,sweep=5.4)
    m.ring((-.8,0,2.19),(.11,.17),.043,'gold',12,5)
    for x,y in [(-.63,-.45),(.64,-.37),(-.60,.44),(.65,.40)]:
        m.tube([(x,y,.95),(x*1.50,y*1.34,.63),(x*1.48,y*1.52,.24),(x*1.8,y*1.64,.10)],
               [.16,.18,.12,.09],'iron',9)
        for toe in range(3):
            m.ellipsoid((x*1.8+(toe-1)*.10,y*1.64-.13,.09),(.08,.20,.08),'iron_edge',4,8)
    m.begin_part('TarnishAndGlassVeins')
    for a in (.2,1.6,3.4,4.7):
        m.tube([(math.cos(a)*.51,math.sin(a)*.47,.83),
                (math.cos(a+.1)*.53,math.sin(a+.1)*.50,1.23),
                (math.cos(a)*.44,math.sin(a)*.42,1.69)],[.029,.033,.015],'green',5)
    return (0,-.12,1.34),'trapped_green_light','Open deep cage surrounds bright green haunted core, eight uneven iron bars, crooked loop handle and four crouched jointed claw legs.'


def hourglass_hound(m):
    m.begin_part('HourglassTorso')
    # Torso has genuine open waist framed by four curved sandstone stanchions.
    m.bevel_box((.15,0,2.02),(1.33,.82,.18),'sand_light',.07)
    m.bevel_box((.15,0,.77),(1.33,.82,.2),'sand',.07)
    for x,y in [(-.42,-.33),(.72,-.33),(-.42,.33),(.72,.33)]:
        m.tube([(x,y,.78),(x*.9,y*1.04,1.08),(.15+(x-.15)*.62,y*.88,1.43),
                (x*.96,y,1.82),(x,y,2.13)],[.13,.11,.09,.11,.15],'sand',8)
    # Dark sand is a double cone, surrounded by four thin visible glass rims.
    m.lathe((.15,0,.83),[(0,.47),(.10,.41),(.4,.10),(.60,.025)],'ink',14)
    m.lathe((.15,0,1.43),[(0,.025),(.29,.25),(.48,.44),(.55,.44)],'stone_dark',14)
    for i in range(5): m.ellipsoid((.15,-.13,1.34+i*.055),(.022,.022,.029),'sand_light',3,6)
    m.begin_part('SandstoneHoundHeadAndLegs')
    m.ellipsoid((-.87,-.07,1.10),(.49,.40,.52),'sand',7,14)
    m.profile([(-1.47,.59),(-.92,.76),(-.56,1.34),(-.64,1.55),(-1.03,1.35)],.67,'sand_light',-.05)
    for y in (-.36,.3):
        m.profile([(-1.12,1.40),(-1.0,2.17),(-.61,1.50)],.16,'sand',y)
    m.ellipsoid((-1.03,-.45,1.2),(.17,.045,.23),'stone_dark',5,12)
    m.ellipsoid((-1.03,-.487,1.2),(.10,.04,.16),'white_glow',5,10)
    m.ellipsoid((-1.41,-.04,.71),(.12,.23,.10),'ink',4,9)
    for x,y in [(-.71,-.39),(-.73,.34),(.77,-.37),(.80,.34)]:
        m.tube([(x,y,1),(x-.12,y*1.2,.54),(x-.30,y*1.30,.13)],
               [.18,.16,.13],'sand',9)
        m.ellipsoid((x-.36,y*1.3,.12),(.30,.18,.11),'sand_light',4,10)
    m.tube([(.84,.04,1.12),(1.29,.04,1.29),(1.51,.01,1.71),(1.3,-.03,2.06)],
           [.20,.17,.13,.045],'sand',9)
    stone_cracks(m,[[(-1.06,-.48,1.47),(-.86,-.47,1.31),(-.79,-.45,1.43)],
                     [(.72,-.43,1.98),(.66,-.43,1.84),(.75,-.43,1.75)]],'ochre',.018)
    return (.15,-.09,1.39),'falling_sand','Distinct quadrupedal sandstone relic with an open curved hourglass torso, two dark sand cones and falling-grain geometry, pointed hound skull and curled stone tail.'


def nail_beetle(m):
    m.begin_part('CoffinNailCarapace')
    m.ellipsoid((0,0,.48),(.54,.64,.4),'iron',7,16)
    # Coffin nail lies diagonally along the deep beetle back and forms its armor.
    m.tube([(0,-.5,.54),(0,.23,.71),(0,1.04,.98)],[.23,.32,.37],'iron',7)
    m.rotated_box((0,1.18,1.09),(.99,.32,.74),'iron_edge',(.40,0,0),.09)
    m.ellipsoid((0,-.55,.53),(.43,.32,.28),'iron',7,14)
    tiny_eyes(m,(0,-.827,.55),.21,.102,.135)
    m.begin_part('SixBentIronLegs')
    for side in (-1,1):
        for i in range(3):
            y=-.32+i*.34
            m.tube([(side*.35,y,.56),(side*.71,y-.14,.76),(side*1.03,y-.21,.21),
                    (side*1.05,y-.34,.08)],[.10,.13,.085,.04],'iron',7)
    m.begin_part('RustAndMoss')
    for x,y,z in [(-.21,-.09,.86),(.20,.68,1.05),(-.29,1.21,1.32),(.28,.98,1.26)]:
        m.ellipsoid((x,y,z),(.13,.15,.07),'moss',4,8)
    stone_cracks(m,[[(-.25,-.2,.78),(-.22,.16,1.01),(-.13,.33,1.13)],
                     [(.30,.61,1.65),(.29,.75,1.60),(.12,.90,1.55)]],'rust',.026)
    return (0,-.81,.55),'rust_dust','Iron beetle with coherent coffin-nail carapace rather than a generic insect shell; thick nail head, six jointed legs, pale eyes, rust edges and moss.'


def pale_guest(m):
    m.begin_part('CrookedWoodPortraitFrame')
    # Each frame rail is independently skewed while maintaining a deep aperture.
    for x in (-1.0,1.0):
        m.rotated_box((x,0,1.56),(.21,.36,2.74),'wood',(0,x*.075,0),.06)
    for z in (.26,2.86):
        m.rotated_box((0,0,z),(2.33,.38,.24),'wood',(0,.035,0),.07)
    for x in (-1.05,1.05):
        for z in (.26,2.86): m.rotated_box((x,-.07,z),(.38,.45,.34),'gold',(0,0,x*z*.04),.07)
    m.profile([(-.88,.4),(.85,.4),(.85,2.69),(.31,2.66),(.22,2.12),(-.21,2.01),(-.38,1.57),(-.83,1.49)],
              .075,'paper',.18)
    m.bevel_box((0,.25,1.56),(1.87,.12,2.35),'ink',.06)
    m.begin_part('GhostPeeringOut')
    m.ellipsoid((.23,-.11,1.31),(.58,.43,.76),'ghost',8,18)
    m.tube([(.17,-.04,1.53),(.04,.03,1.99),(.13,.13,2.26)],[.36,.24,.015],'ghost',12)
    tiny_eyes(m,(.23,-.51,1.65),.20,.075,.17,'eye')
    for x in (-.35,.7):
        m.ellipsoid((x,-.28,.63),(.17,.21,.22),'ghost',5,12)
        for i in range(3): m.tube([(x+(i-1)*.07,-.37,.70),(x+(i-1)*.07,-.48,.47)], [.041,.025],'ghost',6)
    m.begin_part('PortraitLeafPatternAndWear')
    for x,z in [(-.69,2.31),(-.59,2.10),(-.74,1.90),(.48,.44),(.1,.42)]:
        m.profile([(x-.07,z),(x-.03,z+.13),(x+.10,z+.2),(x+.04,z+.06)],.035,'ochre',.12)
    stone_cracks(m,[[(-1.09,-.19,.83),(-1.1,-.2,1.42),(-1.07,-.19,1.88)],
                     [(.66,-.20,2.86),(.31,-.20,2.83),(.15,-.20,2.90)]],'ochre',.02)
    return (.24,-.47,1.65),'portrait_ghost','Pale tapered ghost genuinely emerges through torn portrait canvas and deep skewed wooden frame, grips the lower rail with small hands; authored leaf motifs and worn joinery.'


def cold_teacup(m):
    m.begin_part('CrackedPorcelainCupAndSaucer')
    m.lathe((0,0,0),[(0,.68),(.09,1.02),(.19,1.2),(.26,1.1)],'porcelain',24,.03)
    hollow_lathe(m,(0,0,.23),[(0,.33),(.22,.64),(.65,.86),(1.03,.99),
                              (1.10,1.03),(1.10,.91),(.62,.73),(.20,.49),(.11,.22)],'porcelain',24)
    m.ring((.98,.02,.84),(.38,.43),.11,'porcelain',20,7)
    m.lathe((0,0,1.19),[(0,.87),(.03,.87)],'ink',24)
    m.begin_part('CurledShadowSteam')
    m.tube([(0,0,1.20),(-.02,0,1.52),(.28,0,1.86),(.4,.02,2.15),(.18,.04,2.4),
            (-.16,.04,2.37),(-.26,.01,2.13),(-.12,-.04,2.04)],
           [.2,.19,.15,.12,.09,.065,.05,.015],'ink',12)
    for x,y,z in [(-.54,.02,1.64),(.56,.07,2.12)]: m.ellipsoid((x,y,z),(.09,.08,.10),'ink',5,10)
    m.begin_part('BlueBotanicalPaintAndCracks')
    for x in (-.57,0,.53):
        m.tube([(x,-.75,.51),(x+.05,-.88,.74),(x-.03,-.94,1.02)],[.016]*3,'blue_paint',4)
        for sign in (-1,1):
            m.ellipsoid((x+sign*.10,-.82,.66),(.11,.024,.046),'blue_paint',4,9)
            m.ellipsoid((x+sign*.075,-.91,.88),(.087,.022,.05),'blue_paint',4,9)
    stone_cracks(m,[[(-.34,-.936,1.34),(-.24,-.885,1.03),(-.37,-.803,.82),(-.15,-.68,.55)],
                     [(.42,-.847,1.15),(.56,-.78,.95),(.49,-.72,.71)],
                     [(-.75,-.66,.20),(-.43,-.87,.15),(-.29,-.91,.12)]],'ochre',.016)
    return (.05,-.03,1.85),'cold_shadow','Thick genuinely hollow porcelain bowl with saucer and loop handle, dark liquid, curling three-dimensional ink steam, blue botanical decoration and large warm fissures.'


def coin_crawler(m):
    m.begin_part('FuneraryCoinCarapace')
    # Coin faces upwards with a real projecting rim; eye creature hides under it.
    m.lathe((0,0,.45),[(0,.89),(.13,1.17),(.30,1.24),(.42,1.18),(.47,.96)],'iron',24,.025)
    start=len(m.vertices)
    m.ring((0,0,.98),(1.10,1.10),.08,'iron_edge',24,6)
    # The legacy ring is X/Z; rotate the rim to the horizontal coin plane.
    # The coin's embossed funerary gate is drawn in its top X/Y plane.
    from mathutils import Matrix, Vector
    m.transform_since(start,Matrix.Translation(Vector((0,0,.98)))@Matrix.Rotation(math.pi/2,4,'X')@Matrix.Translation(Vector((0,0,-.98))))
    m.begin_part('EmbossedFuneralGate')
    for x in (-.65,-.32,0,.32,.65):
        m.tube([(x,-.45,.944),(x,.42,.955)],[.027,.027],'stone_dark',5)
        m.ellipsoid((x,.49,.96),(.05,.08,.035),'iron_edge',3,8)
    m.tube([(-.75,-.3,.95),(.75,-.3,.95)],[.033,.033],'iron_edge',5)
    m.tube([(-.73,.23,.95),(0,.46,.96),(.73,.23,.95)],[.031,.04,.031],'iron_edge',5)
    m.begin_part('CrawlerBodyEyesAndPaws')
    m.ellipsoid((0,-.27,.40),(.62,.57,.35),'iron',7,14)
    tiny_eyes(m,(0,-.795,.38),.22,.12,.095)
    for side in (-1,1):
        for y in (-.44,.37):
            m.tube([(side*.62,y,.58),(side*.99,y*.95,.63),(side*1.24,y*1.33,.12)],
                   [.17,.19,.11],'iron',9)
            m.bevel_box((side*1.25,y*1.33,.09),(.27,.32,.16),'iron_edge',.04)
    for x,y in [(-.84,.67),(.73,.65),(-1.0,-.23)]: m.ellipsoid((x,y,.84),(.17,.18,.09),'moss',4,8)
    # Thin crescent on coin lid.
    start=len(m.vertices)
    m.ring((-.30,0,1.13),(.19,.21),.033,'ghost',12,5,start=.32,sweep=4.5)
    m.transform_since(start,Matrix.Translation(Vector((0,0,1.13)))@Matrix.Rotation(math.pi/2,4,'X')@Matrix.Translation(Vector((0,0,-1.13))))
    return (0,-.81,.38),'coin_moss','Broad funeral coin over a hidden four-legged crawler, projecting rim, embossed cemetery gate and crescent, warm corroded edges, pale eyes beneath lip.'


def umbrella_wraith(m):
    m.begin_part('FoldedUmbrellaBodyAndHandle')
    m.tube([(0,0,.4),(0,0,1.31),(.03,0,2.68),(0,0,3.30)],[.075,.10,.06,.09],'wood',9)
    m.ring((.16,0,.30),(.22,.24),.074,'gold',14,6,start=.28,sweep=4.6)
    m.profile([(-.19,.86),(.28,.91),(.53,2.13),(.15,3.14),(-.1,2.79),(-.42,1.85)],.48,'cloth',.05)
    for x in (-.26,0,.27): m.tube([(x*.4,-.23,1.04),(x,-.22,1.97),(x*.33,-.19,2.89)], [.025,.023,.015],'iron_edge',5)
    m.ellipsoid((.02,-.24,2.05),(.115,.07,.20),'white_glow',5,12)
    m.begin_part('TatteredWingLikeFolds')
    for side in (-1,1):
        m.ribbon([(side*.20,.08,2.07),(side*.81,.06,2.13),(side*1.45,.03,1.83),
                  (side*1.81,-.07,1.40)], [.62,.69,.55,.025],'cloth',.18)
        for i in range(3):
            m.ribbon([(side*(.73+i*.32),-.03,1.97-i*.12),(side*(.65+i*.40),-.20,1.35-i*.13)],
                     [.25,.025],'cloth',.10)
        m.tube([(side*.17,-.16,2.14),(side*.77,-.14,2.19),(side*1.53,-.11,1.79)],
               [.03,.038,.016],'iron_edge',5)
    m.begin_part('BrassFasteners')
    m.bevel_box((0,-.28,1.12),(.55,.14,.15),'gold',.05)
    m.ellipsoid((.07,-.375,1.12),(.063,.035,.063),'gold_edge',4,10)
    m.ellipsoid((0,0,3.23),(.11,.12,.15),'gold_edge',5,10)
    return (.02,-.26,2.06),'umbrella_shadow','Tall folded black umbrella spirit with one glowing eye in the fold, torn bat-like cloth wings, exposed rib seams, brass clasp and curved hook handle.'


COMMON=[
    ('candle_wisp','Candle Wisp',1,candle_wisp),('grave_hopper','Grave Hopper',1,grave_hopper),
    ('grave_key','Grave Key',1,grave_key),('mourning_ribbon','Mourning Ribbon',1,mourning_ribbon),
    ('wilted_sprout','Wilted Sprout',1,wilted_sprout),('ink_imp','Ink Imp',2,ink_imp),
    ('lost_locket','Lost Locket',2,lost_locket),('ashen_book','Ashen Book',2,ashen_book),
    ('lantern_lurker','Lantern Lurker',2,lantern_lurker),('hourglass_hound','Hourglass Hound',2,hourglass_hound),
    ('nail_beetle','Nail Beetle',3,nail_beetle),('pale_guest','Pale Guest',3,pale_guest),
    ('cold_teacup','Cold Teacup',3,cold_teacup),('coin_crawler','Coin Crawler',3,coin_crawler),
    ('umbrella_wraith','Umbrella Wraith',3,umbrella_wraith),
]


def main():
    prototype='--prototype' in sys.argv
    rows=[]
    for id,name,sheet,make in COMMON:
        if prototype and id!='candle_wisp': continue
        # Root is importing the approved prototype. Reuse its exact frozen FBX;
        # preview relighting and ledger aliases never change source identity.
        if id=='candle_wisp' and not prototype and (SOURCE/'candle_wisp_metrics.json').is_file():
            row=json.loads((SOURCE/'candle_wisp_metrics.json').read_text(encoding='utf-8'))
            row['blendSource']=row['source']; row['robloxIntendedSize']=row['intendedRobloxSize']; row['vfxHookRoblox']=row['vfxHook']
            if isinstance(row['designNotes'],str): row['designNotes']=[row['designNotes']]
            row['roundtripValidation']=validate_asset(row)
            row['fbxExported']=True; row['locallyValidated']=True
            bpy=__import__('bpy'); bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'candle_wisp.blend'))
            render(bpy.data.objects['candle_wisp'],SOURCE/'candle_wisp_preview.png')
            rows.append(row)
            continue
        reset(); m=PaintedSculpt(); hook,profile,notes=make(m)
        obj,row=m.finish(id,name,'COMMON',f'rework-{sheet:02d}-common.png',hook,profile,notes)
        render(obj,SOURCE/(id+'_preview.png'),azimuth=-1.25 if id=='nail_beetle' else -.28)
        row['roundtripValidation']=validate_asset(row)
        row['fbxExported']=True; row['locallyValidated']=True
        (SOURCE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
        rows.append(row)
        print(f'COMMON_REWORK {id} triangles={row["triangles"]} bounds={row["intendedRobloxSize"]} colors={row["paintedColorCount"]}')
    (SOURCE/('common_prototype_report.json' if prototype else 'common_report.json')).write_text(json.dumps({'assets':rows},indent=2)+'\n',encoding='utf-8')
    if not prototype:
        (SOURCE/'common_geometry.json').write_text(json.dumps({'assets':rows},indent=2)+'\n',encoding='utf-8')
        (SOURCE/'common_validation.json').write_text(json.dumps({'assets':[r['roundtripValidation'] for r in rows]},indent=2)+'\n',encoding='utf-8')


if __name__=='__main__': main()
