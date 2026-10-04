"""Contact sheets of actual native Roblox pixels, not synthetic pose evidence."""
import subprocess,sys
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
stem=sys.argv[1];folder=root/'assets/review/sanctuary-restoration/videos'
video=folder/(stem+'-native.mp4');frames=folder/(stem+'-frames');frames.mkdir(exist_ok=True)
times=[2,4.4,8,10.7,12.3,19,22,25]
sheet=Image.new('RGB',(1280,4*390),(16,21,29));draw=ImageDraw.Draw(sheet)
for i,t in enumerate(times):
    output=frames/f'{t:.1f}.png'
    subprocess.run([str(root/'tests/ffmpeg-review.exe'),'-loglevel','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(output)],check=True)
    im=Image.open(output).convert('RGB');im.thumbnail((640,360))
    x=(i%2)*640;y=(i//2)*390;sheet.paste(im,(x,y));draw.text((x+8,y+363),f'{stem} / {t}s',fill='white')
sheet.save(folder/(stem+'-contact.png'));print(folder/(stem+'-contact.png'))
