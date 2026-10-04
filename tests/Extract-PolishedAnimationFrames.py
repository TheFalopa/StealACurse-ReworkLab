"""Decode native Roblox videos, preserving original pixels for pose review."""
import json,subprocess,sys
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
base=ROOT/'assets/review/animations-polished/videos';base.mkdir(exist_ok=True)
n=int(sys.argv[1]);video=base/f'native-batch{n:02}.mp4'
out=base/f'batch{n:02}-frames';out.mkdir(exist_ok=True)
times=[1.5,5.8,8.7,8.82,12.0,13.8,15.65,19.9,22.6,22.72,26.2,27.9]
sheet=Image.new('RGB',(1200,4*270),(14,19,28));draw=ImageDraw.Draw(sheet)
for i,t in enumerate(times):
    frame=out/f'{i+1:02}.png'
    subprocess.run([str(ROOT/'tests/ffmpeg-review.exe'),'-loglevel','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(frame)],check=True)
    im=Image.open(frame).convert('RGB');im.thumbnail((400,240))
    x=i%3*400;y=i//3*270;sheet.paste(im,(x,y))
    draw.text((x+5,y+244),f'{t:.2f}s · '+(['IDLE A','IDLE B','ROUTE A','ROUTE B','CARRY A','CARRY B'][i%6]),fill='white')
sheet.save(base/f'batch{n:02}-contact.png')
print(base/f'batch{n:02}-contact.png')
