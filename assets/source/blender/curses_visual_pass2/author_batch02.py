"""Night-readability revisions driven by individual native Studio captures.

Loads the real editable meshes; preserves apertures, painted motifs and all
concept-specific construction. No subdivision or indiscriminate polygon gain.
Semantic pre-triangulation face ranges are deliberately not used for painting.
"""
import sys, json, hashlib, math, re
from pathlib import Path
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OLD=ROOT/'assets/source/blender/curses_expansion/rework'
sys.path.insert(0,str(HERE))
import author_batch01 as batch
SOURCE=HERE/'batch02'
EXPORT=ROOT/'assets/export/meshes/curses/visual-pass2/batch02'
SOURCE.mkdir(exist_ok=True); EXPORT.mkdir(exist_ok=True)

# H, optional W/D, material family, specific observed issue.
DESIGNS={
 'cold_teacup':(4.9,5,None,'steam','Lift only the black curled steam above the porcelain rim; preserve white porcelain and blue botanical paint.'),
 'grave_key':(4.6,None,None,'steel','Readable cool iron and worn bronze edge; preserve the broken key-ring opening and blue scarf.'),
 'mourning_ribbon':(4.8,6.4,None,'cloth_plum','Shaped satin folds and pale violet edge faces expose both asymmetric bow loops and frayed tails.'),
 'wilted_sprout':(4.8,None,None,'plant','Dry olive stem facets and ochre petal faces stay distinct from the genuinely dark nested face.'),
 'hourglass_hound':(3.8,5.8,None,'sand','Dark ochre sand cones replace unreadable black fill; keep the open framed waist and pale grain stream.'),
 'nail_beetle':(3.2,5.6,5.4,'rust','Low broad six-leg stance, broad coffin nail head, visibly worn iron and orange rust surfaces.'),
 'umbrella_wraith':(5.2,None,2.8,'cloth_blue','Cool charcoal canopy facets and blue-gray seams reveal the folded, torn umbrella; preserve the pale eye and brass hook.'),
 'veil_mourner':(6.1,None,None,'cloth_slate','Deep slate cloth with lit folded faces; preserve the hollow cloak, faceless interior, lace hems and bone hands.'),
 'raven_quill':(6.4,5.2,2.4,'feather','Broad layered feather barbs in oil-blue charcoal with visible silver-gray faces, bronze nib and orange talons.'),
 'thorn_reliquary':(6.5,None,None,'thorn','Readable aged green thorn entity behind actual native glass, antique bronze cage preserved.'),
 'night_harp':(7.9,None,None,'indigo','Lift sculpted indigo frame faces, retain warm gold strings, pale mask and open instrument interior.'),
 'blood_moon_rose':(7.4,None,None,'rose','Garnet-to-coral petal face contrast separates the concentric sculpted blossom; olive stem stays readable.'),
 'judgement_scales':(7.5,None,None,'steel','Steel facets on the dark half retain the asymmetric ivory/gold judgement identity and open hanging pans.'),
 'eclipse_stag':(8.6,None,None,'stag','Warm charcoal hide with silver-brown facets gives the body volume beneath the ivory antlers and jade mane.'),
 'hollow_throne':(10,None,None,'steel','Cold dark iron with broad pale bevel faces; preserve the empty king silhouette and architectural aperture.'),
 'worldroot':(10.2,None,None,'bark','Warm bark relief and separate moss colors reveal the forked trunk and root feet around the jade seed.'),
 'the_last_funeral':(8.9,10.6,None,'burial','Muted aubergine cloth and graphite leg facets define the coffin bearers beneath the ivory floral inlays.'),
 'the_unwritten':(11.7,None,None,'paper','Ink-charcoal paper folds with dusty warm edges; keep the erased parchment face and white fractured glyphs.'),
}

def painted(rgb, normal, family, pos):
    r,g,b=rgb; maximum=max(rgb); minimum=min(rgb)
    facing=max(0,-normal.y*.7+normal.x*.3+normal.z*.25)
    edge=.72+.28*facing
    if family=='steam':
        if pos.z>.26 and maximum<.065:
            return (.27+facing*.17,.34+facing*.18,.40+facing*.19)
        return rgb
    # True carved eyes, holes and liquid stay black. Families with an entirely
    # dark authored material explicitly opt into a lifted charcoal form.
    forced=family in ('paper','burial','thorn','stag')
    if maximum<.048 and not forced: return rgb
    if family=='rose':
        if r>g*1.8 and r>b*1.25:
            return (min(.96,r*1.23+.13*facing),min(.30,g*1.2+.045*facing),min(.34,b*1.15+.05*facing))
        if maximum<.42 and g>=b: return (r+.075,g+.12,b+.05)
        return rgb
    if family=='plant':
        if .05<maximum<.42 and g>b*1.3: return (min(.7,r+.10),min(.7,g+.16),b+.07)
        if r>g*1.5 and r>b*2: return (min(.96,r+.07*facing),min(.75,g+.05*facing),b)
        return rgb
    if family=='sand':
        # Only the two dark torso cones (X near body center and middle Z).
        if pos.x>-.25 and pos.x<.6 and pos.z>-.55 and maximum<.30:
            return (.38*edge,.28*edge,.14*edge)
        return rgb
    if maximum>.47: return rgb
    if family.startswith('cloth'):
        if maximum>.30 and maximum-minimum>.12: return rgb
        bases={'cloth_plum':(.31,.25,.34),'cloth_blue':(.22,.29,.38),'cloth_slate':(.25,.31,.35)}
        base=bases[family]; gain=.68+maximum*.9+facing*.24
        return tuple(min(.70,c*gain) for c in base)
    if family=='feather':
        if r>g*1.5 and r>b*1.7: return rgb
        return tuple(c*(.68+maximum*.8+facing*.30) for c in (.25,.32,.38))
    if family=='bark':
        if g>r*1.08: return (min(.55,r+.07),min(.62,g+.12),min(.35,b+.04))
        return tuple(c*(.78+maximum*.55+facing*.24) for c in (.45,.33,.19))
    if family=='thorn':
        if r>g*1.25 and r>b*1.7: return rgb
        return tuple(c*(.75+maximum*.6+facing*.20) for c in (.24,.36,.28))
    if family=='indigo':
        if r>g*1.25 and r>b*1.8: return rgb
        return tuple(c*(.72+maximum*.75+facing*.2) for c in (.27,.30,.46))
    if family=='stag':
        if g>r*1.25 and g>b*1.08: return rgb
        return tuple(c*(.70+maximum*.65+facing*.28) for c in (.34,.30,.28))
    if family in ('burial','paper'):
        base=(.28,.23,.29) if family=='burial' else (.27,.25,.28)
        return tuple(c*(.75+maximum*.75+facing*.26) for c in base)
    if family=='rust' and r>g*1.25 and r>b*1.8:
        return (min(.75,r+.15),min(.53,g+.08),min(.35,b+.04))
    # Worn steel is still steel: directionally painted facets, no whole tint.
    return tuple(min(.65,c+.11+facing*.10) for c in rgb)

rows=[]
old_asset_text=(ROOT/'src/shared/CurseExpansionAssets.luau').read_text(encoding='utf-8')
for id,(height,width,depth,family,note) in DESIGNS.items():
    source=HERE/(id+'.blend') if id=='cold_teacup' else OLD/(id+'.blend')
    old=json.loads((source.parent/(id+'_metrics.json')).read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(source)); obj=bpy.data.objects[id]
    obj.location=(0,0,0); mesh=obj.data
    bpy.context.view_layer.update(); dims=obj.dimensions.copy()
    # Independent footprint/height decisions, within measured procession limits.
    scalar=height/dims.z
    desired=Vector((min(11,width or dims.x*scalar),min(6,depth or dims.y*scalar),height))
    factors=Vector(tuple(desired[a]/dims[a] for a in range(3)))
    colors=mesh.color_attributes['SACPaintedColor']; changed=0
    for polygon in mesh.polygons:
        for li in polygon.loop_indices:
            c=colors.data[li]; oldrgb=tuple(c.color_srgb[:3])
            pos=mesh.vertices[mesh.loops[li].vertex_index].co
            rgb=painted(oldrgb,polygon.normal,family,pos)
            if tuple(rgb)!=oldrgb: changed+=1
            c.color_srgb=tuple(max(.005,min(1,a)) for a in rgb)+(1,)
    for vertex in mesh.vertices: vertex.co*=factors
    mesh.update(); bpy.context.view_layer.update(); dims=list(obj.dimensions)
    hook=Vector((old['vfxHook'][0],-old['vfxHook'][2],old['vfxHook'][1]))*factors
    semantic={}
    entry=re.search(r'\t'+re.escape(id)+r' = \{.*?(?=\n\t[a-z_]+ =|\n})',old_asset_text,re.S)
    detail=re.search(r'vfxHooks = \{([^}]+)\}',entry.group(0)) if entry else None
    if detail:
        for name,coordinates in re.findall(r'(\w+) = Vector3.new\(([^)]+)\)',detail.group(1)):
            values=[float(v) for v in coordinates.split(',')]
            semantic[name]=[values[0]*factors.x,values[1]*factors.z,values[2]*factors.y]
    row={**old,'pass':2,'revision':3 if id=='cold_teacup' else 2,
         'source':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
         'blendSource':str((SOURCE/(id+'.blend')).relative_to(ROOT)).replace('\\','/'),
         'export':str((EXPORT/(id+'.fbx')).relative_to(ROOT)).replace('\\','/'),
         'sourceReused':str(source.relative_to(ROOT)).replace('\\','/'),
         'sourceReusedSha256':hashlib.sha256(source.read_bytes()).hexdigest(),
         'blenderDimensions':dims,'intendedRobloxSize':[dims[0],dims[2],dims[1]],
         'robloxIntendedSize':[dims[0],dims[2],dims[1]],
         'vfxHook':[hook.x,hook.z,-hook.y],'vfxHookRoblox':[hook.x,hook.z,-hook.y],
         'vfxHooks':semantic,
         'diagonal':math.sqrt(sum(v*v for v in dims)),
         'localValidation':batch.geo.check_mesh(obj),'changedPaintCorners':changed,
         'designNotes':old['designNotes']+[note],
         'realImportRecorded':False,'appearanceChecked':False,'gameplayChecked':False}
    if id=='thorn_reliquary': row['vfxGeometryScale']=factors.z
    obj['VFXHook_Blender']=list(hook); obj['Pass2DesignNote']=note
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.fbx(filepath=str(ROOT/row['export']),use_selection=True,global_scale=.01,
                            apply_unit_scale=True,object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
    row['sha256']=hashlib.sha256((ROOT/row['export']).read_bytes()).hexdigest()
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/row['source']))
    row['roundtripValidation']=batch.geo.validate_asset(row)
    (SOURCE/(id+'_metrics.json')).write_text(json.dumps(row,indent=2)+'\n',encoding='utf-8')
    rows.append(row)
    print('PASS2_BATCH02_READY',id,row['intendedRobloxSize'],changed,flush=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
for index,row in enumerate(rows):
    with bpy.data.libraries.load(str(ROOT/row['source']),link=False) as (a,b): b.objects=[row['id']]
    obj=b.objects[0]; bpy.context.collection.objects.link(obj); obj.location=((index%5)*16,(index//5)*16,0)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=str(EXPORT/'batch02-18.fbx'),use_selection=True,global_scale=.01,
                        apply_unit_scale=True,object_types={'MESH'},add_leaf_bones=False,colors_type='SRGB')
(SOURCE/'batch02-local-geometry.json').write_text(json.dumps({'assets':rows,'studioImportPending':True},indent=2)+'\n',encoding='utf-8')
print('PASS2_BATCH02_DONE',len(rows),flush=True)
