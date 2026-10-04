"""Extract the authored physical contact markers into Roblox coordinates, height 6."""
import sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:\RobloxProjects\StealACurse');sys.path.insert(0,str(ROOT/'assets/source/blender/curse_animation'))
from audit_semantics import author,original
ledger=json.loads((ROOT/'assets/imports/curse-animation-current.json').read_text())
feet={
 'grave_hopper':[(-1.04,-.70,.11),(1.04,-.70,.11),(-1.27,.10,.09),(1.27,.10,.09)],
 'hourglass_hound':[(x-.36,y*1.3,.12)for x,y in [(-.71,-.39),(-.73,.34),(.77,-.37),(.80,.34)]],
 'nail_beetle':[(s*1.05,-.32+i*.34-.34,.08)for s in [-1,1]for i in range(3)],
 'coin_crawler':[(s*1.25,y*1.33,.09)for s in [-1,1]for y in [-.44,.37]],
 'thimble_spider':[(s*(1.60+.08*__import__('math').cos(i)),-.43+i*.33-.50,.095)for s in [-1,1]for i in range(4)],
 'anchor_crab':[(s*(1.61+i*.07),-.30+i*.33-.21,.10)for s in [-1,1]for i in range(3)],
 'hollow_violin':[(-.58,-.21,.10),(.58,-.21,.10)],
 'clockwork_raven':[(-.42,-.16,.16),(.42,-.16,.16)],
 'eclipse_stag':[(x-.08,y-.13,.12)for x,y in [(.40,-.25),(.42,.35),(-.77,-.26),(-.70,.36)]],
 'thorn_cathedral':[(x*1.42,y-.15,.13)for x,y in [(-.74,-.48),(.59,-.48),(-.68,.62),(.68,.62)]],
 'endless_library':[(x*1.15,y-.25,.14)for x,y in [(-1.02,-.12),(-.81,.37),(1,-.12),(.81,.37)]],
}
output={}
for ident,points in feet.items():
 m=original.geo.Sculpt();author(ident)(m)
 lo=Vector([min(v[i]for v in m.vertices)for i in range(3)]);hi=Vector([max(v[i]for v in m.vertices)for i in range(3)]);center=(lo+hi)/2
 size=Vector((ledger[ident]['observedSize'][0],ledger[ident]['observedSize'][2],ledger[ident]['observedSize'][1]));scale=size.z/6
 def native(p):
  v=Vector([(p[i]-center[i])*size[i]/(hi[i]-lo[i])/scale for i in range(3)])
  return [-v.x,v.z,v.y]
 output[ident]=[native(p)for p in points]
(ROOT/'assets/review/animations-polished/creatures-foot-markers.json').write_text(json.dumps(output,indent=2))
print('local contact = {')
for ident,points in output.items():
 print('\t'+ident+' = {'+','.join('Vector3.new('+','.join(f'{x:.7f}'for x in p)+')'for p in points)+'},')
print('}')
