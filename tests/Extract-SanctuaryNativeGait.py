"""Dense native frames to judge actual articulated geometry, rather than bones alone."""
import subprocess
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
folder=root/'assets/review/sanctuary-restoration/videos'
sheet=Image.new('RGB',(1600,960),(16,21,29));draw=ImageDraw.Draw(sheet)
for row,stem in enumerate(['grave-hopper','nail-beetle','coin-crawler']):
    for col,t in enumerate([2.0,2.3,2.6,2.9]):
        frame=folder/(stem+'-frames')/f'gait-{t:.1f}.png'
        subprocess.run([str(root/'tests/ffmpeg-review.exe'),'-loglevel','error','-y','-ss',str(t),'-i',str(folder/(stem+'-native.mp4')),'-frames:v','1',str(frame)],check=True)
        im=Image.open(frame).convert('RGB')
        # Crop around the actual screen model from these fixed native QA cameras.
        im=im.crop((300,140,760,500));im.thumbnail((390,290))
        x,y=col*400,row*320;sheet.paste(im,(x,y));draw.text((x+8,y+294),f'{stem} / {t:.1f}s',fill='white')
sheet.save(folder/'native-gait-detail.png')
