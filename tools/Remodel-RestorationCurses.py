"""Editable sanctuary visual repairs, preserving authored animation rest rigs.

Run with Blender 5.2 --background --python this_file.py -- --inspect or --produce.
Only sanctuary-restoration source, export and visual evidence directories change.
Actual native import IDs and Play approvals must be recorded by Studio integration.
"""
import bpy, json, hashlib, sys, math, bmesh
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(r'C:\RobloxProjects\StealACurse')
SRC=ROOT/'assets/source/blender/sanctuary-restoration'
OUT=ROOT/'assets/export/meshes/curses/sanctuary-restoration'
EVID=ROOT/'assets/review/sanctuary-restoration/visuals'
for d in (SRC,OUT,EVID):d.mkdir(parents=True,exist_ok=True)
LEDGER=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())
TARGETS=['grave_hopper','nail_beetle','coin_crawler']

def source_for(ident):
    p=ROOT/'assets/source/blender/animations-polished'/f'{ident}.blend'
    if p.exists():return p
    return ROOT/'assets/source/blender/curse_animation'/f'{ident}.blend'

def repair_coin_knees(obj,arm,parts):
    """Match four legacy knee pivots/skin boundaries to the authored bent tubes.

    The Common authoring recipe is still present and the rest source is unchanged.
    hip=.62x,.58z; real bend=.99x,.63z, y=.95*hip.y. Recover its
    independent source X/Y/Z scales from the actual loaded bones/lathe bounds.
    Foot volumes, hips, hierarchy and all non-leg weights remain untouched.
    """
    hips=[arm.data.bones['Leg'+str(i)].head_local.copy()for i in range(4)]
    fx=abs(hips[0].x)/.62
    fy=(hips[1].y-hips[0].y)/.81
    outer=[obj.data.vertices[i].co.z for i in parts[0]]
    fz=(max(outer)-min(outer))/.47
    old=rig_record(arm);newpoints=[]
    for i,hip in enumerate(hips):
        side=-1 if hip.x<0 else 1
        authored_y=-.44 if i%2==0 else .37
        newpoints.append(Vector((side*.99*fx,hip.y-authored_y*.05*fy,hip.z+.05*fz)))
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
    for i,p in enumerate(newpoints):
        b=arm.data.edit_bones['Knee'+str(i)];delta=p-b.head.copy();b.head+=delta;b.tail+=delta
    bpy.ops.object.mode_set(mode='OBJECT');changed=[]
    def segment(v,a,b):
        d=b-a;t=max(0,min(1,(v-a).dot(d)/d.length_squared))
        return (v-a-d*t).length,t
    def smooth(t):t=max(0,min(1,t));return t*t*(3-2*t)
    for i,(component,footcomponent)in enumerate([(17,18),(19,20),(21,22),(23,24)]):
        hip=hips[i];knee=newpoints[i]
        feet=[obj.data.vertices[n].co for n in parts[footcomponent]]
        foot=sum(feet,Vector())/len(feet)
        for n in parts[component]+parts[footcomponent]:
            v=obj.data.vertices[n]
            if n in parts[footcomponent]:distal=1
            else:
                du,tu=segment(v.co,hip,knee);dl,tl=segment(v.co,knee,foot)
                distal=.5*smooth((tu-.83)/.17) if du<=dl else .5+.5*smooth(tl/.17)
            prior=[(obj.vertex_groups[w.group].name,round(w.weight,6))for w in v.groups]
            for g in obj.vertex_groups:g.remove([n])
            if distal<.99999:obj.vertex_groups['Leg'+str(i)].add([n],1-distal,'REPLACE')
            if distal>.00001:obj.vertex_groups['Knee'+str(i)].add([n],distal,'REPLACE')
            now=[(obj.vertex_groups[w.group].name,round(w.weight,6))for w in v.groups]
            if now!=prior:changed.append({'vertex':n,'before':prior,'after':now})
    return {'bonesBefore':old,'bonesAfter':rig_record(arm),'changedWeights':changed,
        'changedWeightCount':len(changed),'changedBoneNames':['Knee'+str(i)for i in range(4)],
        'note':'Only four actual knee pivots and their proximal/distal tube weights change. Hips/feet positions and all names/parents preserved.'}

def bbox(points):
    return {'min':[min(p[k]for p in points)for k in range(3)],
            'max':[max(p[k]for p in points)for k in range(3)]}if points else None

def dominant(obj,v):
    if not v.groups:return None
    return obj.vertex_groups[max(v.groups,key=lambda x:x.weight).group].name

def component_indices(obj):
    adjacency=[set()for _ in obj.data.vertices]
    for edge in obj.data.edges:
        a,b=edge.vertices;adjacency[a].add(b);adjacency[b].add(a)
    unseen=set(range(len(adjacency)));groups=[]
    while unseen:
        first=unseen.pop();members={first};todo=[first]
        while todo:
            for v in adjacency[todo.pop()]:
                if v in unseen:unseen.remove(v);members.add(v);todo.append(v)
        groups.append(sorted(members))
    return groups

def rig_record(arm):
    return [{'name':b.name,'parent':b.parent.name if b.parent else None,
        'head':list(b.head_local),'tail':list(b.tail_local),'matrix':[list(r)for r in b.matrix_local]}for b in arm.data.bones]

def inspect_mesh(ident,obj,arm,components=False):
    mesh=obj.data;mesh.calc_loop_triangles();attrs=[]
    for ca in mesh.color_attributes:
        colors=[tuple(round(c,3)for c in d.color_srgb)for d in ca.data]
        attrs.append({'name':ca.name,'domain':ca.domain,'dataType':ca.data_type,
            'colors':len(set(colors)),'sampleColors':sorted(set(colors))[:20]})
    row={'id':ident,'source':source_for(ident).relative_to(ROOT).as_posix(),
        'sourceSHA256':hashlib.sha256(source_for(ident).read_bytes()).hexdigest(),
        'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),'dimensionsBlender':list(obj.dimensions),
        'nativeMeshId':LEDGER[ident]['meshId'],'materials':[m.name for m in mesh.materials],
        'colorAttributes':attrs,'smoothFaces':sum(p.use_smooth for p in mesh.polygons),
        'uvLayers':[u.name for u in mesh.uv_layers],'bones':rig_record(arm),'groups':[]}
    row['imageTextures']=[{'material':m.name,'image':n.image.name if n.image else None}for m in mesh.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE']
    for g in obj.vertex_groups:
        pts=[v.co for v in mesh.vertices if any(w.group==g.index and w.weight>.05 for w in v.groups)]
        row['groups'].append({'name':g.name,'vertices':len(pts),'bounds':bbox(pts)})
    if components:
        ca=mesh.color_attributes.get('SACPaintedColor')
        row['components']=[]
        for inds in component_indices(obj):
            pts=[mesh.vertices[i].co for i in inds];iset=set(inds)
            counts={}
            for i in inds:
                name=dominant(obj,mesh.vertices[i]);counts[name]=counts.get(name,0)+1
            colors=[tuple(round(c,3)for c in ca.data[l.index].color_srgb[:3])for l in mesh.loops if l.vertex_index in iset]if ca else []
            row['components'].append({'vertices':len(inds),'bounds':bbox(pts),'centroid':[sum(p[k]for p in pts)/len(pts)for k in range(3)],
                'dominantGroups':counts,'colors':sorted(set(colors))[:6]})
    return row

def paint_component(obj,indices,color,contrast=.1,preserve_black=False):
    """Large directional faces; no random per-vertex dirt gradients."""
    inds=set(indices);ca=obj.data.color_attributes['SACPaintedColor']
    for p in obj.data.polygons:
        if not all(v in inds for v in p.vertices):continue
        factor=.94+contrast*max(-.6,min(.7,p.normal.z*.65-p.normal.y*.55+p.normal.x*.2))
        for li in p.loop_indices:
            old=ca.data[li].color_srgb
            if preserve_black and max(old[:3])<.06:continue
            ca.data[li].color_srgb=tuple(min(1,c*factor)for c in color)+(1,)

class Detail:
    def __init__(self):self.v=[];self.f=[];self.colors=[];self.bones=[];self.labels=[]
    def add(self,verts,faces,color,bone,label):
        offset=len(self.v);self.v.extend(tuple(v)for v in verts)
        self.f.extend(tuple(offset+i for i in f)for f in faces)
        self.colors.extend([color]*len(faces));self.bones.extend([bone]*len(verts));self.labels.append({'name':label,'bone':bone,'vertices':len(verts),'faces':len(faces)})
    def tube(self,points,radii,color,bone,label,sides=8):
        vs=[];fs=[]
        for j,p in enumerate(points):
            p=Vector(p);direction=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(j-1,0)])
            q=direction.to_track_quat('Z','Y')
            for i in range(sides):
                a=i*math.tau/sides;vs.append(p+q@Vector((radii[j]*math.cos(a),radii[j]*math.sin(a),0)))
        fs.append(tuple(reversed(range(sides))))
        for j in range(len(points)-1):
            for i in range(sides):fs.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
        fs.append(tuple((len(points)-1)*sides+i for i in range(sides)))
        self.add(vs,fs,color,bone,label)
    def ellipsoid(self,center,radii,color,bone,label,rings=5,sides=12):
        c=Vector(center);vs=[c+Vector((0,0,-radii[2]))];fs=[]
        for j in range(1,rings):
            phi=-math.pi/2+math.pi*j/rings
            for i in range(sides):
                a=i*math.tau/sides;vs.append(c+Vector((radii[0]*math.cos(phi)*math.cos(a),radii[1]*math.cos(phi)*math.sin(a),radii[2]*math.sin(phi))))
        end=len(vs);vs.append(c+Vector((0,0,radii[2])))
        for i in range(sides):fs.append((0,1+(i+1)%sides,1+i))
        for j in range(rings-2):
            for i in range(sides):
                a=1+j*sides+i;b=1+j*sides+(i+1)%sides;fs.append((a,b,b+sides,a+sides))
        for i in range(sides):fs.append((end,1+(rings-2)*sides+i,1+(rings-2)*sides+(i+1)%sides))
        self.add(vs,fs,color,bone,label)
    def prism(self,outline,y,depth,color,bone,label,bevel=.045):
        """Bevelled extruded polygon in X/Z: readable edge, no triangulation noise."""
        cx=sum(p[0]for p in outline)/len(outline);cz=sum(p[1]for p in outline)/len(outline)
        n=len(outline);vs=[];fs=[]
        radius=max(math.hypot(x-cx,z-cz)for x,z in outline)
        for yy,shrink in [(y-depth/2,1-bevel/radius),(y-depth/2+bevel,1),(y+depth/2-bevel,1),(y+depth/2,1-bevel/radius)]:
            vs.extend((cx+(x-cx)*shrink,yy,cz+(z-cz)*shrink)for x,z in outline)
        fs.append(tuple(reversed(range(n))))
        for j in range(3):
            for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
        fs.append(tuple(3*n+i for i in range(n)))
        self.add(vs,fs,color,bone,label)
    def box(self,c,s,color,bone,label,bevel=.035):
        x,y,z=c;w,d,h=s
        self.prism([(x-w/2,z-h/2),(x+w/2,z-h/2),(x+w/2,z+h/2),(x-w/2,z+h/2)],y,d,color,bone,label,min(bevel,d*.3))
    def ring_horizontal(self,c,rx,ry,width,height,color,bone,label,sides=32):
        x,y,z=c;vs=[];fs=[]
        for zz in (z-height/2,z+height/2):
            for rxx,ryy in ((rx,ry),(rx-width,ry-width)):
                vs.extend((x+rxx*math.cos(i*math.tau/sides),y+ryy*math.sin(i*math.tau/sides),zz)for i in range(sides))
        for i in range(sides):
            j=(i+1)%sides
            fs.extend([(i,j,2*sides+j,2*sides+i),(sides+i,3*sides+i,3*sides+j,sides+j),
                (2*sides+i,2*sides+j,3*sides+j,3*sides+i),(i,sides+i,sides+j,j)])
        self.add(vs,fs,color,bone,label)
    def cylinder(self,c,r,h,color,bone,label,sides=20):
        x,y,z=c;vs=[];fs=[]
        for zz in (z-h/2,z+h/2):vs.extend((x+r*math.cos(i*math.tau/sides),y+r*math.sin(i*math.tau/sides),zz)for i in range(sides))
        fs.append(tuple(reversed(range(sides))))
        for i in range(sides):j=(i+1)%sides;fs.append((i,j,sides+j,sides+i))
        fs.append(tuple(sides+i for i in range(sides)))
        self.add(vs,fs,color,bone,label)
    def integrate(self,obj):
        data=bpy.data.meshes.new(obj.name+'_MacroDetails');data.from_pydata(self.v,[],self.f);data.update()
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(data);bm.free()
        new=bpy.data.objects.new(obj.name+'_MacroDetails',data);bpy.context.collection.objects.link(new)
        new.matrix_world=obj.matrix_world
        ca=data.color_attributes.new(name='SACPaintedColor',type='BYTE_COLOR',domain='CORNER')
        for p,color in zip(data.polygons,self.colors):
            facing=max(-.8,min(.8,p.normal.z*.55-p.normal.y*.3+p.normal.x*.15))
            # This is broad face separation for a cheap vertex-painted single material.
            factor=.93+.11*facing
            for li in p.loop_indices:ca.data[li].color_srgb=tuple(min(1,c*factor)for c in color)+(1,)
        for b in set(self.bones):
            g=new.vertex_groups.new(name=b);g.add([i for i,name in enumerate(self.bones)if name==b],1,'REPLACE')
        data.materials.append(obj.data.materials[0])
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);new.select_set(True);bpy.context.view_layer.objects.active=obj
        bpy.ops.object.join();obj.data.update()

def grave(obj,arm,parts):
    stone=(.58,.63,.60);warm=(.75,.74,.65);dark=(.15,.21,.18);moss=(.27,.43,.17)
    paint_component(obj,parts[0],stone,.18,True)
    for i in range(1,13):paint_component(obj,parts[i],(.48,.55,.49),.15)
    paint_component(obj,parts[13],(.41,.48,.44),.16)
    paint_component(obj,parts[14],warm,.05)
    for i in (15,16,24,25,26,27,28):paint_component(obj,parts[i],dark,.07)
    # Make space for the legible inscription above the head without changing its rig.
    for i in (15,16):
        for idx in parts[i]:obj.data.vertices[idx].co.z+=.20
    for i in range(17,24):paint_component(obj,parts[i],moss,.13)
    d=Detail()
    # Border sits proud of the existing warm face, behind its cross and RIP.
    border=[(-.99,-.19),(.98,-.19),(1.01,1.18),(.77,1.77),(.29,2.01),(-.23,2.02),(-.75,1.78),(-.99,1.14),(-.99,-.19)]
    d.tube([(x,.006,z)for x,z in border],[.064]*len(border),(.82,.83,.75),'Shell','TombstoneCutBorder',sides=6)
    # Narrow carved ledges separate capstone and inscription from the amphibian head.
    d.box((0,-.005,.14),(1.74,.11,.095),dark,'Shell','CarvedBaseline')
    d.box((0,-.07,.17),(1.78,.08,.065),(.78,.80,.72),'Shell','CutStoneBaseline')
    # Angular rim and shoulders retain the real hollow mouth, rather than hide it.
    d.tube([(-.94,-1.16,-.59),(-.86,-1.26,-.88),(-.45,-1.25,-1.14),(0,-1.24,-1.20),(.45,-1.25,-1.14),(.86,-1.26,-.88),(.94,-1.16,-.59)],
        [.073,.09,.09,.085,.09,.09,.073],(.76,.78,.70),'Shell','StoneJawCutEdge',sides=6)
    for side in (-1,1):
        # Carved sleepy eyes on the ledge, with expression and actual sockets.
        d.ellipsoid((side*.70,-1.10,-.24),(.26,.18,.23),dark,'Shell','InsetEyeSocket')
        d.ellipsoid((side*.70,-1.255,-.22),(.16,.035,.13),(.91,.87,.59),'Shell','PaleEye')
        d.ellipsoid((side*.685,-1.285,-.225),(.044,.015,.10),(.03,.06,.035),'Shell','StoneEyeSlit',rings=4,sides=10)
        d.prism([(side*.48,-.16),(side*.98,-.18),(side*1.01,-.04),(side*.67,.015)],-1.105,.21,stone,'Shell','HeavyCarvedBrow')
        # Group moss near a shoulder; tiny scattered round dots become readable clusters.
        d.ellipsoid((side*.98,-.73,-.11),(.19,.14,.09),moss,'Shell','MossShoulderPad',rings=3,sides=8)
    for i in range(4):
        p=arm.data.bones['Knee'+str(i)].head_local
        d.ellipsoid(p,(.17,.18,.13),(.76,.78,.70),'Knee'+str(i),'StoneKneeCut',rings=3,sides=8)
    d.integrate(obj)
    # Actual 3D lettering, no high-resolution label texture. It follows Shell.
    curve=bpy.data.curves.new('GraveRIPInscription','FONT');curve.body='RIP';curve.align_x='CENTER';curve.size=.34;curve.extrude=.006;curve.bevel_depth=.003;curve.resolution_u=3
    text=bpy.data.objects.new('GraveRIPInscription',curve);bpy.context.collection.objects.link(text);text.location=(0,-.052,.445);text.rotation_euler=(math.pi/2,0,0)
    bpy.ops.object.select_all(action='DESELECT');text.select_set(True);bpy.context.view_layer.objects.active=text;bpy.ops.object.convert(target='MESH')
    text=bpy.context.object;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    ca=text.data.color_attributes.new(name='SACPaintedColor',type='BYTE_COLOR',domain='CORNER')
    for c in ca.data:c.color_srgb=dark+(1,)
    g=text.vertex_groups.new(name='Shell');g.add(list(range(len(text.data.vertices))),1,'REPLACE');text.data.materials.append(obj.data.materials[0])
    obj.select_set(True);bpy.context.view_layer.objects.active=obj;bpy.ops.object.join()
    return d.labels+[{'name':'RIP actual extruded glyphs','bone':'Shell'}]

def nail(obj,arm,parts):
    body=(.20,.29,.30);plate=(.36,.48,.48);steel=(.70,.72,.66);iron=(.24,.32,.34);rust=(.60,.28,.10)
    paint_component(obj,parts[0],body,.14)
    paint_component(obj,parts[1],(.52,.57,.56),.16)
    paint_component(obj,parts[2],steel,.11)
    paint_component(obj,parts[3],(.27,.34,.34),.16)
    for i in (4,5):
        paint_component(obj,parts[i],(.96,.82,.45),.045)
        for idx in parts[i]:obj.data.vertices[idx].co.y+=.055
    for i in range(6,12):paint_component(obj,parts[i],iron,.14)
    for i in range(12,16):paint_component(obj,parts[i],(.29,.41,.19),.1)
    for i in (16,17):paint_component(obj,parts[i],rust,.06)
    d=Detail()
    # Paired plates flank the forged shaft, with their dark central seam intact.
    for side in (-1,1):
        outline=[(side*.13,-.10),(side*.33,.19),(side*.72,.17),(side*1.03,-.15),(side*.88,-.56),(side*.42,-.63),(side*.17,-.48)]
        d.prism(outline,-.40,.71,plate,'Root','ForgedWingPlate',bevel=.075)
        d.tube([(side*.23,-.79,-.13),(side*.53,-.79,-.02),(side*.84,-.75,-.24)], [.040,.048,.035],steel,'Root','CutPlateEdge',sides=6)
        d.ellipsoid((side*.71,-.75,-.31),(.070,.042,.075),rust,'Root','PlateRivet',rings=3,sides=8)
        d.ellipsoid((side*.53,-2.675,-.60),(.055,.025,.096),(.025,.055,.045),'Root','LivingPupil',rings=4,sides=12)
        d.prism([(side*.23,-.43),(side*.85,-.40),(side*.79,-.24),(side*.36,-.29)],-2.51,.17,plate,'Root','WatchfulHeadPlate')
        d.tube([(side*.50,-2.48,-.93),(side*.33,-2.61,-1.12),(side*.16,-2.57,-1.04)], [.06,.085,.015],steel,'Root','IronMandible',sides=6)
    # A metallic cap edge and square forge-strike are part of the existing Nail.
    d.tube([(-1.13,1.64,.77),(0,1.64,.91),(1.13,1.64,.77)],[.050,.065,.050],(.84,.83,.72),'Nail','ForgedNailHeadLip',sides=6)
    d.box((0,1.64,.55),(.37,.075,.29),rust,'Nail','SquareForgeStamp')
    d.box((0,1.594,.55),(.16,.055,.14),iron,'Nail','ForgeStampInset')
    # Actual knee locations are the repaired animation pivots, not nearest guesses.
    for i in range(6):
        p=arm.data.bones['Knee'+str(i)].head_local
        d.ellipsoid(p,(.35,.31,.28),steel,'Knee'+str(i),'LegJointCollar',rings=3,sides=8)
        hip=arm.data.bones['Leg'+str(i)].head_local
        mid=hip.lerp(p,.63)
        d.tube([hip.lerp(p,.24)+Vector((0,0,.22)),mid+Vector((0,0,.22)),hip.lerp(p,.83)+Vector((0,0,.20))],
            [.033,.043,.025],(.60,.66,.62),'Leg'+str(i),'UpperLegEdge',sides=5)
    d.integrate(obj);return d.labels

def coin(obj,arm,parts):
    bronze=(.64,.41,.18);edge=(.86,.63,.27);graphite=(.19,.28,.27);pale=(.95,.84,.48)
    paint_component(obj,parts[0],bronze,.18)
    paint_component(obj,parts[1],edge,.1)
    for i in range(2,14):paint_component(obj,parts[i],(.85,.64,.30),.08)
    paint_component(obj,parts[14],graphite,.17)
    for i in (15,16):paint_component(obj,parts[i],pale,.03)
    for i in (17,19,21,23):paint_component(obj,parts[i],(.29,.38,.33),.13)
    for i in (18,20,22,24):paint_component(obj,parts[i],(.65,.54,.30),.1)
    for i in (25,26,27):paint_component(obj,parts[i],(.21,.40,.28),.1)
    paint_component(obj,parts[28],(.97,.84,.53),.05)
    d=Detail()
    # Thin rim bands sit on the original thick coin, whose full volume is retained.
    d.ring_horizontal((0,0,.57),2.49,1.85,.060,.09,edge,'CoinLid','LowerMintedEdge')
    # Radial milled edge marks are actual geometry separated at modest density.
    for i in range(20):
        a=i*math.tau/20;x=2.48*math.cos(a);y=1.84*math.sin(a)
        d.tube([(x,y,.51),(x,y,.72)],[.033,.033],(.44,.29,.14),'CoinLid','MilledCurrencyEdge',sides=4)
    # Three distinct actual currency disks: material/rim/stamp read at play distance.
    for n,(x,y,r,z)in enumerate([(-1.46,-.46,.43,1.23),(.23,-.50,.48,1.27),(1.30,.39,.38,1.20)]):
        d.cylinder((x,y,z),r,.17,bronze,'CoinLid','LooseFuneralCoin'+str(n))
        d.ring_horizontal((x,y,z+.094),r*.93,r*.93,.065,.035,pale,'CoinLid','CoinRaisedMintRim'+str(n),sides=20)
        d.cylinder((x,y,z+.097),r*.65,.027,(.32,.39,.27),'CoinLid','CoinInsetPatina'+str(n),sides=16)
        # Simple gate/soul stamp formed with a single cut panel and upper crown.
        d.box((x,y,z+.130),(r*.16,r*.90,.041),pale,'CoinLid','MintedSoulStem'+str(n))
        d.box((x,y-r*.08,z+.133),(r*.67,r*.13,.042),pale,'CoinLid','MintedSoulCross'+str(n))
    # Face remains under the lid, with brows and cheeks attached to its real Gaze.
    for side in (-1,1):
        d.ellipsoid((side*.46,-1.365,-.56),(.064,.026,.15),(.035,.065,.04),'Gaze','CrawlerEyeSlit',rings=4,sides=10)
        d.prism([(side*.18,-.28),(side*.72,-.28),(side*.76,-.14),(side*.30,-.15)],-1.29,.13,graphite,'Gaze','CrawlerBrow')
        d.tube([(side*.68,-1.23,-.92),(side*.36,-1.32,-1.05),(0,-1.33,-1.08)],[.046,.047,.042],(.69,.60,.38),'Root','LowerJawCut',sides=5)
    for i in range(4):
        p=arm.data.bones['Knee'+str(i)].head_local
        d.ellipsoid(p,(.15,.16,.16),edge,'Knee'+str(i),'BronzeLegJoint',rings=3,sides=8)
    d.integrate(obj);return d.labels

def render_mesh(obj,path,angle=.40):
    # Production diagnostic only. Native Play comparison is the coordinator's gate.
    scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
    scene.world=bpy.data.worlds.new('RestorationDiagnosticWorld');scene.world.use_nodes=True
    nodes=scene.world.node_tree.nodes;nodes.clear();background=nodes.new('ShaderNodeBackground');output=nodes.new('ShaderNodeOutputWorld');scene.world.node_tree.links.new(background.outputs[0],output.inputs[0])
    background.inputs[0].default_value=(.035,.045,.065,1);background.inputs[1].default_value=.55
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1
    # Clean all previous source camera/light objects so a rebuild is deterministic.
    for o in list(scene.objects):
        if o.type in ('LIGHT','CAMERA'):bpy.data.objects.remove(o,do_unlink=True)
    def light(name,p,power,size):
        ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size
        lo=bpy.data.objects.new(name,ld);scene.collection.objects.link(lo);lo.location=p;lo.rotation_euler=(Vector((0,0,0))-lo.location).to_track_quat('-Z','Y').to_euler()
    light('SoftKey',(4,-7,8),1100,5);light('WarmFill',(-5,-4,3),650,5);light('EdgeRead',(1,5,6),1000,4)
    camera=bpy.data.cameras.new('DiagnosticCamera');co=bpy.data.objects.new('DiagnosticCamera',camera);scene.collection.objects.link(co)
    maxd=max(obj.dimensions);co.location=(math.sin(angle)*maxd*2.6,-math.cos(angle)*maxd*2.6,maxd*1.15)
    co.rotation_euler=(Vector((0,0,-.14))-co.location).to_track_quat('-Z','Y').to_euler();camera.type='ORTHO';camera.ortho_scale=maxd*1.42;scene.camera=co
    scene.render.filepath=str(path);bpy.ops.render.render(write_still=True)

def export_fbx(obj,arm,path):
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
        object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,colors_type='SRGB')

def produce():
    rows=[]
    for ident in TARGETS:
        src=source_for(ident);bpy.ops.wm.open_mainfile(filepath=str(src));obj=bpy.data.objects[ident];arm=bpy.data.objects[ident+'_Rig']
        before=inspect_mesh(ident,obj,arm);parts=component_indices(obj);rig_before=rig_record(arm)
        rest_verts=[list(v.co)for v in obj.data.vertices]
        rest_weights=[[(obj.vertex_groups[w.group].name,w.weight)for w in v.groups]for v in obj.data.vertices]
        render_mesh(obj,EVID/f'{ident}-blender-before.png')
        repair=repair_coin_knees(obj,arm,parts)if ident=='coin_crawler'else None
        added={'grave_hopper':grave,'nail_beetle':nail,'coin_crawler':coin}[ident](obj,arm,parts)
        if not repair:assert rig_record(arm)==rig_before,'A rest bone or parent changed'
        else:
            now=rig_record(arm)
            for prior,after in zip(rig_before,now):
                if not prior['name'].startswith('Knee'):assert prior==after
                assert prior['name']==after['name'] and prior['parent']==after['parent']
        allowedweights=set(n for c in (17,18,19,20,21,22,23,24)for n in parts[c])if repair else set()
        for i,old in enumerate(rest_weights):
            if i not in allowedweights:assert [(obj.vertex_groups[w.group].name,w.weight)for w in obj.data.vertices[i].groups]==old,'Existing weights changed outside the approved anatomical repair'
        changed=[i for i,v in enumerate(obj.data.vertices[:len(rest_verts)])if (v.co-Vector(rest_verts[i])).length>.00001]
        # Only eye lenses and the inscription's old cross move; existing skin weights stay exact.
        expected={'nail_beetle':set(parts[4]+parts[5]),'grave_hopper':set(parts[15]+parts[16]),'coin_crawler':set()}[ident]
        assert set(changed)==expected
        dims=list(obj.dimensions)
        ca=obj.data.color_attributes['SACPaintedColor'];obj.data.color_attributes.active_color=ca
        for modifier in obj.modifiers:
            if modifier.type=='ARMATURE':modifier.object=arm
        obj['SanctuaryRestorationDesign']='Macrogeometry/material separation; original rest bones, rig, contacts and source volumes preserved.'
        obj['SourceBeforeRestoration']=src.relative_to(ROOT).as_posix()
        bpy.context.preferences.filepaths.save_version=0
        # Render cameras are convenient source views, and never included in FBX.
        render_mesh(obj,EVID/f'{ident}-blender-after.png')
        source=SRC/f'{ident}.blend';bpy.ops.wm.save_as_mainfile(filepath=str(source))
        export=OUT/f'{ident}.fbx';export_fbx(obj,arm,export)
        after=inspect_mesh(ident,obj,arm)
        after['source']=source.relative_to(ROOT).as_posix();after['sourceSHA256']=hashlib.sha256(source.read_bytes()).hexdigest()
        row={'id':ident,'before':before,'after':after,'source':source.relative_to(ROOT).as_posix(),'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'fbx':export.relative_to(ROOT).as_posix(),'fbxSHA256':hashlib.sha256(export.read_bytes()).hexdigest(),'macroDetails':added,
            'originalWeightsPreserved':not bool(repair),'restBoneMatricesAndParentsPreserved':not bool(repair),'allNamesAndParentsPreserved':True,'coinAnatomicalRepair':repair,'originalVertexCount':len(rest_verts),'oldVerticesMoved':len(changed),
            'targetSize':[dims[0],dims[2],dims[1]],'previousObservedSize':LEDGER[ident]['observedSize'],
            'realImportRecorded':False,'playReviewed':False,'newMeshId':None,'vfxNamesChanged':False}
        (EVID/f'{ident}-source-production.json').write_text(json.dumps(row,indent=2));rows.append(row)
        print('RESTORATION_SOURCE_READY',ident,after['triangles'],row['targetSize'],flush=True)
    # Combined native import: one joined armature, id__ names; original local data
    # remains namespaced only in this export, exactly like the working rig batch.
    bpy.ops.wm.read_factory_settings(use_empty=True);meshes=[];arms=[]
    for row in rows:
        ident=row['id']
        with bpy.data.libraries.load(str(ROOT/row['source']),link=False)as(src,dst):dst.objects=[ident,ident+'_Rig']
        for o in dst.objects:bpy.context.collection.objects.link(o)
        mesh=next(o for o in dst.objects if o.type=='MESH');arm=next(o for o in dst.objects if o.type=='ARMATURE')
        for vg in mesh.vertex_groups:vg.name=ident+'__'+vg.name
        for b in arm.data.bones:b.name=ident+'__'+b.name
        meshes.append(mesh);arms.append(arm)
    bpy.ops.object.select_all(action='DESELECT')
    for a in arms:a.select_set(True)
    bpy.context.view_layer.objects.active=arms[0];bpy.ops.object.join();common=arms[0]
    for mesh in meshes:
        world=mesh.matrix_world.copy();mesh.parent=common;mesh.matrix_world=world
        for m in mesh.modifiers:
            if m.type=='ARMATURE':m.object=common
    bpy.ops.object.select_all(action='SELECT');batch=OUT/'sanctuary-curse-remodel-03.fbx'
    bpy.ops.export_scene.fbx(filepath=str(batch),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
        object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,colors_type='SRGB')
    (EVID/'source-production-batch.json').write_text(json.dumps({'assets':rows,'batch':batch.relative_to(ROOT).as_posix(),'batchSHA256':hashlib.sha256(batch.read_bytes()).hexdigest(),'realImportRecorded':False,'playReviewed':False},indent=2))
    print('REAL_FBXS_PREPARED',batch,flush=True)

def verify():
    rows=[]
    for ident in TARGETS:
        source=SRC/f'{ident}.blend';bpy.ops.wm.open_mainfile(filepath=str(source));obj=bpy.data.objects[ident];arm=bpy.data.objects[ident+'_Rig']
        for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
        bpy.context.view_layer.update();base=[v.co.copy()for v in obj.data.vertices];checks=[]
        # One bone at a time: vertices with no weight in its descendants stay fixed.
        for bone in arm.data.bones:
            descendants={bone.name}|{b.name for b in bone.children_recursive}
            weighted={v.index for v in obj.data.vertices if any(obj.vertex_groups[w.group].name in descendants and w.weight>.00001 for w in v.groups)}
            pb=arm.pose.bones[bone.name];pb.rotation_mode='XYZ';pb.rotation_euler=(.19,.07,.03)
            bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();evaluated=obj.evaluated_get(deps);mesh=evaluated.to_mesh()
            moved={i for i,v in enumerate(mesh.vertices)if (v.co-base[i]).length>1e-5}
            evaluated.to_mesh_clear();foreign=moved-weighted
            checks.append({'bone':bone.name,'weightedIncludingDescendants':len(weighted),'verticesMoved':len(moved),'foreignVerticesMoved':len(foreign)})
            assert not foreign,ident+' foreign deformation '+bone.name
            if weighted:assert len(moved)>0,ident+' weighted bone did not move geometry '+bone.name
            pb.matrix_basis=Matrix.Identity(4);bpy.context.view_layer.update()
        totals=[sum(w.weight for w in v.groups)for v in obj.data.vertices]
        assert all(abs(w-1)<.0001 for w in totals),ident+' unnormalized skin weights'
        original=inspect_mesh(ident,obj,arm)
        count=6 if ident=='nail_beetle' else 4
        for i in range(count):
            arm.pose.bones['Leg'+str(i)].rotation_mode='XYZ';arm.pose.bones['Leg'+str(i)].rotation_euler=(.20*(1 if i%2 else-1),.04,0)
            arm.pose.bones['Knee'+str(i)].rotation_mode='XYZ';arm.pose.bones['Knee'+str(i)].rotation_euler=(-.25*(1 if i%2 else-1),0,0)
        special='Shell' if ident=='grave_hopper'else('Nail'if ident=='nail_beetle'else'CoinLid')
        arm.pose.bones[special].rotation_mode='XYZ';arm.pose.bones[special].rotation_euler=(-.08,.06,.02)
        render_mesh(obj,EVID/f'{ident}-blender-articulation.png')
        # Source isn't saved in this test pose. FBX is separately read back from disk.
        bpy.ops.wm.read_factory_settings(use_empty=True);path=OUT/f'{ident}.fbx';bpy.ops.import_scene.fbx(filepath=str(path),use_anim=False)
        imported=next(o for o in bpy.context.scene.objects if o.type=='MESH');rarm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
        imported.data.calc_loop_triangles()
        assert set(b.name for b in rarm.data.bones)==set(b['name']for b in original['bones']),ident+' FBX bone names mismatch'
        assert len(imported.data.loop_triangles)==original['triangles'],ident+' FBX geometry mismatch'
        assert imported.data.color_attributes.get('SACPaintedColor'),ident+' FBX painted color missing'
        assert imported.data.uv_layers.get('CurseMaterialUV'),ident+' FBX inherited UV missing'
        for k in range(3):assert abs(imported.dimensions[k]-original['dimensionsBlender'][k]*.01)<.0001,ident+' FBX scale differs'
        rows.append({'id':ident,'individualFBXSHA256':hashlib.sha256(path.read_bytes()).hexdigest(),'deformationIsolation':checks,
            'roundTrip':{'bones':len(rarm.data.bones),'vertices':len(imported.data.vertices),'triangles':len(imported.data.loop_triangles),
                'dimensionsBlender':list(imported.dimensions),'colorAttributes':[a.name for a in imported.data.color_attributes],'uvLayers':[u.name for u in imported.data.uv_layers]},
            'weightsNormalized':True,'status':'SOURCE_AND_REAL_FBX_VERIFIED','newNativePlayReview':False})
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(OUT/'sanctuary-curse-remodel-03.fbx'),use_anim=False)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    assert set(o.name for o in meshes)==set(TARGETS),'Combined FBX logical identities mismatch'
    expected={r['id']+'__'+c['bone']for r in rows for c in r['deformationIsolation']}
    assert set(b.name for b in arm.data.bones)==expected,'Combined FBX namespaced bones mismatch'
    result={'sources':rows,'combinedMeshes':[o.name for o in meshes],'combinedBoneCount':len(arm.data.bones),'status':'SOURCE_AND_FBX_PASS','nativePlayReviewPending':True}
    (EVID/'rig-deformation-checks.json').write_text(json.dumps(result,indent=2));print('REAL_SOURCE_AND_FBX_VERIFIED',len(rows),len(expected),flush=True)

def main():
    if '--produce' in sys.argv:return produce()
    if '--verify' in sys.argv:return verify()
    audit=[]
    for ident in LEDGER:
        path=source_for(ident)
        if not path.exists():
            audit.append({'id':ident,'missingSource':str(path)});continue
        bpy.ops.wm.open_mainfile(filepath=str(path))
        obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
        arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
        audit.append(inspect_mesh(ident,obj,arm,ident in TARGETS))
    (EVID/'source-audit56.json').write_text(json.dumps(audit,indent=2))
    print('ACTUAL_SOURCE_AUDIT',len(audit),flush=True)

if __name__=='__main__':main()
