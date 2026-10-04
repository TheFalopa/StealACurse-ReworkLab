"""Write the human-readable and machine-readable high-rarity local review.

Run after reviewing the actual front/rear sheets and representative rotations.
Does not mark Roblox importer, gameplay, spawning or enabling as verified.
"""
from pathlib import Path
import json,hashlib
from PIL import Image, ImageDraw, ImageFont

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[4]
geometry=json.loads((SOURCE/'high_geometry.json').read_text(encoding='utf-8'))
batch=json.loads((SOURCE/'high_import_batch_validation.json').read_text(encoding='utf-8'))
rows=geometry['assets']
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',21)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
representatives=[]
for id,rarity in [('night_harp','Legendary'),('worldroot','Mythic'),('the_last_star','Secret')]:
    row=next(r for r in rows if r['id']==id)
    canvas=Image.new('RGB',(1536,494),(24,25,29)); draw=ImageDraw.Draw(canvas)
    draw.text((14,10),f"{rarity.upper()} / {row['displayName']} / ACTUAL SAVED BLENDER GEOMETRY",font=font,fill=(230,225,204))
    views=[]
    for i,angle in enumerate((0,90,180,270)):
        source=SOURCE/(id+'_angle_'+str(angle)+'.png')
        img=Image.open(source).convert('RGB'); img.thumbnail((384,432)); canvas.paste(img,(i*384,45))
        draw.text((i*384+13,471),str(angle)+' degrees',font=small,fill=(180,188,201))
        views.append(str(source.relative_to(ROOT)).replace('\\','/'))
    sheet=SOURCE/('high_'+id+'_turnaround.png'); canvas.save(sheet)
    representatives.append({'id':id,'rarity':rarity,'angles':[0,90,180,270],
                            'views':views,'sheet':str(sheet.relative_to(ROOT)).replace('\\','/')})
review={'scope':'Legendary10,Mythic6,Secret5; authored local Blender geometry, not live Roblox validation',
        'assetCount':21,'referencesReviewed':[f'assets/reference/rework-{n:02d}-{r}.png' for n,r in [(7,'legendary'),(8,'legendary'),(9,'mythic'),(10,'mythic'),(11,'secret'),(12,'secret')]],
        'totalTriangles':sum(r['triangles'] for r in rows),'maximumDiagonal':max(r['diagonal'] for r in rows),
        'localFrontRearReviewed':True,'representativeFourAngleTurnarounds':representatives,
        'singleAssetFbxRoundtrips':'PASS all21; actual topology/color/UV/finite centered bounds',
        'combinedBatch':batch['batchExport'],'combinedBatchSha256':batch['batchSha256'],
        'combinedBatchValidation':'PASS all21; exact individual component color sets, topology, dimensions and current FBX hashes',
        'sourcesRemainEditable':True,'frozenIndividualExports':True,'frozenBatchExport':True,
        'realImportRecordedByThisAgent':False,'liveRobloxAppearanceCheckedByThisAgent':False,
        'gameplayCheckedByThisAgent':False,'publishPerformed':False,
        'assets':[{'id':r['id'],'blendSource':r['blendSource'],'export':r['export'],'fbxSha256':r['sha256'],
                   'triangles':r['triangles'],'robloxIntendedSize':r['robloxIntendedSize'],'vfxHookRoblox':r['vfxHookRoblox'],
                   'vfxProfile':r['vfxProfile'],'palette':r['palette'],'designNotes':r['designNotes'],
                   'front':f"assets/source/blender/curses_expansion/rework/{r['id']}_preview.png",
                   'rear':f"assets/source/blender/curses_expansion/rework/{r['id']}_rear.png"} for r in rows]}
for row in rows:
    path=ROOT/row['export']
    if hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']: raise RuntimeError('Frozen FBX changed')
if hashlib.sha256((ROOT/batch['batchExport']).read_bytes()).hexdigest()!=batch['batchSha256']: raise RuntimeError('Frozen batch changed')
(SOURCE/'high_local_review.json').write_text(json.dumps(review,indent=2)+'\n',encoding='utf-8')
lines=['# High rarity Curse rework — local authoring review','',
       '21 actual editable Blender sources and individually exported meshes follow current reference sheets 07–12. The final geometry uses distinct object identities, closed shells and authored material-specific vertex paint with normalized UVs. All models remain below the existing seven-stud diagonal contract.','',
       f"Local evidence: **{review['totalTriangles']:,} total triangles**, maximum diagonal **{review['maximumDiagonal']:.3f} studs**. All21 individual FBX roundtrips pass. Combined HIGH21 import FBX also passes exact individual color-set, UV, scale, origin and topology comparisons.",'',
       f"Frozen batch SHA256: `{batch['batchSha256']}`",'',
       '## Review artifacts','',
       '- Front and rear sheets: `high_legendary_preview_sheet.png`, `high_legendary_rear_sheet.png`, equivalent Mythic/Secret sheets.',
       '- Four-angle geometry rotations: `high_night_harp_turnaround.png`, `high_worldroot_turnaround.png`, `high_the_last_star_turnaround.png`.',
       '- Exact source paths, component hashes, palette roles, centered native VFX hooks and design notes: `high_geometry.json` and `high_local_review.json`.',
       '- Actual FBX evidence: `high_validation.json` and `high_import_batch_validation.json`.',
       '- Rerunnable authoring: `high_generate.py`; shared primitive/FBX helper: `rework_geometry.py`.',
       '- Actual component batch builder: `high_import_batch.py`. It imports the frozen individual FBXs, restores100× authored scale, exports distinct names at0.01 and reimports the batch. It never joins components or rewrites individual FBXs.','',
       '## Reference corrections accepted during review','',
       '- The Last Funeral is a horizontal long coffin on four tall curved strap legs, with real wrap bands and raised ivory memorial lilies.',
       '- Blood Moon Rose has21 closed curved petals in three overlapping cupped rings, dark garnet surfaces and a small restrained core.',
       '- Crown of Silence has a broad pale cloth robe, ten physical circumferential folds, six wide sleeve folds, an open collar and four separate floating crown fragments.',
       '- The Unwritten has a coat of folded black pages, curved page shoulders/sleeves and an irregular torn faceless parchment head.','',
       '## Integration scope','',
       'This review verifies local authoring and FBX exports. The parent task records real Roblox import IDs, checks actual Studio appearance, native VFX and production gameplay before enabling any new Curse. The six originals, economy and gameplay code were not edited by this authoring agent.','',
       '## Per-Curse geometry','',
       '| Curse | Rarity | Triangles | Roblox width × height × depth | Native VFX hook profile |',
       '|---|---|---:|---|---|']
for row in sorted(rows,key=lambda r:({'Legendary':0,'Mythic':1,'Secret':2}[r['rarity']],r['displayName'])):
    dims=' × '.join(f'{d:.2f}' for d in row['robloxIntendedSize'])
    lines.append(f"| {row['displayName']} | {row['rarity']} | {row['triangles']:,} | {dims} | `{row['vfxProfile']}` |")
(SOURCE/'high_review.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('HIGH_LOCAL_REVIEW',len(rows),review['totalTriangles'],review['maximumDiagonal'],batch['batchSha256'])
