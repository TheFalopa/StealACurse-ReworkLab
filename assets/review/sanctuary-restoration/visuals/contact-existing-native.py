"""Crop existing valid native frames for a readable audit, no new Play claims."""
from PIL import Image,ImageDraw
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
rows=json.loads((ROOT/'assets/review/animations-polished/visual-reviewed.json').read_text())
for start in range(0,len(rows),9):
    canvas=Image.new('RGB',(1080,1236),'#171c27');draw=ImageDraw.Draw(canvas)
    for k,row in enumerate(rows[start:start+9]):
        f=8 if row['id']=='thimble_spider' else (1 if (start+k)%2==0 else 7)
        p=ROOT/f'assets/review/animations-polished/videos/batch{row["batch"]:02d}-frames/{f:02d}.png'
        im=Image.open(p)
        box=(im.width*.39,im.height*.05,im.width*.74,im.height*.91)
        canvas.paste(im.crop(box).resize((360,387)),((k%3)*360,(k//3)*412))
        draw.text(((k%3)*360+8,(k//3)*412+389),f'{row["id"]} | old native T{row["batch"]:02d} F{f}',fill='white')
    canvas.save(OUT/f'audit-native-crop-sheet{start//9+1:02d}.png')
print('EXISTING_NATIVE_CROPS',len(rows))
