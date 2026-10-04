"""Actual saved Blender source rotations for the three high-rarity representatives.

Only preview state is rotated; saved editables and frozen FBXs stay unchanged.
"""
from pathlib import Path
import sys,json,math
import bpy
sys.dont_write_bytecode=True
SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[4]
sys.path.insert(0,str(SOURCE))
from rework_geometry import render
for id in ('night_harp','worldroot','the_last_star'):
    for degrees in (0,90,180,270):
        bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(id+'.blend')))
        obj=bpy.data.objects[id]; obj.rotation_euler.z=math.radians(degrees)
        render(obj,SOURCE/(id+'_angle_'+str(degrees)+'.png'),azimuth=.28)
        print('HIGH_TURNAROUND',id,degrees,flush=True)
