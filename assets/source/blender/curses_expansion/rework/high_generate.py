"""Author the 21 Legendary/Mythic/Secret reference-driven original meshes.

Blender 5.2: --background --factory-startup --python this.py -- <id|all>
The geometry is deliberately authored here: shaped plates, real empty rib cages,
bell interiors, articulated joints and asymmetric hand-shaped volumes. This
script never changes gameplay, catalog data or fabricated imported asset IDs.
"""
from pathlib import Path
import sys, math, json
import bpy, bmesh
from mathutils import Vector, Matrix

sys.dont_write_bytecode=True
SOURCE=Path(__file__).resolve().parent
sys.path.insert(0,str(SOURCE))
from rework_geometry import Sculpt, PALETTE, reset, render, validate_asset, material

PALETTE.update({
 'star_iron':(.115,.14,.18),'star_edge':(.43,.47,.52),'star_wear':(.65,.63,.59),
 'white_glow':(.79,.93,1),'cold_white':(.88,.91,.95),'obsidian':(.075,.085,.105),
 'indigo':(.12,.14,.27),'indigo_edge':(.28,.30,.45),'ivory':(.79,.74,.61),
 'bone_high':(.94,.88,.72),'ruby':(.53,.018,.05),'ruby_edge':(.93,.09,.12),
 'thorn':(.18,.19,.105),'thorn_edge':(.38,.32,.19),'patina':(.17,.40,.32),
 'copper':(.47,.30,.14),'copper_edge':(.75,.57,.32),'jade':(.14,.49,.37),
 'jade_glow':(.42,.87,.68),'bark_dark':(.15,.115,.065),'bark_light':(.43,.31,.16),
 'moss_dark':(.30,.35,.105),'moss_light':(.58,.61,.22),'deep_water':(.025,.12,.17),
 'sea_glass':(.10,.45,.54),'sea_edge':(.38,.78,.79),'coral':(.80,.32,.17),
 'burial':(.085,.07,.085),'burial_edge':(.22,.18,.21),'parchment':(.90,.81,.64),
 'inkblack':(.025,.018,.025),'charcoal':(.18,.16,.18),'brass':(.53,.37,.14),
 'brass_edge':(.82,.63,.31),'linen':(.70,.68,.62),'linen_high':(.91,.86,.76),
 'plague_glow':(.48,.73,.14),'gold_glow':(.99,.78,.32),'moon_glow':(.69,.97,.87),
 'rose_petal':(.45,.020,.046),'rose_rim':(.72,.055,.10),'rose_glint':(.88,.20,.24),
 'rose_core':(.62,.041,.074),'royal_cloth':(.96,.90,.79),'royal_shadow':(.62,.59,.53),
 'royal_edge':(.99,.95,.85),'paper_black':(.038,.028,.042),'paper_wear':(.34,.28,.29),
})

class PaintedSculpt(Sculpt):
    """Original material-specific worn paint on actual UV-mapped closed volumes.

    Extra edge cuts create spatial paint control across broad faces, without
    relying on random per-face colors or a single tint for an entire creature.
    Metal has pale chipped edges/rust, copper has broad verdigris islands,
    stone has mineral mottling, wood follows longitudinal bark and cloth shows
    softer broad folds. These painted surfaces export with the actual FBX.
    """
    def object(self,name,mat=None):
        mins=[min(v[a] for v in self.vertices) for a in range(3)]
        maxs=[max(v[a] for v in self.vertices) for a in range(3)]
        self.offset=[(lo+hi)*.5 for lo,hi in zip(mins,maxs)]
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v[a]-self.offset[a] for a in range(3)) for v in self.vertices],[],self.faces)
        mesh.update()
        keys=list(PALETTE)
        bm=bmesh.new(); bm.from_mesh(mesh); tag=bm.faces.layers.int.new('PaintMaterial')
        for f,key in zip(bm.faces,self.face_materials): f[tag]=keys.index(key)
        longedges=[e for e in bm.edges if e.calc_length()>.42]
        if longedges: bmesh.ops.subdivide_edges(bm,edges=longedges,cuts=2,use_grid_fill=True)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(mesh); bm.free(); mesh.update()
        mesh.materials.append(mat or material())
        uv=mesh.uv_layers.new(name='CurseMaterialUV')
        colors=mesh.color_attributes.new(name='SACPaintedColor',type='BYTE_COLOR',domain='CORNER')
        mesh.color_attributes.active_color=colors
        mask=mesh.attributes.new(name='SACEmissiveMask',type='FLOAT',domain='CORNER')
        tagdata=mesh.attributes.get('PaintMaterial').data
        grid=math.ceil(math.sqrt(len(keys)))
        glow={'white_glow','jade_glow','plague_glow','gold_glow','moon_glow','ruby_edge','sea_edge'}
        for p in mesh.polygons:
            key=keys[tagdata[p.index].value]; tile=keys.index(key); base=PALETTE[key]
            dominant=max(range(3),key=lambda a:abs(p.normal[a])); axes=[a for a in range(3) if a!=dominant]
            for li in p.loop_indices:
                v=mesh.vertices[mesh.loops[li].vertex_index].co+Vector(self.offset)
                h=(v.z-mins[2])/max(.001,maxs[2]-mins[2])
                u=(v[axes[0]]-mins[axes[0]])/max(.001,maxs[axes[0]]-mins[axes[0]])
                w=(v[axes[1]]-mins[axes[1]])/max(.001,maxs[axes[1]]-mins[axes[1]])
                uv.data[li].uv=((tile%grid+.035+u*.93)/grid,(tile//grid+.035+w*.93)/grid)
                broad=.75+.24*h+.13*math.sin(v.x*2.2+v.y*1.8+v.z*.9)
                grains=math.sin(v.x*19.7+v.y*15.4+v.z*12.3)*math.sin(v.x*8.8-v.z*10.3)
                patch=math.sin(v.x*6.8+v.z*5.2+v.y*2.4)*math.sin(v.z*4.4-v.x*3.1)
                rgb=[c*broad for c in base]
                if key in glow:
                    rgb=[c*(.90+.1*h) for c in base]
                elif key in {'star_iron','star_edge','star_wear','iron','indigo','indigo_edge','obsidian','brass','brass_edge','copper','copper_edge'}:
                    if grains>.35:
                        amount=min(.53,(grains-.35)*1.3)
                        worn=(.62,.62,.59) if key.startswith('star') else (.70,.51,.27)
                        rgb=[a*(1-amount)+b*amount for a,b in zip(rgb,worn)]
                    elif grains<-.40:
                        rgb=[c*.57 for c in rgb]
                elif key in {'patina','jade','deep_water','sea_glass'}:
                    if patch>.05:
                        amount=min(.65,(patch-.05)*1.3)
                        worn=(.65,.41,.20) if key=='patina' else (.34,.67,.54)
                        rgb=[a*(1-amount)+b*amount for a,b in zip(rgb,worn)]
                    if grains>.5: rgb=[c*1.2 for c in rgb]
                elif key in {'bark_dark','bark_light','thorn','thorn_edge'}:
                    stripe=math.sin(v.x*26+v.y*18+math.sin(v.z*2.8)*2.6)
                    rgb=[c*(.76+.23*stripe) for c in rgb]
                    if patch>.30: rgb=[a*.72+b*.28 for a,b in zip(rgb,PALETTE['moss_dark'])]
                elif key in {'ivory','bone_high','cold_white','parchment','linen','linen_high','porcelain'}:
                    rgb=[c*(.88+.1*math.sin(v.z*17+v.x*5)+.12*patch) for c in rgb]
                elif key in {'burial','burial_edge','inkblack','charcoal'}:
                    rgb=[c*(.73+.23*math.sin(v.z*23+v.x*3)) for c in rgb]
                else: rgb=[c*(.92+.19*patch) for c in rgb]
                colors.data[li].color_srgb=tuple(max(.005,min(1,c)) for c in rgb)+(1,)
                mask.data[li].value=1.5 if key in glow else 0
        mesh.attributes.remove(mesh.attributes.get('PaintMaterial'))
        bm=bmesh.new(); bm.from_mesh(mesh); bmesh.ops.triangulate(bm,faces=list(bm.faces)); bm.to_mesh(mesh); bm.free()
        mesh.update(); obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
        return obj

def part(m,name): m.begin_part(name)

def plate(m,outline,depth,key,y=0,edge=None,shrink=.86):
    """Closed shaped armor; its smaller raised face adds physical bevel detail."""
    cx=sum(p[0] for p in outline)/len(outline); cz=sum(p[1] for p in outline)/len(outline)
    chipped=[]
    for i,(x,z) in enumerate(outline):
        nx,nz=outline[(i+1)%len(outline)]; chipped.append((x,z))
        if math.hypot(nx-x,nz-z)>.58 and i%2==0:
            for t,inset in ((.43,0),(.49,.055),(.56,0)):
                px=x+(nx-x)*t; pz=z+(nz-z)*t
                d=math.hypot(cx-px,cz-pz) or 1
                chipped.append((px+(cx-px)*inset/d,pz+(cz-pz)*inset/d))
    m.profile(chipped,depth,key,y)
    if edge:
        inner=[(cx+(x-cx)*shrink,cz+(z-cz)*shrink) for x,z in chipped]
        m.profile(inner,depth*.20,edge,y-depth*.57)
        # A few long inlaid fractures cross the raised face, not uniform noise.
        if max(z for x,z in outline)-min(z for x,z in outline)>.65:
            ax,az=inner[0]; bx,bz=inner[min(2,len(inner)-1)]
            sx=ax*.67+cx*.33; sz=az*.67+cz*.33
            ex=bx*.44+cx*.56; ez=bz*.44+cz*.56
            m.profile([(sx-.013,sz),(sx+.012,sz+.014),(cx+.06,cz+.045),
                       (ex+.013,ez),(ex-.006,ez-.035),(cx+.025,cz-.018)],
                      .012,'obsidian' if key not in {'ivory','bone_high'} else 'thorn_edge',y-depth*.68)

def limb(m,points,radii,key='star_iron',edge='star_edge',sides=7):
    m.tube(points,radii,key,sides)
    for i,p in enumerate(points[1:-1]):
        r=radii[i+1]
        m.ellipsoid(p,(r*1.2,r*.95,r*1.2),edge,3,7)

def claws(m,foot,key='star_edge',scale=1,forward=-1):
    x,y,z=foot
    for dx in (-.16,0,.16):
        m.tube([(x+dx*scale,y,z),(x+dx*1.25*scale,y+forward*.32*scale,z-.11*scale),
                (x+dx*1.35*scale,y+forward*.51*scale,z-.12*scale)],
                [.105*scale,.085*scale,.012*scale],key,5)

def spike(m,a,b,r,key): m.tube([a,b],[r,.007],key,5)

def star(m,center,reach,key='white_glow',points=8,inner=.21,depth=.18):
    x,y,z=center
    outline=[]
    for i in range(points*2):
        angle=math.pi/2+i*math.pi/points
        radius=reach*(1 if i%2==0 else inner)
        if i%4==2: radius*=.73
        outline.append((x+radius*math.cos(angle),z+radius*math.sin(angle)))
    first=len(m.vertices)
    m.vertices.append((x,y-depth,z)); m.vertices.append((x,y+depth,z))
    m.vertices.extend((a,y,b) for a,b in outline)
    count=len(outline)
    for i in range(count):
        j=(i+1)%count
        m.face((first,first+2+i,first+2+j),key)
        m.face((first+1,first+2+j,first+2+i),key)

def chain(m,points,key='iron',r=.07):
    for i,p in enumerate(points):
        start=len(m.vertices)
        m.ring((0,0,0),(.11,.17),r,key,8,5)
        rot=Matrix.Rotation(math.pi/2 if i%2 else 0,4,'Z')
        m.transform_since(start,Matrix.Translation(Vector(p))@rot)

def hollow_bell(m,center,profile,key='patina',sides=14,wall=.10):
    """Closed wall cross-section with a genuine open cavity underneath."""
    x,y,z=center
    path=list(profile)+[(h-wall,max(.035,r-wall)) for h,r in reversed(profile)]
    first=len(m.vertices)
    for h,r in path:
        for i in range(sides):
            t=i*2*math.pi/sides
            m.vertices.append((x+r*math.cos(t),y+r*math.sin(t),z+h))
    for k in range(len(path)):
        nk=(k+1)%len(path)
        for i in range(sides):
            j=(i+1)%sides
            m.face((first+k*sides+i,first+k*sides+j,first+nk*sides+j,first+nk*sides+i),key)

def curved_sheet(m,points,widths,key,thickness=.055,fold=.055,edge=None):
    """Closed folded cloth/paper strip, with width axes transverse to its path.

    Each strip is a lofted volume: seven cross-section points give physical
    folds and two capped skins keep the back and ragged edges real geometry.
    """
    centers=[Vector(p) for p in points]; n=len(centers); cross=7; first=len(m.vertices)
    frames=[]
    for i,p in enumerate(centers):
        t=(centers[min(n-1,i+1)]-centers[max(0,i-1)]).normalized()
        guide=Vector((1,0,0)); a=guide-t*guide.dot(t)
        if a.length<.10: a=Vector((0,1,0))-t*t.y
        a.normalize(); normal=t.cross(a).normalized(); frames.append((a,normal))
    for layer in (-1,1):
        for i,p in enumerate(centers):
            axis,normal=frames[i]
            for j in range(cross):
                u=-1+2*j/(cross-1)
                bend=fold*math.cos(u*math.pi*2)*(0.65+0.35*i/(n-1))
                m.vertices.append(tuple(p+axis*(u*widths[i])+normal*(bend+layer*thickness*.5)))
    span=n*cross
    for i in range(n-1):
        for j in range(cross-1):
            a=first+i*cross+j; b=a+1; c=first+(i+1)*cross+j+1; d=c-1
            facekey=edge if edge and j in (0,cross-2) else key
            m.face((a,b,c,d),facekey); m.face((a+span,d+span,c+span,b+span),facekey)
    for i in range(n-1):
        for j in (0,cross-1):
            a=first+i*cross+j; b=first+(i+1)*cross+j
            m.face((a,b,b+span,a+span),edge or key)
    for i in (0,n-1):
        for j in range(cross-1):
            a=first+i*cross+j; b=a+1
            m.face((a,a+span,b+span,b),edge or key)

def cupped_petal(m,center,theta,scale,key='rose_petal',front=0):
    """A thick faceted garnet petal whose outer lip curls toward the heart."""
    radial=[.22,.39,.64,.85,.88,.78,.60]
    depth=[.18,.09,-.05,-.11,-.23,-.40,-.49]
    width=[.045,.14,.27,.34,.31,.23,.115]
    first=len(m.vertices); n=len(radial); cross=7
    for layer in (-1,1):
        for i,(r,y,w) in enumerate(zip(radial,depth,width)):
            for j in range(cross):
                u=-1+2*j/(cross-1); tangent=u*w*scale
                # A shallow cross-cup and curling rim create volumetric roses
                # even when viewed from the side, unlike a radial star card.
                dy=(y+.13*u*u)*scale+front+layer*.028
                twist=theta+.10*i/(n-1)
                x=tangent*math.cos(twist)+r*scale*math.sin(twist)
                z=-tangent*math.sin(twist)+r*scale*math.cos(twist)
                m.vertices.append((center[0]+x,center[1]+dy,center[2]+z))
    span=n*cross
    for i in range(n-1):
        for j in range(cross-1):
            a=first+i*cross+j; b=a+1; c=first+(i+1)*cross+j+1; d=c-1
            k='rose_rim' if i>=n-3 else key
            m.face((a,b,c,d),k); m.face((a+span,d+span,c+span,b+span),key)
    for i in range(n-1):
        for j in (0,cross-1):
            a=first+i*cross+j; b=first+(i+1)*cross+j
            m.face((a,b,b+span,a+span),'rose_glint')
    for i in (0,n-1):
        for j in range(cross-1):
            a=first+i*cross+j; b=a+1
            m.face((a,a+span,b+span,b),'rose_rim')

def arch(m,half,bottom,height,y,key='star_iron',radius=.14):
    for side in (-1,1):
        m.tube([(side*half,y,bottom),(side*half,y,height*.65),
                (side*half*.78,y,height*.87),(side*half*.41,y,height*.97),(0,y,height)],
               [radius,radius,radius*.9,radius*.82,radius*.65],key,7)

def rose_window(m,center,r=.55):
    x,y,z=center
    m.ring(center,(r,r),.07,'brass',18,5)
    m.ellipsoid((x,y+.025,z),(r*.85,.045,r*.85),'ruby',5,16)
    for i in range(8):
        t=i*math.pi/4
        start=len(m.vertices)
        m.diamond((0,-.025,.46*r),(.23*r,.06,.40*r),'ruby_edge')
        m.transform_since(start,Matrix.Translation(Vector(center))@Matrix.Rotation(t,4,'Y'))
    m.ellipsoid((x,y-.03,z),(.10,.07,.10),'ruby',4,8)

def night_harp(m):
    part(m,'Indigo quadruped shell and four gilded claw feet')
    m.ellipsoid((0,0,.83),(1.05,.44,.44),'indigo',5,12)
    for x,y in [(-.79,-.32),(.67,-.32),(-.71,.38),(.74,.38)]:
        limb(m,[(x,y,.83),(x*1.27,y*.98,.46),(x*1.33,y-.06,.15)],
             [.18,.16,.115],'indigo','brass',7)
        claws(m,(x*1.33,y-.12,.13),'brass_edge',.80)
        plate(m,[(x-.21,.44),(x-.28,.73),(x+.15,.83),(x+.22,.37)],.23,'indigo',y-.14,'indigo_edge')
    part(m,'Crescent beast back and exact four playable harp strings')
    spine=[(-.92,.02,.77),(-1.28,.04,1.38),(-1.36,.04,2.06),(-1.15,.02,2.76),(-.67,.01,3.30),(.06,.02,3.63),(.57,.02,3.65)]
    m.tube(spine,[.28,.25,.22,.20,.20,.19,.16],'indigo',8)
    m.tube([(x,y-.22,z+.04) for x,y,z in spine],[.044]*7,'brass_edge',5)
    m.tube([(-.91,-.13,.87),(-.23,-.17,.59),(.52,-.11,.70),(.92,0,1.10)],[.18,.19,.18,.16],'brass',8)
    for x,top,low in [(-.83,3.04,.71),(-.47,3.35,.63),(-.10,3.53,.65),(.27,3.57,.81)]:
        m.tube([(x,-.02,top),(x-.19,-.13,low)],[.019,.019],'gold_glow',5)
        m.ellipsoid((x-.19,-.13,low),(.045,.05,.045),'brass_edge',3,6)
    part(m,'Blind crescent head and overlapping indigo scales')
    plate(m,[(.40,3.34),(.32,3.82),(.72,3.87),(.97,3.54),(.77,3.18)],.37,'ivory',-.02,'bone_high',.77)
    m.ellipsoid((.71,-.26,3.54),(.055,.035,.16),'obsidian',4,7)
    for i,(x,z) in enumerate([(-1.33,1.6),(-1.34,2.10),(-1.16,2.57),(-.85,2.98),(-.43,3.35),(.05,3.51)]):
        plate(m,[(x-.19,z-.23),(x-.27,z+.09),(x+.09,z+.20),(x+.22,z-.05)],.18,'indigo',-.10,'indigo_edge',.76)
    for x,z in [(-1.19,1.29),(-.95,2.86),(.62,.93)]:
        m.ring((x,-.23,z),(.12,.14),.033,'brass',10,5)
    return ((-.30,-.12,2.10),'harp_strings','Reference 07: four-legged indigo harp beast; curved armored back, gold soundboard, exact four suspended strings and an ivory blind crescent head. Gilded joints and layered scales separate metal from indigo stone.')

def thorn_cathedral(m):
    part(m,'Walking chapel with four stone buttress legs')
    m.bevel_box((-.15,.05,1.08),(1.63,1.31,1.40),'star_iron',.09)
    for x,y in [(-.74,-.48),(.59,-.48),(-.68,.62),(.68,.62)]:
        limb(m,[(x,y,.78),(x*1.3,y*.98,.41),(x*1.42,y-.13,.14)],[.22,.23,.16],'star_iron','star_edge')
        claws(m,(x*1.42,y-.15,.13),'star_wear',.90)
    plate(m,[(-1.07,1.70),(-.10,2.47),(.79,1.76),(.66,1.55),(-.99,1.48)],1.55,'star_iron',.10,'star_edge',.92)
    for x in (-.84,.61):
        m.bevel_box((x,-.75,1.18),(.17,.25,1.48),'star_edge',.04)
    part(m,'Crimson eight petal rose facade and side lancet windows')
    rose_window(m,(-.18,-.79,1.38),.58)
    for x in (-.73,.23,.57):
        m.bevel_box((x,.83,1.16),(.14,.06,.69),'ruby',.015)
        m.tube([(x-.12,.86,.88),(x-.12,.86,1.51),(x,.86,1.72),(x+.12,.86,1.51),(x+.12,.86,.88)],[.028]*5,'brass',4)
    part(m,'Crooked belfry and thorn coils')
    m.bevel_box((.64,.33,2.44),(.52,.62,1.75),'star_iron',.055)
    plate(m,[(.27,3.27),(.99,3.25),(.70,4.03)],.86,'star_iron',.33,'star_edge',.88)
    for x in (.47,.69,.88):
        m.bevel_box((x,-.015,2.75),(.055,.05,.59),'ruby_edge',.01)
    for side in (-1,1):
        pts=[(side*.66,-.12,.57),(side*1.16,.04,1.36),(side*1.19,.10,2.02),
             (side*.91,.10,2.66),(side*.44,.10,2.52),(side*.10,-.04,1.92)]
        m.tube(pts,[.10,.105,.09,.085,.07,.05],'thorn',6)
        for i in (1,2,3):
            a=pts[i]; spike(m,a,(a[0]+side*.19,a[1]-.07,a[2]+.20),.085,'ruby_edge')
    m.tube([(.36,.51,3.14),(.83,.57,3.43),(.92,.54,3.81)],[.062]*3,'thorn',6)
    return ((-.18,-.85,1.38),'rose_window','Reference 07: asymmetric walking chapel with a readable eight-petal crimson rose window, three lancet windows, crooked right belfry and two volumetric thorn coils. Four shaped stone legs support the church rather than a generic animal body.')

def phantom_marionette(m):
    part(m,'Faceless ivory puppet suspended in an expressive asymmetric pose')
    plate(m,[(-.31,2.30),(-.38,2.99),(-.11,3.16),(.31,3.10),(.40,2.69),(.17,2.37)],.31,'ivory',0,'bone_high',.82)
    m.ellipsoid((.09,-.04,3.48),(.33,.21,.44),'ivory',5,10)
    m.profile([(.11,3.26),(.17,3.58),(.08,3.76),(.01,3.51)],.04,'inkblack',-.26)
    limbs=[([(-.28,0,2.98),(-.79,-.05,3.24),(-1.24,-.10,3.63)],[.10,.08,.075]),
           ([(.31,0,2.96),(.77,.01,2.70),(1.28,-.06,2.45)],[.10,.08,.07]),
           ([(-.19,0,2.36),(-.62,-.05,1.71),(-.41,-.12,1.08)],[.13,.095,.10]),
           ([(.21,0,2.34),(.47,.14,1.85),(.87,.11,1.61)],[.13,.09,.10])]
    for points,radii in limbs:
        m.tube(points,radii,'ivory',7)
        for p in points:
            m.ellipsoid(p,(.14,.12,.14),'brass',4,8)
    for x,z in [(-1.24,3.63),(1.28,2.45)]:
        for i,dx in enumerate((-.095,0,.095)):
            m.tube([(x+dx,-.11,z),(x+dx*1.6,-.14,z-.15),(x+dx*2,-.15,z-.22)],[.026,.02,.007],'ivory',5)
    m.bevel_box((-.40,-.17,1.04),(.25,.38,.15),'ivory',.04)
    m.bevel_box((.92,.09,1.59),(.31,.28,.15),'ivory',.04)
    part(m,'Black articulated crossbar and visible tension strings')
    m.tube([(-1.53,.15,4.45),(1.41,.15,4.65)],[.085,.085],'bark_dark',6)
    m.tube([(-.56,-.09,4.69),(.64,.44,4.48)],[.08,.08],'bark_dark',6)
    for i,(a,b) in enumerate([((-.99,.15,4.49),(-1.24,-.09,3.65)),((.08,.15,4.56),(.10,-.02,3.88)),
                              ((1.11,.15,4.63),(1.28,-.05,2.46)),((-.43,.15,4.53),(-.19,.03,2.37))]):
        m.tube([a,b],[.012,.012],'gold_glow',4)
        m.ellipsoid(a,(.07,.075,.07),'brass',3,7)
    part(m,'Ragged garnet cape and joint collar')
    for dx,end in [(-.20,1.90),(0,1.75),(.21,2.05)]:
        m.ribbon([(dx,.20,3.00),(dx+.15,.31,2.73),(dx+.31,.40,2.32),(dx+.50,.43,end)],
                 [.15,.20,.18,.015],'ruby',.065)
    m.ring((.04,-.03,3.03),(.22,.16),.045,'brass',10,5)
    return ((.08,-.25,3.46),'puppet_strings','Reference 07: faceless ivory articulated marionette in an uneven hanging pose, black wooden crossbar and four individually visible gold strings. Brass ball joints, separated finger rods and a ragged garnet cape are real volumes on both sides.')

def blood_moon_rose(m):
    part(m,'Arched thorn stem and four spreading root feet')
    m.tube([(-.10,0,.16),(-.33,.03,.78),(-.21,.04,1.40),(.11,.01,1.93),(.20,0,2.55)],
           [.23,.26,.21,.18,.13],'thorn',7)
    for x,y in [(-.91,-.37),(.93,-.33),(-.77,.53),(.74,.58)]:
        pts=[(-.19,0,.48),(x*.49,y*.39,.31),(x,y,.14),(x*1.37,y*.94,.07)]
        m.tube(pts,[.14,.12,.075,.012],'thorn',6)
        m.tube([(x*.8,y*.8,.18),(x*1.06,y-.28,.10),(x*1.2,y-.38,.05)],[.06,.045,.007],'thorn_edge',5)
    part(m,'Layered garnet glass rose with spiraling physical petals')
    center=(.18,-.02,2.68)
    for ring,count,scale,front in [(0,9,1.13,0),(1,7,.81,-.19),(2,5,.53,-.34)]:
        for i in range(count):
            t=2*math.pi*i/count+ring*.33
            cupped_petal(m,center,t,scale,front=front)
    m.diamond((.18,-.48,2.68),(.115,.11,.13),'rose_core')
    part(m,'Two curved thorn arms with hooked ruby talons')
    for side,height in [(-1,1.92),(1,1.72)]:
        pts=[(-.16,0,1.25),(side*.64,.03,height),(side*1.14,-.08,height+.09),
             (side*1.43,-.13,height-.30),(side*1.44,-.16,height-.65)]
        m.tube(pts,[.15,.13,.115,.10,.04],'thorn',7)
        for j in (1,2,3):
            a=pts[j]; spike(m,a,(a[0]+side*.18,a[1]-.04,a[2]+.14),.065,'ruby_edge')
        for offset in (-.09,.07):
            m.tube([(side*1.39+offset,-.14,height-.40),(side*1.55+offset,-.22,height-.74),
                    (side*1.39+offset,-.26,height-.94)],[.08,.06,.005],'ruby',5)
    return ((.18,-.64,2.68),'rose_pulse','Reference 07: a deep garnet rose has three rings of overlapping, cross-cupped thick petals whose lips curl inward around a small dark red core. Twenty-one closed individual petal volumes, warm rose glints, unequal thorn arms and hooked ruby talons flank an arched woody stem and four branching roots; no flat radial starflower or overbright core.')

def judgement_scales(m):
    part(m,'Bone and iron idol with two broad planted feet')
    for side in (-1,1):
        limb(m,[(side*.23,0,1.23),(side*.50,.03,.56),(side*.70,-.06,.22)],
             [.22,.20,.17],'ivory' if side>0 else 'star_iron','brass')
        claws(m,(side*.72,-.12,.19),'bone_high' if side>0 else 'star_edge',1)
    plate(m,[(-.20,.85),(-.40,1.91),(0,2.24),(.40,1.88),(.21,.83)],.50,'star_iron',.03,'brass',.74)
    plate(m,[(-.38,2.25),(-.51,2.90),(0,3.63),(.49,2.92),(.22,2.22),(0,1.94)],.32,'ivory',0,'bone_high',.80)
    m.profile([(-.075,2.38),(-.13,2.98),(.005,3.17),(.14,2.99),(.07,2.39)],.04,'obsidian',-.23)
    m.ring((0,.11,2.92),(.60,.66),.046,'brass',18,5)
    part(m,'Uneven balance arms and suspended open bowl pans')
    for side,top,low,key in [(-1,2.62,1.17,'star_iron'),(1,2.99,1.66,'ivory')]:
        x=side*1.28
        m.tube([(side*.31,0,2.31),(side*.70,0,top+.04),(x,0,top)],[.13,.09,.07],'brass',6)
        m.ring((x,0,top),(.095,.13),.03,'brass_edge',8,5)
        for dy,dx in [(-.15,-.29),(-.15,.29),(.24,0)]:
            m.tube([(x,0,top-.04),(x+dx,dy,low+.18)],[.018,.018],'brass_edge',4)
        hollow_bell(m,(x,0,low),[(0,.22),(.10,.39),(.28,.48)],key,12,.07)
        m.ring((x,0,low+.28),(.48,.48),.026,'brass',12,5)
        for k in range(4):
            t=k*math.pi/2
            spike(m,(x+.35*math.cos(t),.33*math.sin(t),low+.18),(x+.44*math.cos(t),.43*math.sin(t),low+.43),.07,'brass_edge')
        if side>0: star(m,(x,-.10,low+.37),.23,'gold_glow',4,.25,.05)
        else:
            m.ribbon([(x,-.02,low+.2),(x-.15,.01,low+.49),(x+.05,.04,low+.69)],[.18,.12,.015],'indigo',.065)
    m.diamond((0,-.31,1.53),(.16,.09,.32),'brass_edge')
    return ((1.28,-.14,2.03),'unequal_scales','Reference 07: blind bone and iron judgment idol with unequal suspended real open pans. The pale right bowl bears a gold soul, the dark lower bowl a folded smoke volume; unequal legs, a tall split face and brass halo complete the ceremonial silhouette.')

def clockwork_raven(m):
    part(m,'Mechanical raven torso, clock face, brass beak and jointed claws')
    m.ellipsoid((0,.02,1.75),(.47,.42,.74),'obsidian',5,10)
    m.ellipsoid((.12,-.03,2.76),(.36,.31,.40),'obsidian',5,10)
    plate(m,[(.12,2.65),(.41,2.92),(.80,2.71),(.53,2.55)],.23,'brass',-.22,'brass_edge',.85)
    m.ring((.05,-.37,2.82),(.22,.22),.036,'brass',14,5)
    m.ellipsoid((.05,-.38,2.82),(.19,.026,.19),'ivory',4,12)
    m.tube([(.05,-.42,2.82),(.05,-.42,2.96)],[.015,.013],'obsidian',4)
    m.tube([(.05,-.42,2.82),(.14,-.42,2.76)],[.015,.013],'obsidian',4)
    for side in (-1,1):
        limb(m,[(side*.25,0,1.24),(side*.44,-.02,.67),(side*.42,-.15,.21)],
             [.13,.11,.085],'obsidian','brass',7)
        claws(m,(side*.42,-.16,.21),'brass_edge',1.05)
        m.ring((side*.31,-.43,1.80),(.20,.20),.055,'brass',12,5)
    part(m,'Raised unequal wings with individual armored flight feathers')
    for side,raisez in [(-1,.22),(1,-.05)]:
        m.tube([(side*.35,.06,2.04),(side*.92,.11,2.80+raisez),(side*1.34,.20,3.17+raisez)],
               [.19,.15,.10],'brass',6)
        for i in range(7):
            x=side*(.65+i*.13); top=2.88+raisez+i*.065; tip=1.53+raisez-i*.16
            outline=[(x-side*.11,top),(x+side*.14,top+.14),(x+side*.51,tip+.07),(x+side*.38,tip-.13),(x-side*.06,top-.37)]
            plate(m,outline,.15,'obsidian',.12+i*.02,'indigo_edge',.82)
            m.tube([(x,.03+i*.02,top-.07),(x+side*.37,.03+i*.02,tip+.07)],[.018,.013],'brass',4)
        for x,z in [(side*.87,2.78+raisez),(side*.43,1.43)]:
            m.ring((x,-.09,z),(.16,.16),.045,'brass_edge',10,5)
    part(m,'Long layered tail feathers and back winding wheel')
    for i in range(4):
        m.ribbon([((i-1.5)*.16,.28,1.55),((i-1.5)*.20,.51,.95),((i-1.5)*.27,.85,.62)],
                 [.12,.14,.01],'obsidian',.10)
    m.ring((0,.45,1.91),(.31,.31),.06,'brass',14,5)
    return ((.05,-.44,2.82),'raven_clock','Reference 08: black and brass mechanical raven with white clock eye and two visible hands. Unequally raised wings contain individual thick armored flight feathers, brass quills, winding joints, long tail and separate claw toes; no generic rounded pet body.')

def eclipse_stag(m):
    part(m,'Lean black spectral deer with four articulated hooves')
    m.ellipsoid((-.20,.04,1.32),(.93,.40,.47),'obsidian',5,10)
    m.tube([(.39,.03,1.38),(.66,.03,2.01),(.52,.02,2.55)],[.32,.25,.19],'obsidian',7)
    for x,y,z in [(-.77,-.26,1.18),(.40,-.25,1.38),(-.70,.36,1.16),(.42,.35,1.36)]:
        pts=[(x,y,z),(x+(.15 if x<0 else -.11),y,.68),(x-.08,y-.07,.16)]
        limb(m,pts,[.14,.105,.09],'obsidian','jade',6)
        m.bevel_box((x-.08,y-.13,.12),(.24,.32,.19),'ivory',.05)
        m.tube([(a-.06,b-.07,c+.02) for a,b,c in pts],[.016]*3,'moon_glow',4)
    plate(m,[(.21,2.30),(.21,2.66),(.56,2.98),(.81,2.57),(.70,2.10)],.32,'ivory',-.11,'bone_high',.81)
    for x,z in [(.40,2.63),(.65,2.62)]:
        m.profile([(x-.036,z+.04),(x+.032,z+.05),(x+.015,z-.14)],.045,'obsidian',-.33)
    part(m,'Broad pale branching antlers with suspended moon crystals')
    for side in (-1,1):
        base=(.43+side*.19,.10,2.77)
        pts=[base,(.42+side*.59,.11,3.17),(.33+side*.96,.13,3.39),(.18+side*1.29,.12,3.78),(.17+side*1.45,.11,4.03)]
        m.tube(pts,[.12,.11,.10,.075,.012],'ivory',6)
        for index,up in [(1,.46),(2,.38),(3,.29)]:
            a=pts[index]
            m.tube([a,(a[0]+side*.10,a[1]-.05,a[2]+up*.55),(a[0]-side*.03,a[1]-.12,a[2]+up)],[.065,.046,.007],'bone_high',5)
        m.diamond((pts[2][0],-.02,3.19),(.074,.064,.16),'moon_glow')
    part(m,'Separated wind mane and tapered phantom tail')
    for i in range(5):
        m.ribbon([(.55+(i-2)*.11,.28,2.23),(.06+(i-2)*.16,.48,2.10),(-.43+(i-2)*.20,.61,1.80)],
                 [.055,.09,.012],'jade',.055)
    m.tube([(-.98,.18,1.37),(-1.27,.22,1.50),(-1.42,.35,1.77)],[.16,.11,.015],'jade',6)
    return ((.43,-.32,2.56),'eclipse_antlers','Reference 08: lean spectral deer with black armored body, four jointed hooves, pale mask and broad multi-branch ivory antlers. Small moon crystals and separated jade mane ribbons occupy controlled negative space rather than a halo of spikes.')

def endless_library(m):
    part(m,'Three differently colored bound books with physical pages and cover corners')
    for x,z,key in [(-.92,1.56,'jade'),(0,1.47,'bark_light'),(.91,1.39,'ivory')]:
        m.bevel_box((x,.04,z),(.81,.51,1.49),'parchment',.055)
        for y in (-.28,.37):
            m.bevel_box((x,y,z),(.94,.12,1.64),key,.055)
        m.bevel_box((x-.40,.07,z),(.16,.65,1.61),key,.04)
        for dx in (-.34,.34):
            for dz in (-.68,.68):
                m.bevel_box((x+dx,-.36,z+dz),(.15,.10,.15),'brass',.025)
        for dz in (-.48,.48):
            m.bevel_box((x,-.37,z+dz),(.87,.08,.08),'brass',.015)
        for dz in (-.4,-.21,.02,.23,.40):
            m.tube([(x+.43,-.18,z+dz),(x+.43,.22,z+dz)],[.012,.012],'bark_light',4)
        star(m,(x,-.39,z),.24,'brass_edge',8,.27,.04)
    part(m,'Shelf legs with stacked page talons and hanging bookmarks')
    for x,y in [(-1.02,-.12),(1.00,-.12),(-.81,.37),(.81,.37)]:
        limb(m,[(x,y,.79),(x*1.07,y-.05,.45),(x*1.15,y-.17,.18)],
             [.18,.15,.14],'bark_dark','brass',6)
        for i in range(3):
            m.bevel_box((x*1.15,y-.25,.11+i*.05),(.41-i*.02,.43-i*.03,.065),'parchment',.025)
    for x in (-.86,.86):
        m.ribbon([(x,-.40,1.17),(x+.02,-.44,.72),(x-.05,-.45,.38)],
                 [.08,.09,.045],'jade',.055)
    part(m,'Real hanging chain links and a suspended fourth open codex')
    chain(m,[(x,-.42,1.17-.24*math.cos(x*1.3)) for x in [-1.0,-.77,-.54,-.31,-.08,.15,.38,.61,.84,1.07]],'star_iron',.044)
    m.rotated_box((.22,.02,2.75),(.89,.59,.53),'parchment',(0,.09,.12),.055)
    for x,a in [(-.05,-.18),(.44,.18)]:
        m.rotated_box((x,-.30,2.75),(.55,.10,.61),'bark_light',(0,a,.12),.04)
    m.tube([(-.20,-.38,2.76),(.20,-.39,2.94),(.68,-.35,2.77)],[.025]*3,'brass_edge',4)
    return ((.22,-.37,2.76),'library_pages','Reference 08: three distinct oversized chained tomes walking on four bookshelf legs. Actual page blocks, cover corners, clasps, sun sigils, dangling bookmarks, separated chain links and a suspended fourth open codex distinguish an animate library from stacked plain boxes.')

def sunken_crown(m):
    part(m,'Pale coral crown with open circlet and central aquamarine jewel')
    start=len(m.vertices); m.ring((0,0,0),(.94,.94),.11,'ivory',20,6)
    m.transform_since(start,Matrix.Translation(Vector((0,0,2.42)))@Matrix.Rotation(math.pi/2,4,'X'))
    for i in range(8):
        t=i*math.pi/4; x=.92*math.cos(t); y=.92*math.sin(t)
        m.tube([(x,y,2.38),(x*1.03,y*1.03,2.85),(x*1.12,y*1.12,3.27)],[.10,.07,.02],'ivory',6)
        m.diamond((x,y,2.61),(.075,.075,.13),'sea_edge')
        for side in (-1,1):
            m.tube([(x*1.04,y*1.04,2.95),(x+side*.13,y+.07,3.12),(x+side*.18,y+.06,3.25)],
                   [.048,.031,.008],'coral' if i%3==0 else 'ivory',5)
    m.ring((0,-.99,2.81),(.27,.40),.075,'ivory',14,5)
    m.diamond((0,-1.06,2.82),(.19,.15,.33),'sea_edge')
    part(m,'Aquatic spirit descending as six thick curled translucent-color tendrils')
    m.ellipsoid((0,.05,2.00),(.48,.39,.46),'sea_glass',5,10)
    for i in range(6):
        t=i*2*math.pi/6
        x=.36*math.cos(t); y=.32*math.sin(t)
        pts=[(x,y,2.17),(x*1.3,y*1.25,1.62),(x*1.95,y*1.80,1.07),
             (x*2.20+.13,y*2.1,.57),(x*1.70+.25,y*1.9,.25),(x*1.2+.15,y*1.6,.31)]
        m.tube(pts,[.17,.16,.14,.11,.07,.012],'sea_glass',7)
        m.tube([(a,b-.09,c+.02) for a,b,c in pts],[.025,.027,.025,.021,.012,.006],'sea_edge',5)
    part(m,'Side coral growths and bound turquoise drops')
    for side in (-1,1):
        m.tube([(side*.71,.0,2.54),(side*.67,-.01,2.95),(side*.53,0,3.12)],
               [.08,.059,.012],'coral',6)
        m.diamond((side*1.14,-.05,1.44),(.10,.08,.15),'sea_edge')
    return ((0,-1.09,2.82),'sunken_tides','Reference 08: an open pale coral crown with eight branching points and a prominent aquamarine jewel serves as the head of a six-tendril aquatic spirit. Thick curled water volumes, bright water ridges and warm coral branches create distinct ivory/turquoise/orange material roles.')

def silent_choir(m):
    part(m,'Three solemn separate robed presences with unequal heights')
    for x,height,key,trim in [(-.89,2.86,'burial','brass'),(0,3.51,'linen','brass_edge'),(.94,3.04,'indigo','ivory')]:
        m.lathe((x,0,.12),[(0,.47),(.43,.40),(1.05,.32),(height-1.14,.20)],key,9)
        for side in (-1,1):
            m.ribbon([(x+side*.22,-.03,height-.91),(x+side*.37,-.12,height-1.36),
                      (x+side*.51,-.16,.62),(x+side*.61,-.09,.10)],
                     [.12,.13,.16,.025],key,.10)
            m.tube([(x+side*.17,-.27,height-.94),(x+side*.19,-.31,.64),(x+side*.32,-.34,.21)],
                   [.020,.022,.007],trim,5)
        part(m,'Open inverted bell head '+str(x))
        start=len(m.vertices)
        hollow_bell(m,(0,0,0),[(0,.36),(.12,.35),(.52,.17),(.68,.12)],key,12,.065)
        # Rotate the open mouth toward the player, giving a genuine empty face.
        transform=Matrix.Translation(Vector((x,-.24,height-.44)))@Matrix.Rotation(math.radians(-65),4,'X')
        m.transform_since(start,transform)
        m.diamond((x,-.34,height-.66),(.083,.075,.15),trim)
        star(m,(x,-.34,height-1.04),.17,trim,4,.30,.045)
        m.tube([(x,-.02,height-.93),(x+.36,-.15,height-1.25),(x+.57,-.26,height-1.04)],
               [.10,.085,.045],key,6)
        for i in range(2):
            m.tube([(x+.57,-.26,height-1.04),(x+.58+i*.07,-.28,height-.87)],[.022,.009],trim,5)
    part(m,'Fine suspended chime chain between three bell heads')
    m.tube([(-1.13,.08,2.64),(-.55,.08,2.80),(0,.08,3.12),(.55,.08,2.88),(1.13,.08,2.72)],
           [.014]*5,'gold_glow',4)
    return ((0,-.31,3.10),'silent_choir_chimes','Reference 08: three individually robed solemn presences in charcoal, pale linen and indigo, with different heights and genuinely open bell mouths turned toward the viewer. Folded cloth volumes, raised seam piping, small chimes and a suspended connecting line unify the choir.')

def cathedral_heart(m):
    part(m,'Three-dimensional split stone heart with a branching golden seam')
    for x in (-.31,.31):
        m.ellipsoid((x,-.08,2.23),(.53,.38,.56),'ivory',6,12)
    plate(m,[(-.66,2.22),(-.66,1.81),(-.31,1.30),(0,1.05),(.31,1.31),(.66,1.81),(.66,2.22)],
          .62,'ivory',-.05,'bone_high',.86)
    seam=[(-.14,-.48,2.60),(.09,-.49,2.28),(-.09,-.49,1.99),(.06,-.43,1.66),(0,-.42,1.24)]
    m.tube(seam,[.032]*5,'gold_glow',5)
    for a,b in [(seam[1],(.46,-.44,2.48)),(seam[2],(-.44,-.43,1.77)),(seam[3],(.38,-.37,1.43))]:
        m.tube([a,b],[.022,.011],'gold_glow',4)
    part(m,'Two tall pointed dark arches with open sides and rear depth')
    for y in (.18,.65):
        arch(m,1.05,.56,4.23,y,'star_iron',.20)
        arch(m,1.01,.58,4.20,y-.17,'ivory',.065)
    for side in (-1,1):
        m.tube([(side*1.02,.15,.62),(side*1.00,.16,1.82),(side*.70,.24,3.25)],
               [.27,.21,.12],'star_iron',7)
        # Stacked buttress shoes visually carry the stone heart's arches.
        for y in (-.12,.73):
            limb(m,[(side*.89,y,.90),(side*1.12,y,.38),(side*1.22,y-.12,.16)],
                 [.24,.24,.15],'star_iron','ivory')
            claws(m,(side*1.22,y-.13,.15),'bone_high',.90)
        for z in (1.24,2.18,2.90):
            m.tube([(side*1.01,.02,z),(side*1.01,.71,z)],[.065,.065],'brass',5)
        plate(m,[(side*.74,2.43),(side*1.26,2.34),(side*1.12,2.90),(side*.94,3.19)],
              .44,'star_iron',.11,'ivory',.77)
        m.tube([(side*1.06,-.06,.85),(side*1.34,-.04,1.45),(side*1.23,.03,2.12)],
               [.12,.11,.06],'star_iron',6)
    part(m,'Narrow gilded cathedral lancets suspended along the arches')
    for side in (-1,1):
        for y in (.06,.77):
            m.tube([(side*1.02,y,1.64),(side*1.02,y,2.27)],[.029,.025],'gold_glow',5)
    m.diamond((0,.14,4.22),(.16,.14,.25),'ivory')
    return ((0,-.52,2.15),'cathedral_heart_seam','Reference 09: large cracked ivory heart suspended inside paired depth-separated pointed cathedral arches. Four buttress feet, dark shaped stone, pale arch ridges and slender golden lancets leave genuine openings around the heart and create a sacred monumental silhouette within gameplay bounds.')

def plague_monarch(m):
    part(m,'Four copper armored insect legs and tapering monarch chest')
    m.ellipsoid((0,.10,1.55),(.57,.41,.72),'patina',5,10)
    for x,y in [(-.65,-.25),(.66,-.24),(-.58,.58),(.57,.58)]:
        pts=[(x*.68,y*.60,1.31),(x*1.36,y,1.00),(x*1.57,y,.47),(x*1.57,y-.09,.14)]
        limb(m,pts,[.19,.18,.15,.09],'star_iron','patina',7)
        plate(m,[(x*1.57-.20,.25),(x*1.57-.15,.80),(x*1.57+.06,1.00),(x*1.57+.23,.61)],
              .27,'patina',y-.16,'copper_edge',.71)
        claws(m,(x*1.57,y-.12,.14),'copper_edge',.84)
    part(m,'Broad five point corroded copper crown shell with real cutouts')
    for y in (.16,.49):
        arch(m,.78,1.93,3.19,y,'patina',.21)
    for side in (-1,1):
        pts=[(side*.71,.20,2.31),(side*.87,.21,2.91),(side*.64,.22,3.40),(side*.84,.22,3.88)]
        m.tube(pts,[.17,.14,.10,.015],'patina',6)
        m.tube([(side*.37,.28,2.95),(side*.44,.33,3.46),(side*.35,.32,3.78)],[.12,.08,.009],'patina',6)
        m.tube([(side*.61,-.19,1.99),(side*.72,-.05,2.46),(side*.27,-.02,2.84)],
               [.16,.17,.08],'patina',6)
    face=[(-.24,2.67),(-.34,2.29),(-.13,1.72),(0,1.48),(.13,1.73),(.34,2.30),(.23,2.66)]
    m.profile(face,.35,'ivory',-.31)
    m.profile([(-.12,2.31),(0,2.50),(.12,2.31),(.025,1.85),(-.025,1.85)],.045,'obsidian',-.52)
    for side in (-1,1):
        m.tube([(side*.13,-.51,2.54),(side*.22,-.52,2.31),(side*.10,-.51,1.77)],[.023,.025,.01],'bone_high',5)
    for side in (-1,1):
        m.tube([(side*.20,.08,2.66),(side*.36,.13,3.17),(side*.57,.22,3.52)],
               [.06,.05,.007],'copper_edge',5)
    part(m,'Plate seams and bounded poison wisps')
    for side in (-1,1):
        plate(m,[(side*.12,1.59),(side*.72,1.36),(side*.74,1.74),(side*.34,2.10)],
              .22,'patina',-.13,'copper',.77)
        m.ribbon([(side*.54,.20,.64),(side*.83,.29,1.0),(side*.77,.34,1.30)],
                 [.11,.07,.01],'plague_glow',.05)
    return ((0,-.57,2.28),'plague_monarch_breath','Reference 09: four-legged corroded copper monarch with a broad open crown shell, irregular antler-like copper points, pale plague mask and warm exposed metal under broad verdigris islands. Small contained green wisps support the form without obscuring its four-leg anatomy.')

def hollow_throne(m):
    part(m,'Open throne architecture with tall pointed rails and four living feet')
    m.bevel_box((0,.18,.85),(1.75,1.14,.23),'burial',.08)
    m.bevel_box((0,.18,.96),(1.51,.96,.17),'charcoal',.08)
    for side in (-1,1):
        for y in (-.25,.68):
            limb(m,[(side*.79,y,.85),(side*.99,y,.43),(side*1.05,y-.11,.15)],
                 [.24,.22,.15],'star_iron','star_edge')
            claws(m,(side*1.05,y-.13,.15),'star_wear',1.02)
        m.bevel_box((side*.86,-.04,1.29),(.28,.98,.24),'star_iron',.08)
        m.tube([(side*.92,.64,.99),(side*.95,.65,2.85),(side*.67,.65,3.41),(side*.36,.64,3.81)],
               [.17,.15,.12,.045],'star_iron',7)
        m.tube([(side*.94,.47,1.07),(side*.91,.46,2.79),(side*.60,.46,3.40),(0,.46,4.14)],
               [.05,.05,.045,.027],'cold_white',5)
        plate(m,[(side*.88,1.08),(side*1.18,1.22),(side*1.20,1.61),(side*.98,1.76),(side*.72,1.53)],
              .61,'star_iron',-.06,'star_edge',.73)
    arch(m,.93,1.16,4.05,.78,'star_iron',.20)
    m.tube([(-.79,.65,1.30),(.80,.65,1.30)],[.11,.11],'star_iron',6)
    part(m,'Monarch occupied only by a luminous empty outline')
    # Both front and rear sides remain open; there is no black screen filling the chair.
    ghost=[(-.45,.31,1.16),(-.32,.34,1.83),(-.52,.34,2.41),(-.23,.35,2.63),
           (-.15,.35,2.94),(0,.35,3.10),(.17,.35,2.96),(.24,.35,2.65),
           (.48,.35,2.40),(.31,.34,1.80),(.47,.31,1.16)]
    m.tube(ghost,[.025]*len(ghost),'white_glow',4)
    for side in (-1,1):
        m.ribbon([(side*.28,.45,2.60),(side*.59,.52,2.86),(side*.79,.56,3.34),
                  (side*.55,.63,3.73)], [.08,.17,.16,.012],'linen',.062)
    part(m,'Chipped outer lancets and white diamond finials')
    for side in (-1,1):
        m.diamond((side*.72,.66,3.78),(.13,.12,.25),'star_edge')
        m.diamond((side*.89,-.32,1.48),(.08,.065,.17),'white_glow')
    m.diamond((0,.65,4.05),(.15,.14,.30),'cold_white')
    return ((0,.31,2.34),'hollow_throne_presence','Reference 09: living dark throne with four claw feet, tall open gothic back rails and an occupant defined only by a thin luminous monarch outline. Real empty openings remain visible from the rear; torn linen shoulders and white chipped rail ridges provide a restrained monochrome identity.')

def worldroot(m):
    part(m,'Four twisting inverted tree root legs with bifurcated toes')
    for x,y in [(-.94,-.34),(.89,-.32),(-.74,.56),(.72,.56)]:
        pts=[(x*.52,y*.42,1.48),(x*.88,y*.83,1.01),(x*1.22,y,.51),(x*1.30,y-.12,.14)]
        m.tube(pts,[.27,.24,.18,.09],'bark_dark',7)
        m.tube([(a-.055,b-.13,c+.03) for a,b,c in pts],[.045]*4,'bark_light',5)
        for side in (-1,1):
            m.tube([pts[-2],(x*1.40+side*.16,y-.23,.17),(x*1.56+side*.19,y-.39,.06)],
                   [.10,.057,.005],'bark_light',5)
    part(m,'Two thick opposing trunk arches surrounding a suspended jade seed')
    for side in (-1,1):
        pts=[(side*.11,.09,.82),(side*.63,.04,1.44),(side*.83,.07,2.19),
             (side*.71,.15,2.83),(side*.40,.20,3.38),(side*.30,.21,3.96)]
        m.tube(pts,[.20,.27,.25,.23,.20,.06],'bark_dark',8)
        m.tube([(x-side*.08,y-.18,z+.03) for x,y,z in pts],[.065,.07,.065,.062,.05,.015],'bark_light',6)
        m.tube([(side*.37,.59,1.07),(side*.76,.61,1.99),(side*.61,.56,2.95),(side*.12,.48,3.60)],
               [.19,.22,.18,.03],'bark_dark',7)
    m.diamond((0,-.02,1.92),(.27,.24,.50),'jade')
    m.diamond((0,-.25,1.95),(.17,.07,.34),'jade_glow')
    for side in (-1,1):
        m.tube([(side*.28,.03,3.1),(side*.22,-.01,2.46),(side*.15,-.01,2.22)],
               [.05,.036,.02],'bark_light',5)
        m.tube([(side*.62,-.02,1.12),(side*.42,-.02,1.30),(side*.30,-.02,1.64)],
               [.06,.05,.015],'gold_glow',5)
    part(m,'Wide inverted branching crown with individually hanging moss strips')
    for side in (-1,1):
        branch=[(side*.38,.18,3.21),(side*.92,.15,3.41),(side*1.34,.10,3.68),(side*1.51,.03,4.10)]
        m.tube(branch,[.18,.15,.12,.012],'bark_light',7)
        m.tube([(side*.87,.17,3.4),(side*1.00,.33,3.84),(side*.90,.37,4.24)],
               [.11,.074,.008],'bark_light',6)
        for i,(x,y,z) in enumerate([(side*.51,-.03,3.34),(side*.91,.00,3.49),(side*1.30,-.01,3.80)]):
            m.ellipsoid((x,y,z),(.23,.17,.09),'moss_dark',3,7)
            for dx,length in [(-.09,.51),(.06,.73),(.15,.36)]:
                m.ribbon([(x+dx,y-.08,z),(x+dx-.02,y-.10,z-length*.51),(x+dx+.025,y-.12,z-length)],
                         [.047,.050,.007],'moss_light',.036)
    for x,z in [(-.58,1.10),(.65,2.31),(-.68,2.76)]:
        m.ellipsoid((x,-.08,z),(.19,.12,.075),'moss_dark',3,7)
    return ((0,-.32,1.94),'worldroot_seed','Reference 10: an inverted tree beast with four twisting root feet, two opposite trunk arches and a suspended jade seed in a true central opening. Wide asymmetric branch forks, longitudinal painted bark and individually hanging moss strips create a living ancient tree rather than a pile of spikes.')

def the_undertow(m):
    part(m,'Genuinely hollow wreck bell with corroded rim and hanging clapper')
    hollow_bell(m,(0,.06,1.01),[(0,.74),(.14,.71),(.90,.47),(1.60,.32)],'patina',18,.11)
    for h,r in [(1.03,.76),(1.18,.71),(2.29,.39)]:
        start=len(m.vertices); m.ring((0,0,0),(r,r),.041,'copper_edge',18,5)
        m.transform_since(start,Matrix.Translation(Vector((0,.06,h)))@Matrix.Rotation(math.pi/2,4,'X'))
    m.tube([(0,.06,1.93),(0,.06,1.29),(0,.06,1.05)],[.07,.07,.09],'copper',6)
    m.ellipsoid((0,.06,1.03),(.16,.16,.19),'copper',4,9)
    for side in (-1,1):
        m.diamond((side*.20,-.41,1.94),(.09,.065,.20),'cold_white')
    part(m,'Large unequal curved dark water blade arms and copper wrist plates')
    for side,raisez in [(-1,0),(1,.30)]:
        pts=[(side*.35,.09,2.13),(side*.91,.10,2.47),(side*1.34,.12,2.17+raisez),
             (side*1.42,.09,1.52+raisez),(side*1.14,.03,.80+raisez),(side*.89,-.05,.54+raisez)]
        m.tube(pts,[.19,.20,.19,.17,.12,.015],'sea_glass',7)
        m.tube([(x-side*.045,y-.14,z+.06) for x,y,z in pts],[.035]*6,'sea_edge',5)
        for k in (2,3):
            a=pts[k]
            spike(m,a,(a[0]+side*.37,a[1]-.05,a[2]+.23),.12,'sea_glass')
        plate(m,[(side*.54,2.24),(side*.79,2.60),(side*1.02,2.48),(side*.88,2.11)],
              .33,'patina',.01,'copper',.80)
    part(m,'Compact curled undertow below the open bell')
    m.tube([(0,.09,1.02),(-.27,.08,.82),(-.13,.12,.48),(.27,.14,.29),(.33,.07,.06)],
           [.26,.22,.19,.13,.015],'deep_water',8)
    m.tube([(.13,-.14,.95),(-.13,-.17,.71),(.10,-.09,.44),(.30,-.08,.19)],[.05,.055,.045,.01],'sea_edge',5)
    part(m,'Bell hanger with broad weathered linked handle')
    m.ring((0,.06,2.76),(.19,.25),.072,'patina',12,6)
    m.ring((-.18,.08,2.95),(.19,.22),.060,'copper',12,5)
    return ((0,-.16,.68),'undertow_spiral','Reference 10: a genuinely hollow corroded wreck bell with visible hanging clapper, copper rim bands and two large unequal curling water blade arms. A compact dark-water undertow spiral occupies the open bottom while bright water edges and patina islands preserve readable material boundaries.')

def the_last_funeral(m):
    part(m,'Long horizontal chamfered black coffin with a raised lid and ivory memorial lilies')
    outline=[(-1.84,2.38),(-1.56,2.97),(-1.18,3.20),(1.38,3.12),(1.84,2.73),
             (1.81,2.25),(1.43,2.02),(-1.46,2.07)]
    plate(m,outline,1.31,'burial',.05,'burial_edge',.92)
    m.tube([(-1.58,-.78,2.34),(-1.43,-.78,2.89),(-1.13,-.78,3.02),(1.32,-.78,2.97),(1.65,-.78,2.70)],
           [.021]*5,'brass',5)
    m.tube([(-1.49,-.77,2.20),(1.39,-.77,2.17)],[.022,.022],'brass',5)
    for x,z,size in [(-.94,2.52,.24),(.16,2.75,.25),(1.02,2.49,.22)]:
        for i in range(5):
            t=2*math.pi*i/5
            start=len(m.vertices)
            m.diamond((0,0,size*.45),(.055,.035,size*.52),'ivory')
            m.transform_since(start,Matrix.Translation(Vector((x,-.91,z)))@Matrix.Rotation(t,4,'Y'))
        m.ellipsoid((x,-.95,z),(.055,.035,.055),'brass_edge',3,7)
        m.tube([(x,-.91,z-.12),(x-.18,-.91,z-.39)],[.015,.013],'ivory',4)
    part(m,'Two broad wrapping straps each continuing into front and rear tall curved claw legs')
    for x in (-1.08,.91):
        side=-1 if x<0 else 1
        for y in (-.79,.83):
            pts=[(x,y,3.03),(x,y,2.06),(x+side*.12,y*1.06,1.73),
                 (x+side*.42,y*1.04,1.26),(x+side*.49,y*.91,.65),(x+side*.43,y*.82,.23)]
            curved_sheet(m,pts,[.085,.095,.11,.12,.10,.065],'burial',.14,.015,'burial_edge')
            end=pts[-1]
            for dx in (-.075,.075):
                m.tube([(end[0]+dx,end[1],end[2]+.10),(end[0]+dx*1.8,end[1]-.19,.14),
                        (end[0]+dx*2,end[1]-.39,.08)],[.085,.075,.012],'ivory',6)
            m.tube([(x-.025,y-.075,2.99),(x-.025,y-.075,2.08)],[.019,.019],'brass_edge',4)
        m.bevel_box((x,0,3.09),(.20,1.71,.12),'burial',.025)
        m.bevel_box((x,0,2.03),(.20,1.69,.10),'burial',.025)
        m.diamond((x,-.95,2.43),(.13,.07,.15),'brass_edge')
    return ((.16,-.96,2.74),'last_funeral_lilies','Reference 10 final correction: long HORIZONTAL black coffin on four tall, physically folded curved straps ending in two-toed ivory claws. Two bands wrap the lid and body before becoming its supports; raised lilies, gold seams and a chamfered coffin silhouette preserve the solemn funeral object from all sides.')

def nameless_door(m):
    part(m,'Living jade threshold with five genuinely receding open corridor frames')
    for i in range(5):
        half=1.02-i*.135; top=3.53-i*.40; y=-.21+i*.26
        for side in (-1,1):
            m.bevel_box((side*half,y,(top+.43)*.5),(.16,.18,top-.43),'patina' if i<2 else 'jade',.035)
            m.tube([(side*(half-.04),y-.12,.45),(side*(half-.04),y-.12,top-.06)],[.016]*2,'jade_glow',4)
        m.bevel_box((0,y,top),(half*2+.21,.18,.18),'star_iron' if i==0 else 'jade',.035)
        m.bevel_box((0,y,.40+i*.07),(half*2,.25,.09),'patina',.025)
    m.bevel_box((0,.21,.22),(2.53,1.93,.29),'star_iron',.075)
    part(m,'Hinged physical half-open door slab and engraved diamond lock')
    start=len(m.vertices)
    plate(m,[(-.03,.47),(-.03,3.25),(1.06,3.25),(1.06,.48)],.19,'star_iron',0,'patina',.82)
    for z in (.68,1.22,1.84,2.43,2.95):
        m.bevel_box((.49,-.16,z),(.78,.06,.045),'copper',.012)
    m.ring((.66,-.17,1.83),(.17,.23),.046,'copper_edge',12,5)
    m.diamond((.66,-.22,1.83),(.07,.04,.12),'jade_glow')
    m.transform_since(start,Matrix.Translation(Vector((1.01,-.15,.05)))@Matrix.Rotation(math.radians(-56),4,'Z'))
    part(m,'Crooked stone legs and moss growths on the outer lintel')
    for side in (-1,1):
        m.tube([(side*.93,.08,.60),(side*1.21,.13,.48),(side*1.34,.02,.13)],
               [.17,.16,.11],'patina',7)
        claws(m,(side*1.34,-.04,.13),'stone_light',.84)
        m.tube([(side*1.08,.0,.83),(side*1.28,.0,1.64),(side*1.17,.02,2.42)],[.13,.11,.035],'bark_dark',6)
        for z in (1.02,2.45,3.33):
            m.diamond((side*1.04,-.38,z),(.10,.07,.22),'jade_glow')
        m.ellipsoid((side*.75,-.03,3.62),(.36,.18,.12),'moss_dark',4,8)
        m.ribbon([(side*.76,-.12,3.60),(side*.79,-.13,3.33),(side*.73,-.14,3.06)],
                 [.11,.10,.01],'moss_light',.055)
    return ((0,.64,1.62),'nameless_threshold','Reference 11: living dark-jade door with five decreasing open frames forming an actual deep corridor, an individually modeled hinged half-open slab, raised lock and receding threshold steps. Crooked mineral legs, root tendrils and selective hanging moss surround the supernatural geometry.')

def crown_of_silence(m):
    part(m,'Headless ivory regent with a genuine open collar and four separate floating crown fragments')
    m.lathe((0,.04,1.09),[(0,.36),(.79,.39),(1.53,.32)],'royal_shadow',10)
    start=len(m.vertices); m.ring((0,0,0),(.32,.32),.065,'brass',14,6)
    m.transform_since(start,Matrix.Translation(Vector((0,.03,2.81)))@Matrix.Rotation(math.pi/2,4,'X'))
    for x,z,size in [(-.43,3.51,.28),(.43,3.53,.30),(0,3.88,.41),(0,3.08,.19)]:
        m.diamond((x,.01,z),(size*.48,.13,size),'royal_edge')
        m.diamond((x,-.13,z),(size*.25,.045,size*.66),'brass_edge')
    part(m,'Heavy circumferential ivory robe with ten independent broad curved folds and uneven torn hems')
    for i in range(10):
        t=i*2*math.pi/10
        start=len(m.vertices)
        tail=.12+.19*(.5+.5*math.sin(i*2.14))
        pts=[(0,.32,2.69),(0,.43,2.18),(.02,.55,1.62),(-.035,.70,.91),(.035,.68,tail)]
        curved_sheet(m,pts,[.13,.17,.19,.22,.10],'royal_cloth',.075,.075,'royal_edge' if i%3==0 else None)
        m.transform_since(start,Matrix.Rotation(t,4,'Z'))
    part(m,'Broad folded shoulder mantle and long torn hanging ceremonial sleeves')
    for side in (-1,1):
        for y,lower,width in [(-.20,.52,.34),(.04,.71,.37),(.29,.93,.30)]:
            pts=[(side*.26,y,2.73),(side*.70,y-.045,2.69),(side*1.10,y-.10,2.29),
                 (side*1.33,y-.05,1.68),(side*1.11,y+.03,lower)]
            curved_sheet(m,pts,[.16,width,width*.94,width*.65,.06],'royal_cloth',.08,.08,'royal_edge')
        for y in (-.23,.24):
            curved_sheet(m,[(side*.22,y,2.78),(side*.54,y-.07,2.55),(side*.72,y-.12,2.30)],
                         [.17,.24,.06],'royal_edge',.055,.09)
        m.tube([(side*.48,-.48,2.68),(side*.76,-.46,2.40),(side*1.05,-.43,1.66)],
               [.021,.020,.014],'brass_edge',5)
        chain(m,[(side*(.97+i*.025),-.21,1.31-i*.17) for i in range(4)],'brass',.025)
        m.diamond((side*1.07,-.21,.55),(.07,.06,.16),'brass_edge')
    m.diamond((0,-.43,2.49),(.19,.10,.24),'brass')
    m.diamond((0,-.52,2.49),(.10,.04,.14),'royal_edge')
    part(m,'Seven bounded sound marks that fade outward from the missing face')
    for side in (-1,1):
        for i,h in enumerate((.20,.33,.15)):
            x=side*(.75+i*.17)
            m.tube([(x,-.08,3.23-h*.5),(x,-.08,3.23+h*.5)],[.012,.012],'white_glow',4)
    return ((0,-.08,3.42),'crown_silence','Reference 11 final correction: headless pale-ivory regent in a HEAVY cloth robe, ten broad curved circumferential folds, uneven torn hems, six wide hanging sleeve folds and layered shoulder cloth. Four separate floating crown fragments sit above a genuinely open gold collar; restrained gold trim and bounded sound marks preserve the missing-head motif.')

def the_first_grave(m):
    part(m,'Pale rooted grave golem with five-part pointed tombstone torso')
    for side in (-1,1):
        m.tube([(side*.47,.21,1.44),(side*.73,.26,.95),(side*.99,.10,.32)],
               [.30,.28,.18],'bark_light',7)
        for dx in (-.14,.13):
            m.tube([(side*.90,.11,.43),(side*1.10+dx,-.17,.15),(side*1.20+dx,-.38,.10)],
                   [.12,.079,.009],'ivory',6)
        plate(m,[(side*.63,.58),(side*.43,1.23),(side*.69,1.42),(side*.96,1.15),(side*1.1,.38)],
              .37,'ivory',.05,'bone_high',.76)
    outline=[(-.71,1.11),(-.81,2.83),(-.48,3.38),(0,3.77),(.51,3.37),(.79,2.80),(.69,1.13)]
    plate(m,outline,.62,'ivory',.24,'bone_high',.91)
    arch(m,.51,2.41,3.64,-.13,'thorn_edge',.06)
    m.diamond((0,-.17,3.15),(.10,.05,.24),'ivory')
    m.tube([(-.18,-.17,2.19),(.09,-.20,2.49),(.00,-.20,2.87)],[.04,.041,.02],'jade_glow',5)
    m.tube([(-.18,-.17,2.19),(-.36,-.17,1.82),(-.21,-.16,1.43)],[.033,.024,.007],'jade_glow',5)
    part(m,'Two crooked gravestone shoulders with branching wood fingers')
    for side in (-1,1):
        plate(m,[(side*.57,2.56),(side*.93,2.72),(side*1.24,2.24),(side*1.36,1.91),(side*.83,1.85)],
              .51,'ivory',.10,'bone_high',.84)
        m.tube([(side*1.05,.17,2.24),(side*1.26,.04,1.57),(side*1.20,-.08,1.20)],
               [.20,.17,.10],'bark_light',7)
        for dx in (-.11,.08):
            m.tube([(side*1.21+dx,-.10,1.34),(side*1.38+dx,-.18,1.04),(side*1.25+dx,-.23,.84)],
                   [.08,.06,.007],'ivory',5)
    part(m,'Long specific moss curtains on shoulder edges and broken memorial chips')
    for x,z,width in [(-.74,2.73,.14),(.86,2.58,.17),(-.36,3.36,.11)]:
        m.ellipsoid((x,-.19,z),(.22,.14,.08),'moss_dark',3,7)
        for dx,lo in [(-.07,.52),(.03,.72),(.11,.36)]:
            m.ribbon([(x+dx,-.27,z),(x+dx-.02,-.26,z-lo*.55),(x+dx+.03,-.25,z-lo)],
                     [width*.28,width*.23,.006],'moss_light',.035)
    for x,z in [(-.42,1.92),(.51,2.64),(-.69,2.88)]:
        m.profile([(x,z),(x+.17,z+.13),(x+.07,z-.14)],.04,'thorn_edge',-.15)
    return ((-.05,-.23,2.36),'first_grave_crack','Reference 11: pale pointed tombstone torso on crooked root legs, with an engraved arch and a cold jade-green branching crack. Mineral shoulders, wooden arm joints, branching ivory fingers and selective long moss curtains create a rooted grave golem with warm stone and ancient plant surfaces.')

def the_unwritten(m):
    part(m,'Paper specter built from twelve broad folded black coat pages with unequal ragged tails')
    m.ellipsoid((0,.03,2.33),(.42,.26,.69),'paper_black',5,10)
    for i in range(12):
        t=i*2*math.pi/12
        start=len(m.vertices); tail=.10+.44*(.5+.5*math.sin(i*1.97))
        pts=[(0,.32,2.89),(.03,.46,2.46),(-.04,.50,1.87),(.03,.65,1.18),(-.07,.55,tail)]
        curved_sheet(m,pts,[.12,.17,.18,.21,.025],'paper_black',.075,.055,'paper_wear' if i%4==0 else None)
        m.transform_since(start,Matrix.Rotation(t,4,'Z'))
    part(m,'Faceless irregular torn parchment head with split curled tips')
    m.profile([(-.15,2.97),(-.30,3.23),(-.25,3.48),(-.38,3.71),(-.24,3.78),
               (-.35,4.19),(-.02,4.06),(.02,3.89),(.16,4.02),(.23,3.78),
               (.35,3.82),(.33,3.56),(.23,3.32),(.22,3.08)],.19,'parchment',.02)
    curved_sheet(m,[(-.19,.07,3.65),(-.23,.15,3.91),(-.33,.24,4.12)],
                 [.10,.11,.023],'parchment',.07,.035)
    part(m,'Overlapping curved shoulder pages and bent paper sleeve volumes')
    for side in (-1,1):
        for i in range(4):
            pts=[(side*.21,-.04+i*.10,2.94-i*.09),(side*.60,-.02+i*.11,3.08-i*.10),
                 (side*.94,.08+i*.10,2.90-i*.15),(side*1.14,.13+i*.10,2.49-i*.17)]
            curved_sheet(m,pts,[.13,.25,.25,.035],'paper_black',.067,.075,'parchment' if i==3 else 'paper_wear')
        m.tube([(side*.81,.07,2.46),(side*1.19,.07,2.06),(side*1.37,-.09,1.51)],
               [.16,.13,.10],'paper_black',7)
        for y in (-.01,.16):
            curved_sheet(m,[(side*.77,y,2.49),(side*1.10,y+.03,2.14),(side*1.39,y+.11,1.73),(side*1.52,y+.23,1.03)],
                         [.16,.21,.22,.015],'paper_black',.08,.067,'paper_wear')
        for i,dx in enumerate((-.13,0,.13)):
            m.tube([(side*(1.38+dx),-.13,1.63),(side*(1.49+dx),-.18,1.33-i*.05),
                    (side*(1.39+dx),-.25,1.15-i*.05)],[.065,.053,.006],'parchment',5)
    part(m,'Large physically modeled erased writing and red binding stitches')
    for pts in [[(-.24,-.56,2.74),(-.04,-.57,2.60),(-.19,-.58,2.33),(-.10,-.55,2.12)],
                [(.16,-.56,2.78),(.26,-.58,2.41),(.10,-.58,2.18),(.18,-.56,1.97)],
                [(-.33,-.56,2.38),(-.05,-.60,2.45),(.27,-.59,2.27)]]:
        m.tube(pts,[.020]*len(pts),'white_glow',5)
    for i in range(5):
        z=1.04+i*.13
        m.tube([(-.07,-.59,z-.035),(.07,-.59,z+.035)],[.015,.015],'ruby',4)
    for i,(x,z) in enumerate([(.64,2.57),(.86,2.47),(.68,2.31),(.99,2.36)]):
        star(m,(x,-.31,z),.065,'white_glow',4,.31,.02)
    return ((.10,-.62,2.40),'unwritten_erasure','Reference 12 final correction: a specter whose coat is made from twelve broad physically folded black pages with uneven ragged hems, eight curved shoulder pages and torn bent paper sleeves. The faceless parchment head has split irregular curled tips rather than ruled notebook lines; pale writing claws, asymmetrical erased glyphs and red bookbinding stitches carry the concept.')

def last_star(m):
    part(m,'Four articulated sentinel feet and knee plates')
    for x,y,lean in [(-1.15,-.55,-.13),(1.15,-.55,.16),(-.92,.63,-.02),(.92,.63,.03)]:
        limb(m,[(x*.75,y*.8,1.43),(x+lean,y,1.04),(x*1.1,y-.03,.42),(x*1.13,y-.10,.20)],
             [.28,.25,.24,.17])
        plate(m,[(x-.33,.23),(x-.28,.75),(x-.11,1.05),(x+.23,.86),(x+.30,.31)],.29,'star_iron',y-.25,'star_edge',.70)
        claws(m,(x*1.13,y-.13,.19),scale=1.06)
    part(m,'Open octagonal chest frame and layered shoulder buttresses')
    m.bevel_box((0,.14,1.40),(1.9,.72,.36),'star_iron',.12)
    for side in (-1,1):
        # Three separate depth ribs enclose, rather than fill, the open chest.
        for depth,spread in [(-.38,1.0),(.10,1.05),(.57,.85)]:
            pts=[(side*.23,depth,1.56),(side*.82*spread,depth,1.86),(side*1.08*spread,depth,2.47),
                 (side*.98*spread,depth,3.20),(side*.59*spread,depth,3.58)]
            m.tube(pts,[.16,.17,.16,.15,.10],'star_iron',6)
            m.tube([(x-side*.025,y-.14,z+.04) for x,y,z in pts],[.034]*len(pts),'star_edge',4)
        for z in (1.83,2.34,2.87,3.32):
            m.tube([(side*.70,-.26,z),(side*.70,.54,z+.04)],[.075,.055],'star_edge',5)
        shoulder=[(side*.86,3.23),(side*1.22,3.61),(side*1.53,3.30),(side*1.69,2.84),(side*1.30,2.82)]
        plate(m,shoulder,.54,'star_iron',-.06,'star_edge',.76)
        limb(m,[(side*1.38,.03,2.94),(side*1.63,-.02,2.40),(side*1.69,-.13,1.62)],
             [.22,.19,.20])
        plate(m,[(side*1.45,2.32),(side*1.73,2.56),(side*1.94,2.11),(side*1.86,1.70),(side*1.52,1.76)],
              .43,'star_iron',-.20,'star_wear',.57)
        for dx,dz in [(0,0),(.16,-.05),(-.12,.04)]:
            spike(m,(side*(1.69+dx),-.27,1.78+dz),(side*(1.62+dx),-.39,1.29+dz),.075,'star_edge')
    part(m,'Eight pointed imprisoned star with cold white center')
    star(m,(0,-.14,2.61),.79,depth=.25)
    m.diamond((0,-.32,2.61),(.20,.18,.24),'cold_white')
    # Cage link studs intentionally point inward without obscuring the white star.
    for side in (-1,1):
        for z in (2.01,2.36,2.80,3.12):
            spike(m,(side*.89,-.34,z),(side*.66,-.40,z+.04),.085,'star_wear')
    part(m,'Narrow split helm and faceted blind visor')
    m.tube([(0,.11,3.47),(0,.11,3.72)],[.13,.11],'star_iron',7)
    plate(m,[(-.34,3.68),(-.52,4.08),(-.22,4.36),(0,4.62),(.35,4.33),(.43,4.03),(.16,3.66)],
          .49,'star_edge',.06,'ivory',.71)
    m.profile([(-.025,3.74),(.06,3.85),(.04,4.32),(-.06,4.20)],.035,'obsidian',-.25)
    for side in (-1,1):
        plate(m,[(side*.29,4.25),(side*.13,3.70),(side*.23,3.56),(side*.40,3.97)],.15,'star_edge',-.20)
    return ((0,-.38,2.61),'last_star_cage',
            'Reference 12: blind iron sentinel on four articulated claw feet; three layered open ribs on each side surround a suspended volumetric eight-point cold-white star. Narrow split helm and shaped weathered plates preserve negative space from every angle.')

MODELS={
 'night_harp':('Night Harp','Legendary','assets/reference/rework-07-legendary.png',night_harp),
 'thorn_cathedral':('Thorn Cathedral','Legendary','assets/reference/rework-07-legendary.png',thorn_cathedral),
 'phantom_marionette':('Phantom Marionette','Legendary','assets/reference/rework-07-legendary.png',phantom_marionette),
 'blood_moon_rose':('Blood Moon Rose','Legendary','assets/reference/rework-07-legendary.png',blood_moon_rose),
 'judgement_scales':('Judgement Scales','Legendary','assets/reference/rework-07-legendary.png',judgement_scales),
 'clockwork_raven':('Clockwork Raven','Legendary','assets/reference/rework-08-legendary.png',clockwork_raven),
 'eclipse_stag':('Eclipse Stag','Legendary','assets/reference/rework-08-legendary.png',eclipse_stag),
 'endless_library':('Endless Library','Legendary','assets/reference/rework-08-legendary.png',endless_library),
 'sunken_crown':('Sunken Crown','Legendary','assets/reference/rework-08-legendary.png',sunken_crown),
 'silent_choir':('Silent Choir','Legendary','assets/reference/rework-08-legendary.png',silent_choir),
 'cathedral_heart':('Cathedral Heart','Mythic','assets/reference/rework-09-mythic.png',cathedral_heart),
 'plague_monarch':('Plague Monarch','Mythic','assets/reference/rework-09-mythic.png',plague_monarch),
 'hollow_throne':('Hollow Throne','Mythic','assets/reference/rework-09-mythic.png',hollow_throne),
 'worldroot':('Worldroot','Mythic','assets/reference/rework-10-mythic.png',worldroot),
 'the_undertow':('The Undertow','Mythic','assets/reference/rework-10-mythic.png',the_undertow),
 'the_last_funeral':('The Last Funeral','Mythic','assets/reference/rework-10-mythic.png',the_last_funeral),
 'nameless_door':('Nameless Door','Secret','assets/reference/rework-11-secret.png',nameless_door),
 'crown_of_silence':('Crown of Silence','Secret','assets/reference/rework-11-secret.png',crown_of_silence),
 'the_first_grave':('The First Grave','Secret','assets/reference/rework-11-secret.png',the_first_grave),
 'the_unwritten':('The Unwritten','Secret','assets/reference/rework-12-secret.png',the_unwritten),
 'the_last_star':('The Last Star','Secret','assets/reference/rework-12-secret.png',last_star),
}

def main():
    requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['the_last_star']
    ids=list(MODELS) if requested==['all'] else requested
    existing=SOURCE/'high_geometry.json'
    rows=json.loads(existing.read_text(encoding='utf-8'))['assets'] if existing.exists() else []
    for id in ids:
        reset(); m=PaintedSculpt(); display,rarity,reference,fn=MODELS[id]
        hook,profile,notes=fn(m)
        obj,row=m.finish(id,display,rarity,reference,hook,profile,notes,diagonal_limit=6.9)
        render(obj,SOURCE/(id+'_preview.png'),azimuth=.58)
        row['roundtrip']=validate_asset(row)
        (SOURCE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
        rows=[r for r in rows if r['id']!=id]+[row]
        print('HIGH_REWORK_VALIDATED',json.dumps(row),flush=True)
        (SOURCE/'high_geometry.json').write_text(json.dumps({'count':len(rows),'assets':rows},indent=2)+'\n',encoding='utf-8')
        (SOURCE/'high_validation.json').write_text(json.dumps({'count':len(rows),'assets':[row['roundtrip'] for row in rows]},indent=2)+'\n',encoding='utf-8')

if __name__=='__main__': main()
