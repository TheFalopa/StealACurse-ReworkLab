"""Preserve actual native CaptureService files before ending the Studio session."""
import json, shutil, subprocess
from pathlib import Path
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
folder = root / 'assets/review/sanctuary-restoration/videos'
manifest = json.loads((folder / 'multiplayer-captures.json').read_text())
capture_folder = Path.home() / 'AppData/Local/Roblox/tmp-capture-storage'
for role, pid in [('OWNER',5044),('OBSERVER',28336)]:
    rows = manifest[role]
    for index, row in enumerate(rows):
        source = capture_folder / ('wob-' + str(pid) + str(index).zfill(6))
        assert source.is_file() and source.stat().st_size > 1000, source
        label = row['label'].lower().replace('_','-')
        dest = folder / ('mp-' + label + '-' + role.lower() + '-native.mp4')
        shutil.copy2(source,dest)
        row['file'] = str(dest.relative_to(root)).replace('\\','/')
        row['bytes'] = dest.stat().st_size
        row['nativeTemporaryFile'] = str(source)
manifest_path = folder / 'multiplayer-captures.json'
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf8')
# These are real pixels at route gait, carry, pedestal and relocation times.
for case in range(8):
    rows = [manifest[role][case] for role in ['OWNER','OBSERVER']]
    label = rows[0]['label'].lower().replace('_','-')
    sheet = Image.new('RGB',(1600,500),(16,21,29))
    draw = ImageDraw.Draw(sheet)
    times = [2.0,2.35,8.0,22.0]
    frames = folder / ('mp-' + label + '-frames'); frames.mkdir(exist_ok=True)
    for row_index, row in enumerate(rows):
        for col, time in enumerate(times):
            out = frames / (row['role'].lower() + '-' + str(time) + '.png')
            subprocess.run([str(root/'tests/ffmpeg-review.exe'),'-loglevel','error','-y',
                            '-ss',str(time),'-i',str(root/row['file']),'-frames:v','1',str(out)],check=True)
            im = Image.open(out).convert('RGB'); im.thumbnail((400,220))
            x,y = col*400,row_index*250
            sheet.paste(im,(x,y))
            draw.text((x+6,y+224),row['role']+' / '+str(time)+' s',fill='white')
    sheet.save(folder/('mp-'+label+'-contact.png'))
print('Preserved',sum(len(rows) for rows in manifest.values()),'actual native clips and 8 contact sheets')
