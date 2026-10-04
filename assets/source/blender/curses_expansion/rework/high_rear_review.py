"""Render the actual saved editables from the opposite side without saving edits."""
from pathlib import Path
import sys,json,math
import bpy
sys.dont_write_bytecode=True
SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[4]
sys.path.insert(0,str(SOURCE))
from rework_geometry import render
rows=json.loads((SOURCE/'high_geometry.json').read_text(encoding='utf-8'))['assets']
requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else None
if requested: rows=[r for r in rows if r['id'] in requested]
for row in rows:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/row['blendSource']))
    obj=bpy.data.objects.get(row['id'])
    if not obj or obj.type!='MESH': raise RuntimeError('Missing saved editable mesh')
    obj.rotation_euler.z=math.pi
    render(obj,SOURCE/(row['id']+'_rear.png'),azimuth=.65)
    print('HIGH_REAR_RENDER',row['id'],flush=True)
