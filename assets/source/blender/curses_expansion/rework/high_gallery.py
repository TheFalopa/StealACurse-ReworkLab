"""Actual geometry contact sheets; no generative illustration substitutes."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

SOURCE=Path(__file__).resolve().parent
rows=json.loads((SOURCE/'high_geometry.json').read_text(encoding='utf-8'))['assets']
order=['night_harp','thorn_cathedral','phantom_marionette','blood_moon_rose','judgement_scales',
       'clockwork_raven','eclipse_stag','endless_library','sunken_crown','silent_choir',
       'cathedral_heart','plague_monarch','hollow_throne','worldroot','the_undertow','the_last_funeral',
       'nameless_door','crown_of_silence','the_first_grave','the_unwritten','the_last_star']
rows.sort(key=lambda r:order.index(r['id']))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',21)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
for rarity,cols in [('Legendary',5),('Mythic',3),('Secret',3)]:
    selected=[r for r in rows if r['rarity']==rarity]
    for suffix in ('preview','rear'):
        if any(not (SOURCE/(r['id']+'_'+suffix+'.png')).exists() for r in selected): continue
        width=384; height=486; countrows=(len(selected)+cols-1)//cols
        canvas=Image.new('RGB',(cols*width,countrows*height+48),(24,25,29)); draw=ImageDraw.Draw(canvas)
        draw.text((15,10),'HIGH REWORK / '+rarity.upper()+' / '+('FRONT 3/4' if suffix=='preview' else 'REAR 3/4'),font=font,fill=(230,225,204))
        for i,row in enumerate(selected):
            x=(i%cols)*width; y=48+(i//cols)*height
            img=Image.open(SOURCE/(row['id']+'_'+suffix+'.png')).convert('RGB')
            img.thumbnail((width,432)); canvas.paste(img,(x+(width-img.width)//2,y))
            draw.text((x+12,y+435),row['displayName'],font=font,fill=(230,225,204))
            dim=' x '.join(f'{d:.2f}' for d in row['robloxIntendedSize'])
            draw.text((x+12,y+461),f"{dim} studs | {row['triangles']:,} tris",font=small,fill=(180,188,201))
        canvas.save(SOURCE/('high_'+rarity.lower()+'_'+suffix+'_sheet.png'))
        print('CONTACT_SHEET',rarity,suffix)
