"""Decode native Roblox recordings, preserving their original pixels."""
import sys,subprocess,json
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
folder=root/'assets/review/management-animations/videos'
batch=int(sys.argv[1]);video=folder/f'phase4-native-batch{batch:02}.mp4'
out=folder/f'batch{batch:02}-frames';out.mkdir(exist_ok=True)
images=[]
for i in range(4):
 for stage in range(3):
  t=i*6.6+stage*2.2+1.3
  frame=out/f'{i+1}-{stage+1}.png'
  subprocess.run([str(root/'tests/ffmpeg-review.exe'),'-loglevel','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(frame)],check=True)
  im=Image.open(frame).convert('RGB');im.thumbnail((400,240))
  images.append((im,t))
sheet=Image.new('RGB',(1200,4*270),(14,19,28));draw=ImageDraw.Draw(sheet)
for i,(im,t)in enumerate(images):
 x=(i%3)*400;y=(i//3)*270
 sheet.paste(im,(x,y));draw.text((x+5,y+243),f'{t:.1f}s - '+['PLACED','PROCESSION','CARRYING'][i%3],fill='white')
sheet.save(folder/f'batch{batch:02}-contact.png')
print(str(folder/f'batch{batch:02}-contact.png'))
