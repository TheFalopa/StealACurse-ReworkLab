"""Skin the actual 51 remaining sculpts, preserving their painted mesh data.
Semantic volumes are matched to authored source surfaces, not triangulated
face offsets. The prototype is used only to identify anatomy and pivots.
Every exported source remains pending real Studio import and Play review.
"""
import bpy,json,math,sys,hashlib
from collections import Counter
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(HERE))
from inspect_sources import sources,components
from audit_semantics import author,original
EXPORT=ROOT/'assets/export/meshes/curses/animations'

class Plan:
    def __init__(self,id):self.id=id;self.bones={'Root':((0,0,0),None)};self.channels=[];self.legs=[]
    def add(self,name,p,parent='Root',kind='sway',axis='z',amp=.06,period=3,phase=0,idle=1,travel=1):
        self.bones[name]=(p,parent)
        self.channels.append(dict(bone=name,kind=kind,axis=axis,amplitude=amp,period=period,phase=phase,idle=idle,travel=travel))
    def legs_at(self,points,knee=.5,period=1.6,amp=.22):
        for i,p in enumerate(points):
            self.add('Leg'+str(i),p,kind='step',axis='x',amp=amp,period=period,phase=(i%2)*math.pi,idle=0)
            lower=(p[0]*1.17,p[1],knee)
            self.add('Knee'+str(i),lower,'Leg'+str(i),kind='knee',axis='x',amp=amp*.75,period=period,phase=(i%2)*math.pi,idle=0)
            self.legs.append(p)
    def nearest(self,c,names):return min(names,key=lambda n:(c-Vector(self.bones[n][0])).length)

def plan_for(id):
    q=Plan(id);a=q.add;l=q.legs_at
    if id=='haunted_mirror':
        a('Reflection',(.18,.02,2.4),kind='emerge',axis='z',amp=.11,period=8.4);a('GhostHead',(.18,.02,3.5),'Reflection',kind='look',axis='y',amp=.16,period=6.8)
        l([(-.69,0,1.15),(.69,0,1.15)],.55,2.6,.10)
    elif id=='crying_mask':
        for s,b in [(-1,'L'),(1,'R')]:
            a('Tear'+b,(s*.64,-.44,2.9),kind='drip',axis='y',amp=.06,period=3.7,phase=s)
            a('Tie'+b,(s,0,3.55),kind='ribbon',axis='z',amp=.11,period=4.1,phase=s)
        a('Sorrow',(0,0,2.5),kind='bow',axis='x',amp=.045,period=9.8)
    elif id=='candle_wisp':
        a('Flame',(0,0,2.69),kind='flame',axis='z',amp=.13,period=1.7)
        for s,b in [(-1,'L'),(1,'R')]:a('Hand'+b,(s*.44,0,1.73),kind='reach',axis='z',amp=s*.12,period=6.6,phase=s)
    elif id=='grave_hopper':l([(-.77,-.15,.87),(.77,-.15,.87),(-.9,.52,.47),(.9,.52,.47)],.3,1.8,.27);a('Shell',(0,0,1.2),kind='hop',axis='x',amp=.03,period=1.8,idle=.16)
    elif id=='grave_key':l([(.66,0,.8),(.43,.08,1.1)],.43,1.45,.18);a('Scarf',(.06,0,2.06),kind='ribbon',axis='z',amp=.15,period=2.7)
    elif id=='mourning_ribbon':
        for s,b in [(-1,'L'),(1,'R')]:a('Loop'+b,(s*.17,0,2.15),kind='fold',axis='y',amp=s*.09,period=5.3,phase=s*.7);a('Tail'+b,(s*.17,0,2.08),kind='ribbon',axis='z',amp=s*.13,period=3.1,phase=s)
    elif id=='wilted_sprout':
        a('Stem',(0,0,.7),kind='bow',axis='z',amp=.10,period=6.2);a('Bloom',(-.1,-.24,2.53),'Stem',kind='look',axis='y',amp=.10,period=7.3);a('Leaf',(.7,0,1.6),'Stem',kind='fold',axis='x',amp=.18,period=4.6)
    elif id=='ink_imp':
        a('Ink',(0,0,1.4),kind='squirm',axis='z',amp=.10,period=2.9);a('Tail',(-.55,.27,1.92),'Ink',kind='coil',axis='y',amp=.15,period=2.4)
        for s,b in [(-1,'L'),(1,'R')]:a('Hand'+b,(s*.56,0,1.45),'Ink',kind='reach',axis='z',amp=s*.16,period=4.2,phase=s)
    elif id=='lost_locket':
        a('Cover',(-.15,0,1.2),kind='creak',axis='y',amp=.19,period=8.7);a('Palm',(.57,-.225,1.4),kind='emerge',axis='z',amp=.055,period=6)
        for i in range(4):a('Finger'+str(i),(.37+i*.14,-.23,1.52),'Palm',kind='curl',axis='x',amp=.12,period=2.7,phase=i*.7)
    elif id=='ashen_book':
        a('PageWing',(1.1,0,1.09),kind='flutter',axis='z',amp=.16,period=2.1);a('Cover',(0,0,.82),kind='creak',axis='x',amp=.045,period=5.2)
        l([(-.77,0,.38),(.77,0,.38)],.18,1.4,.12)
    elif id=='lantern_lurker':
        l([(-.63,-.4,.95),(.63,-.4,.95),(-.63,.4,.95),(.63,.4,.95)],.45,1.3,.21)
        a('Handle',(-.23,0,2.37),kind='pendulum',axis='z',amp=.07,period=2.8);a('Captive',(0,0,1.3),kind='struggle',axis='z',amp=.045,period=5.6)
    elif id=='hourglass_hound':
        l([(-.71,-.39,1),(-.71,.34,1),(.77,-.37,1),(.77,.34,1)],.57,1.24,.20)
        a('Head',(-.87,0,1.1),kind='sniff',axis='y',amp=.13,period=3.4);a('Tail',(.84,0,1.12),kind='wag',axis='y',amp=.23,period=1.5)
    elif id=='nail_beetle':l([(s*.35,-.32+i*.34,.56)for s in [-1,1]for i in range(3)],.32,1.08,.19);a('Nail',(0,.8,.7),kind='twitch',axis='x',amp=.065,period=6.3)
    elif id=='pale_guest':
        a('Ghost',(.23,-.11,1.31),kind='emerge',axis='z',amp=.13,period=8.5);a('Head',(.23,-.11,1.65),'Ghost',kind='peek',axis='z',amp=.13,period=5.2)
        for x,b in [(-.35,'L'),(.7,'R')]:a('Grip'+b,(x,-.1,.63),kind='curl',axis='x',amp=.1,period=3.3,phase=x)
    elif id=='cold_teacup':a('Steam',(0,0,1.20),kind='coil',axis='y',amp=.14,period=3.2);a('SteamTip',(.2,0,2.04),'Steam',kind='ribbon',axis='z',amp=.16,period=2.7)
    elif id=='coin_crawler':l([(s*.62,y,.58)for s in [-1,1]for y in [-.44,.37]],.35,1.1,.18);a('CoinLid',(0,0,.80),kind='creak',axis='x',amp=.065,period=6.1);a('Gaze',(0,-.795,.38),kind='look',axis='y',amp=.07,period=4.1)
    elif id=='umbrella_wraith':
        for s,b in [(-1,'L'),(1,'R')]:a('Wing'+b,(s*.17,0,2.14),kind='fold',axis='z',amp=s*.16,period=4.8,phase=s*.5);a('Rag'+b,(s,0,1.4),'Wing'+b,kind='ribbon',axis='x',amp=.12,period=2.9,phase=s)
    elif id=='marrow_dice':
        a('DieL',(-.71,0,1.49),kind='roll',axis='z',amp=.12,period=3.7);a('DieR',(.89,0,.87),kind='roll',axis='x',amp=.09,period=5.1)
        for i,p in enumerate([(-1.57,-.64,2.42),(-.97,-.77,2.73),(.44,-.61,1.94)]):a('Pip'+str(i),p,kind='drip',axis='y',amp=.09,period=2.9+i*.3,phase=i)
    elif id=='veil_mourner':
        a('Comb',(0,0,3.1),kind='bow',axis='x',amp=.025,period=9)
        for s,b in [(-1,'L'),(1,'R')]:a('Veil'+b,(s*.3,0,2.4),kind='ribbon',axis='z',amp=s*.09,period=5.6,phase=s*.6);a('Hand'+b,(s*.59,-.56,1.4),kind='grip',axis='x',amp=.10,period=7.2,phase=s)
    elif id=='grave_compass':a('Needle',(.36,-.39,1.5),kind='search',axis='z',amp=.70,period=8);a('Lid',(-.76,0,1.55),kind='creak',axis='y',amp=.08,period=7.7);a('Ring',(-.14,0,2.4),kind='pendulum',axis='z',amp=.08,period=3)
    elif id=='hollow_violin':
        l([(-.34,0,.72),(.34,0,.72)],.34,1.65,.16)
        for i,x in enumerate([-.095,0,.095]):a('String'+str(i),(x,-.45,2.14),kind='vibrate',axis='z',amp=.006,period=.19+i*.035)
        a('Scroll',(0,0,3.34),kind='listen',axis='y',amp=.08,period=6.5)
    elif id=='chime_triplets':
        for i,x in enumerate([-1.1,0,1.13]):a('Bell'+str(i),(x,0,2.95),kind='pendulum',axis='z',amp=.13+i*.03,period=2.5+i*.6,phase=i*1.2)
    elif id=='thimble_spider':l([(s*.55,-.43+i*.33,.94)for s in [-1,1]for i in range(4)],.55,.95,.18);a('Fangs',(0,-.45,.74),kind='grip',axis='x',amp=.14,period=5.8)
    elif id=='music_box_dancer':
        a('Dancer',(0,-.13,.84),kind='turn',axis='y',amp=1,period=8);a('Head',(0,-.13,2.89),'Dancer',kind='bow',axis='x',amp=.075,period=7)
        a('ArmL',(-.21,-.13,2.3),'Dancer',kind='reach',axis='z',amp=.16,period=4.5);a('ArmR',(.21,-.13,2.3),'Dancer',kind='reach',axis='z',amp=-.12,period=5.1)
        a('Lid',(0,.65,1),kind='creak',axis='x',amp=.06,period=10)
    elif id=='raven_quill':
        l([(-.16,0,.72),(.16,0,.72)],.35,1.18,.19);a('Nib',(.2,-.25,2.66),kind='write',axis='x',amp=.10,period=5.6)
        for s,b in [(-1,'L'),(1,'R')]:a('Barbs'+b,(s*.22,0,1.3),kind='flutter',axis='z',amp=s*.065,period=3.2,phase=s)
    elif id=='sorrow_chalice':
        a('Spirit',(0,0,1.66),kind='lament',axis='z',amp=.10,period=7.4)
        for i,p in enumerate([(-.83,0,2.1),(.8,0,2.38),(.93,0,1.18)]):a('Drop'+str(i),p,kind='drip',axis='y',amp=.12,period=3.5,phase=i*2)
    elif id=='pale_gramophone':
        l([(s*.82,y,.89)for s in [-1,1]for y in [-.48,.48]],.40,1.85,.16)
        a('Horn',(-.8,.35,1.45),kind='listen',axis='y',amp=.09,period=6.3);a('Record',(-.06,-.02,1.61),kind='turn',axis='y',amp=1,period=3.4);a('Crank',(.35,.78,1.01),kind='turn',axis='z',amp=1,period=3.4)
    elif id=='thorn_reliquary':a('Thorn',(0,.07,.48),kind='struggle',axis='z',amp=.075,period=6.2);a('ThornTip',(.04,.03,1.6),'Thorn',kind='coil',axis='y',amp=.15,period=4.5)
    elif id=='anchor_crab':
        l([(s*.61,-.33+i*.33,.65)for s in [-1,1]for i in range(3)],.34,1.38,.17)
        for s,b in [(-1,'L'),(1,'R')]:a('Claw'+b,(s*.61,-.26,.99),kind='reach',axis='z',amp=s*.11,period=4.2,phase=s);a('Jaw'+b,(s*(1.38 if s<0 else 1.75),-.5,1.16),'Claw'+b,kind='grip',axis='z',amp=s*.12,period=5.8,phase=s)
    elif id=='sundial_sentinel':l([(-.31,.1,1),(.31,.1,1)],.53,2.7,.13);a('Shadow',(-.4,-.37,1.79),kind='search',axis='z',amp=.24,period=15);a('Gnomon',(.02,0,1.58),kind='twitch',axis='y',amp=.035,period=10)
    elif id=='sleepwalker_shoes':
        for i,p in enumerate([(-.7,.15,.35),(.75,-.4,.5)]):a('Boot'+str(i),p,kind='shoe',axis='x',amp=.19,period=1.65,phase=i*math.pi,idle=.12)
    elif id=='night_harp':
        l([(s*.65,y,.7)for s in [-1,1]for y in [-.5,.45]],.4,2.1,.14);a('Head',(.71,-.26,3.54),kind='listen',axis='y',amp=.095,period=6.7)
        for i,x in enumerate([-.83,-.47,-.1,.27]):a('String'+str(i),(x,0,1.9),kind='pluck',axis='z',amp=.012,period=2.4,phase=i*.6)
    elif id=='thorn_cathedral':
        l([(-.74,-.48,.78),(.59,-.48,.78),(-.68,.62,.78),(.68,.62,.78)],.4,2.9,.12)
        a('RoseWindow',(-.18,-.79,1.38),kind='turn',axis='z',amp=1,period=70);a('Belfry',(.64,0,2.44),kind='pendulum',axis='z',amp=.025,period=5.2)
    elif id=='phantom_marionette':
        a('Body',(0,0,2.5),kind='puppet',axis='z',amp=.055,period=4.6);a('Head',(.09,-.04,3.48),'Body',kind='peek',axis='z',amp=.15,period=6.3)
        for b,p,k in [('ArmL',(-.28,0,2.98),(-.79,0,3.24)),('ArmR',(.31,0,2.96),(.77,0,2.7)),('LegL',(-.19,0,2.36),(-.62,0,1.71)),('LegR',(.21,0,2.34),(.47,0,1.85))]:
            a(b,p,'Body',kind='puppet',axis='x',amp=.15,period=3.1,phase=p[0]*2);a(b+'Tip',k,b,kind='puppet',axis='z',amp=.11,period=4.2,phase=p[0]*3)
    elif id=='blood_moon_rose':
        l([(s*.4,y,.45)for s in [-1,1]for y in [-.3,.3]],.25,2.3,.14)
        a('Bloom',(.18,-.02,2.4),kind='listen',axis='y',amp=.08,period=8)
        for i in range(4):a('Petal'+str(i),(.18,-.02,2.68),'Bloom',kind='unfurl',axis='x'if i%2 else 'z',amp=.065,period=9,phase=i*1.3)
        for s,b in [(-1,'L'),(1,'R')]:a('ThornArm'+b,(s*.35,0,1.65),kind='reach',axis='z',amp=s*.09,period=6.1,phase=s)
    elif id=='judgement_scales':
        l([(-.23,0,1.23),(.23,0,1.23)],.56,3.1,.1)
        for s,b in [(-1,'L'),(1,'R')]:a('Balance'+b,(s*.31,0,2.31),kind='weigh',axis='z',amp=s*.08,period=8.5);a('Pan'+b,(s*1.28,0,1.6),'Balance'+b,kind='counterweigh',axis='z',amp=-s*.08,period=8.5)
    elif id=='clockwork_raven':
        l([(-.25,0,1.24),(.25,0,1.24)],.42,1.45,.17);a('Head',(.05,-.42,2.82),kind='ratchet',axis='y',amp=.14,period=6.8)
        for s,b in [(-1,'L'),(1,'R')]:a('Wing'+b,(s*.35,0,2.04),kind='fold',axis='z',amp=s*.11,period=6.5,phase=s)
        a('Minute',(.05,-.5,2.82),'Head',kind='turn',axis='z',amp=1,period=12);a('Hour',(.05,-.5,2.82),'Head',kind='turn',axis='z',amp=1,period=70);a('Wheel',(0,.45,1.91),kind='ratchet',axis='z',amp=.22,period=3.2);a('Tail',(0,.2,1.55),kind='ribbon',axis='x',amp=.055,period=4.3)
    elif id=='eclipse_stag':
        l([(.4,-.3,1.38),(.4,.3,1.38),(-.77,-.3,1.18),(-.77,.3,1.18)],.68,1.7,.17)
        a('Head',(.52,.02,2.55),kind='survey',axis='y',amp=.12,period=9);a('Mane',(0,.2,2.5),kind='ribbon',axis='x',amp=.08,period=4.4);a('Tail',(-.9,0,1.5),kind='wag',axis='y',amp=.14,period=4.3)
    elif id=='endless_library':
        l([(s,y,.5)for s in [-1,1]for y in [-.12,.37]],.25,2.1,.12)
        for i,x in enumerate([-.92,0,.91]):a('Book'+str(i),(x,0,1.39),kind='creak',axis='x',amp=.05,period=7+i,phase=i)
        for b,x in [('PageL',-.05),('PageR',.44)]:a(b,(x,.02,2.75),kind='flutter',axis='z',amp=.14 if b=='PageL'else -.14,period=4.7)
        a('Bookmarks',(0,0,1.4),kind='ribbon',axis='x',amp=.11,period=3.5)
    elif id=='sunken_crown':
        for i in range(6):
            t=i*math.tau/6;p=(.36*math.cos(t),.36*math.sin(t),2.17)
            a('Tendril'+str(i),p,kind='coil',axis='z',amp=.10,period=4.9,phase=i*.9);a('Tip'+str(i),(p[0]*2,p[1]*2,1.1),'Tendril'+str(i),kind='coil',axis='y',amp=.12,period=3.9,phase=i*.9)
    elif id=='silent_choir':
        for i,(x,h)in enumerate([(-.89,2.86),(0,3.51),(.94,3.04)]):
            a('Singer'+str(i),(x,0,1.2),kind='bow',axis='x',amp=.035,period=7.1+i*.6,phase=i*1.9);a('Bell'+str(i),(x,0,h-.2),'Singer'+str(i),kind='pendulum',axis='z',amp=.065,period=4.2+i*.8,phase=i)
    elif id=='cathedral_heart':
        l([(s*.89,y,.9)for s in [-1,1]for y in [-.12,.73]],.45,3.5,.1)
        for s,b in [(-1,'L'),(1,'R')]:a('Heart'+b,(s*.10,0,2),kind='heartbeat',axis='x',amp=s*.025,period=1.6,phase=0)
    elif id=='hollow_throne':
        l([(s*.79,y,.85)for s in [-1,1]for y in [-.25,.68]],.4,3.2,.1);a('Ghost',(0,0,1.4),kind='emerge',axis='z',amp=.06,period=12);a('Mantle',(0,0,2.2),kind='ribbon',axis='z',amp=.035,period=7.5)
    elif id=='worldroot':
        l([(-.94,-.34,1.48),(.94,-.34,1.48),(-.89,.4,1.48),(.89,.4,1.48)],.72,3.8,.11)
        for s,b in [(-1,'L'),(1,'R')]:a('Trunk'+b,(s*.3,0,1.48),kind='bow',axis='z',amp=s*.027,period=11);a('Moss'+b,(s*.75,0,3.34),kind='ribbon',axis='x',amp=.06,period=6.2,phase=s)
        a('Seed',(0,-.02,1.92),kind='turn',axis='y',amp=1,period=35)
    elif id=='the_undertow':
        a('Clapper',(0,.06,1.93),kind='pendulum',axis='x',amp=.16,period=3.6);a('Vortex',(0,0,.9),kind='turn',axis='y',amp=1,period=9)
        for s,b in [(-1,'L'),(1,'R')]:a('Blade'+b,(s*.35,0,2.13),kind='coil',axis='z',amp=s*.07,period=5.2,phase=s)
        a('Hanger',(0,0,2.65),kind='pendulum',axis='z',amp=.035,period=5.3)
    elif id=='the_last_funeral':l([(-1.08,-.79,2.03),(.91,-.79,2.03),(-1.08,.83,2.03),(.91,.83,2.03)],1.26,4.2,.085);a('Lilies',(0,-.3,3.2),kind='bow',axis='x',amp=.03,period=9.2)
    elif id=='nameless_door':
        l([(-.93,0,.6),(.93,0,.6)],.32,3.3,.10);a('Door',(1.01,-.15,.05),kind='creak',axis='y',amp=.12,period=10.7);a('LintelMoss',(0,0,3.5),kind='ribbon',axis='x',amp=.04,period=7.2)
    elif id=='crown_of_silence':
        for i,p in enumerate([(-.43,0,3.51),(.43,0,3.53),(0,0,3.88),(0,0,3.08)]):a('Crown'+str(i),p,kind='hold',axis='z',amp=.07,period=9.1+i,phase=i*1.8)
        for i in range(4):a('Robe'+str(i),(0,0,2.5),kind='ribbon',axis='x',amp=.055,period=8.7,phase=i*1.4)
        for s,b in [(-1,'L'),(1,'R')]:a('Sleeve'+b,(s*.26,0,2.73),kind='reach',axis='z',amp=s*.06,period=10,phase=s)
    elif id=='the_first_grave':
        l([(-.47,.21,1.44),(.47,.21,1.44)],.75,3.2,.14)
        for s,b in [(-1,'L'),(1,'R')]:a('Arm'+b,(s*.57,0,2.56),kind='reach',axis='x',amp=.09,period=7,phase=s);a('Fingers'+b,(s*1.14,0,1.3),'Arm'+b,kind='grip',axis='z',amp=s*.08,period=8.4);a('Moss'+b,(s*.8,0,2.6),kind='ribbon',axis='x',amp=.045,period=6.5,phase=s)
    elif id=='the_unwritten':
        a('Head',(0,0,3.5),kind='twitch',axis='z',amp=.085,period=8.1)
        for i in range(4):a('PageTail'+str(i),(0,0,2.5),kind='ribbon',axis='z',amp=.075,period=5.3,phase=i*1.3)
        for s,b in [(-1,'L'),(1,'R')]:a('Sleeve'+b,(s*.35,0,2.8),kind='fold',axis='z',amp=s*.065,period=6.1,phase=s);a('WritingHand'+b,(s*.81,0,2.46),'Sleeve'+b,kind='write',axis='x',amp=.12,period=3.8,phase=s)
    elif id=='the_last_star':
        l([(-1.15,-.55,1.43),(1.15,-.55,1.43),(-.92,.63,1.43),(.92,.63,1.43)],1.04,3.2,.13)
        a('Star',(0,-.14,2.61),kind='turn',axis='z',amp=1,period=32);a('Helm',(0,0,3.72),kind='survey',axis='y',amp=.085,period=11)
        for s,b in [(-1,'L'),(1,'R')]:a('Arm'+b,(s*1.38,0,2.94),kind='reach',axis='z',amp=s*.055,period=8.5);a('Talons'+b,(s*1.69,0,1.7),'Arm'+b,kind='grip',axis='x',amp=.10,period=6.4,phase=s)
    else:raise ValueError('Missing authored plan: '+id)
    return q

def weights(q,part,c,v):
    id=q.id;x,y,z=c;s='L' if x<0 else 'R'
    def one(b):return {b:1.0}
    def bend(a,b,at,width=.22):
        t=max(0,min(1,(at+width-v.z)/(2*width)));return {a:1-t,b:t}
    def leg():
        i=min(range(len(q.legs)),key=lambda i:(c-Vector(q.legs[i])).length)
        return bend('Leg'+str(i),'Knee'+str(i),q.bones['Knee'+str(i)][0][2])
    def quad(prefix):return prefix+str(int((math.atan2(y,x)+math.pi)/(math.tau/4))%4)
    if id=='haunted_mirror':
        if part==1 and abs(x)<.65 and z<3.9 and z>1.8:return one('GhostHead'if z>3.15 else 'Reflection')
        if z<1.05 and abs(x)>.55:return leg()
    elif id=='crying_mask':
        if z<2.7 and abs(x)<.9 and y<-.35:return one('Tear'+s)
        if part==1 and abs(x)>.9:return one('Tie'+s)
        return one('Sorrow')
    elif id=='candle_wisp':
        if part==4:return one('Flame')
        if part==2:return one('Hand'+s)
    elif id=='grave_hopper':
        if part==1:return leg()
        return one('Shell')
    elif id=='grave_key':
        if part==1:return leg()
        if part==2:return one('Scarf')
    elif id=='mourning_ribbon':return one(('Tail'if part==2 else 'Loop')+s)
    elif id=='wilted_sprout':
        if part==2:return one('Leaf')
        if part==1:return one('Bloom')
        return bend('Root','Stem',.6,.25)
    elif id=='ink_imp':
        if part==1:
            if y>.15 and x<-.45 and z>1.8:return one('Tail')
            if abs(x)>.61 and z<1.65:return one('Hand'+s)
            return one('Ink')
    elif id=='lost_locket':
        if part==2 or (part==0 and x<-.23):return one('Cover')
        if part==1:
            if z>1.57:return one(q.nearest(c,['Finger'+str(i)for i in range(4)]))
            return one('Palm')
    elif id=='ashen_book':
        if part==1:return one('PageWing')
        if z<.38 and abs(x)>.4:return leg()
        if z>1 and part==0:return one('Cover')
    elif id=='lantern_lurker':
        if part==1:
            if z<.87:return leg()
            if z>2.1:return one('Handle')
        if part==0 and abs(x)<.25 and abs(y)<.25 and .9<z<1.6:return one('Captive')
    elif id=='hourglass_hound':
        if part==1:
            if z<.88:return leg()
            if x<-.6 and z>.87:return one('Head')
            if x>1 and z>1:return one('Tail')
    elif id=='nail_beetle':
        if part==1:return leg()
        if y>.75 and z>.8:return one('Nail')
    elif id=='pale_guest':
        if part==1:
            if z<.8 and abs(x)>.2:return one('Grip'+s)
            return one('Head'if z>1.6 else 'Ghost')
    elif id=='cold_teacup':
        if part==1:return bend('Steam','SteamTip',2.04,.25)
    elif id=='coin_crawler':
        if part==2:
            if abs(x)>.56:return leg()
            if y<-.60:return one('Gaze')
        if part in [0,1]:return one('CoinLid')
    elif id=='umbrella_wraith':
        if part==1:return bend('Wing'+s,'Rag'+s,1.4,.25)
    elif id=='marrow_dice':
        if part==1 and z>1.7:return one(q.nearest(c,['Pip'+str(i)for i in range(3)]))
        return one('Die'+s)
    elif id=='veil_mourner':
        if part==2:return one('Comb')
        if part==1 and z>1.05 and abs(x)>.4:return one('Hand'+s)
        return bend('Root','Veil'+s,2.1,.6)
    elif id=='grave_compass':
        if part==1:
            if x<-.75:return one('Lid')
            if z>2.2:return one('Ring')
            return one('Needle')
    elif id=='hollow_violin':
        if z<.72 and part==2:return leg()
        if part==1 and z>3.3:return one('Scroll')
        if part==2 and z>1.5 and abs(x)<.17:
            b=q.nearest(c,['String'+str(i)for i in range(3)]);return bend('Root',b,3.2,.2)if v.z>2.3 else bend(b,'Root',1.05,.2)
    elif id=='chime_triplets':
        if part==1:
            b=q.nearest(c,['Bell'+str(i)for i in range(3)]);return bend('Root',b,2.7,.2)
    elif id=='thimble_spider':
        if part==2:return leg()
        if part==1 and abs(x)<.35 and y<-.4 and z<.8:return one('Fangs')
    elif id=='music_box_dancer':
        if part==1:return one('Lid')
        if part==2:
            if z>2.75:return one('Head')
            if abs(x)>.2 and z>1.85:return one('Arm'+s)
            return one('Dancer')
    elif id=='raven_quill':
        if part==2:return leg()
        if part==1:return one('Nib')
        return one('Barbs'+s)
    elif id=='sorrow_chalice':
        if part==1:
            if abs(x)>.7:return one(q.nearest(c,['Drop'+str(i)for i in range(3)]))
            return one('Spirit')
    elif id=='pale_gramophone':
        if part==2:return leg()
        if part==1:return one('Record')
        if part==3:return one('Horn')
        if part==4 and y>.7:return one('Crank')
    elif id=='thorn_reliquary':
        if part==2:return bend('Thorn','ThornTip',1.6,.32)
    elif id=='anchor_crab':
        if part==1:return leg()
        if part==2:return one(('Jaw'if abs(x)>1.25 and z>1.14 else 'Claw')+s)
    elif id=='sundial_sentinel':
        if part==2:return leg()
        if part==1:return one('Shadow'if y<-.25 else 'Gnomon')
    elif id=='sleepwalker_shoes':return one('Boot'+('0'if x<0 else '1'))
    elif id=='night_harp':
        if part==0 and z<.66:return leg()
        if part==2:return one('Head')
        if part==1 and abs(x)<.92 and z<3.2 and y<.25:
            b=q.nearest(c,['String'+str(i)for i in range(4)]);t=max(0,1-abs(v.z-1.9)/1.2);return {'Root':1-t,b:t}
    elif id=='thorn_cathedral':
        if part==0 and z<.76:return leg()
        if part==1 and y<-.6:return one('RoseWindow')
        if part==2 and x>.35 and z>2.45:return one('Belfry')
    elif id=='phantom_marionette':
        if part==1:
            if z>4.2:return one('Root')
            b=q.nearest(c,['Head','ArmLTip','ArmRTip','LegLTip','LegRTip'])
            # Upper string ends stay on the crossbar; lower ends follow limbs.
            t=max(0,min(1,(4.35-v.z)/(4.35-q.bones[b][0][2])));return {'Root':1-t,b:t}
        if z>3.1 and abs(x)<.7:return one('Head')
        if abs(x)>.6 and z>2.45:return one('Arm'+s+'Tip')
        if z<2.4:return one('Leg'+s+'Tip')
        return one('Body')
    elif id=='blood_moon_rose':
        if part==0 and z<.5:return leg()
        if part==1:return one('Petal'+str(int((math.atan2(z-2.68,x-.18)+math.pi)/(math.tau/4))%4))
        if part==2:return one('ThornArm'+s)
    elif id=='judgement_scales':
        if part==0 and z<1:return leg()
        if part==1:return bend('Balance'+s,'Pan'+s,2.1,.3)
    elif id=='clockwork_raven':
        if part==1:return one('Wing'+s)
        if part==2:return one('Wheel'if z>1.5 and y>.3 else 'Tail')
        if part==0:
            if z<1.12:return leg()
            if z>2.5:
                if y<-.46 and abs(x-.05)<.4 and z<3.15:return one('Minute'if z>2.83 else 'Hour')
                return one('Head')
    elif id=='eclipse_stag':
        if part==0 and z<1.15:return leg()
        if part==1 or (part==0 and x>.38 and z>1.75):return one('Head')
        if part==2:return one('Tail'if x<-.8 else 'Mane')
    elif id=='endless_library':
        if part==0:return one(q.nearest(c,['Book'+str(i)for i in range(3)]))
        if part==1:return leg()if z<.65 else one('Bookmarks')
        if part==2 and z>2.35:return one('PageL'if x<.2 else 'PageR')
    elif id=='sunken_crown':
        if part==1:
            i=int((math.atan2(y,x)%math.tau)/(math.tau/6)+.5)%6;return bend('Tendril'+str(i),'Tip'+str(i),1.1,.35)
    elif id=='silent_choir':
        i=min(range(3),key=lambda i:abs(x-[-.89,0,.94][i]))
        return one(('Bell'if part in [1,2,3]else 'Singer')+str(i))if part!=4 else one('Root')
    elif id=='cathedral_heart':
        if part==0:return one('Heart'+s)
        if part==1 and z<.83:return leg()
    elif id=='hollow_throne':
        if part==0 and z<.82:return leg()
        if part==1:return one('Ghost'if abs(x)<.45 else 'Mantle')
    elif id=='worldroot':
        if part==0:return leg()
        if part==1:return one('Seed'if abs(x)<.28 and 1.55<z<2.2 else 'Trunk'+s)
        if part==2 and z<3.4:return one('Moss'+s)
    elif id=='the_undertow':
        if part==0 and abs(x)<.2 and z<1.6:return one('Clapper')
        if part==1:return one('Blade'+s)
        if part==2:return one('Vortex')
        if part==3:return one('Hanger')
    elif id=='the_last_funeral':
        if part==1 and z<2.12:return leg()
        if part==0 and z>3.2:return one('Lilies')
    elif id=='nameless_door':
        if part==1:return one('Door')
        if part==2:return leg()if z<.64 else one('LintelMoss')
    elif id=='crown_of_silence':
        if part==0 and z>2.96:return one(q.nearest(c,['Crown'+str(i)for i in range(4)]))
        if part==1:return bend('Root',quad('Robe'),2.2,.6)
        if part==2:return one('Sleeve'+s)
    elif id=='the_first_grave':
        if part==0 and z<1.42:return leg()
        if part==1:return one(('Fingers'if z<1.5 else 'Arm')+s)
        if part==2:return one('Moss'+s)
    elif id=='the_unwritten':
        if part==0 or part==3:return bend('Root',quad('PageTail'),2.1,.65)
        if part==1:return one('Head')
        if part==2:return one(('WritingHand'if z<2.3 else 'Sleeve')+s)
    elif id=='the_last_star':
        if part==0:return leg()
        if part==2:return one('Star')
        if part==3:return one('Helm')
        if part==1 and abs(x)>1.37:return one(('Talons'if z<1.9 else 'Arm')+s)
    return one('Root')

def rig(row):
    id=row['id'];q=plan_for(id);proto=original.geo.Sculpt();author(id)(proto)
    rawlo=Vector([min(v[i]for v in proto.vertices)for i in range(3)])
    rawhi=Vector([max(v[i]for v in proto.vertices)for i in range(3)]);rawcenter=(rawlo+rawhi)/2
    target=Vector((float(row['after_W']),float(row['after_D']),float(row['after_H'])))
    factors=Vector([target[i]/(rawhi[i]-rawlo[i])for i in range(3)])
    def point(p):return Vector([(p[i]-rawcenter[i])*factors[i]for i in range(3)])
    def raw(p):return Vector([p[i]/factors[i]+rawcenter[i]for i in range(3)])
    tree=BVHTree.FromPolygons([Vector(v)for v in proto.vertices],proto.faces)
    faceparts=[0]*len(proto.faces)
    for i,part in enumerate(proto.parts):
        end=proto.parts[i+1]['first_face']if i+1<len(proto.parts)else len(proto.faces)
        for f in range(part['first_face'],end):faceparts[f]=i
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/row['actualBlend']))
    obj=bpy.data.objects[id];mesh=obj.data
    lo=Vector([min(v.co[i]for v in mesh.vertices)for i in range(3)])
    hi=Vector([max(v.co[i]for v in mesh.vertices)for i in range(3)])
    for v in mesh.vertices:v.co=Vector([(v.co[i]-(lo[i]+hi[i])/2)*target[i]/(hi[i]-lo[i])for i in range(3)])
    mesh.update();assigned={};semanticCounts=Counter();used=Counter()
    for ids in components(mesh):
        rawpoints=[raw(mesh.vertices[i].co)for i in ids];c=sum(rawpoints,Vector())/len(ids)
        probes=[rawpoints[i]for i in range(0,len(ids),max(1,len(ids)//12))]
        votes=[faceparts[tree.find_nearest(v)[2]]for v in probes];part=Counter(votes).most_common(1)[0][0]
        semanticCounts[part]+=1
        for index,v in zip(ids,rawpoints):
            w=weights(q,part,c,v);assert all(n in q.bones for n in w)
            assigned[index]={n:t for n,t in w.items()if t>1e-6}
            for n,t in assigned[index].items():used[n]+=1
    # Retain every weighted joint plus its ancestors; omit unused decorative
    # pivots instead of pretending those channels have articulated geometry.
    keep=set(used)
    for n in list(keep):
        parent=q.bones[n][1]
        while parent:keep.add(parent);parent=q.bones[parent][1]
    q.bones={n:b for n,b in q.bones.items()if n in keep}
    q.channels=[ch for ch in q.channels if ch['bone']in keep]
    assert len(q.channels)>=2,f'{id}: insufficient actual articulated anatomy'
    obj.vertex_groups.clear()
    for n in q.bones:obj.vertex_groups.new(name=n)
    for i,w in assigned.items():
        assert abs(sum(w.values())-1)<1e-5
        for n,t in w.items():obj.vertex_groups[n].add([i],t,'REPLACE')
    data=bpy.data.armatures.new(id+'_Rig');arm=bpy.data.objects.new(id+'_Rig',data);bpy.context.collection.objects.link(arm)
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
    for n,(p,parent)in q.bones.items():
        b=data.edit_bones.new(n);b.head=Vector()if n=='Root'else point(p);b.tail=b.head+Vector((0,0,max(.1,target.z*.025)));b.use_deform=True
        if parent:b.parent=data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');mod=obj.modifiers.new('Authored concept articulation','ARMATURE');mod.object=arm;obj.parent=arm
    bpy.context.preferences.filepaths.save_version=0;source=HERE/(id+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);obj.select_set(True);bpy.context.view_layer.objects.active=obj
    fbx=EXPORT/(id+'.fbx');EXPORT.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=.01,apply_unit_scale=True,bake_space_transform=False,
        object_types={'MESH','ARMATURE'},add_leaf_bones=False,armature_nodetype='NULL',use_armature_deform_only=True,bake_anim=False,use_mesh_modifiers=True,colors_type='SRGB')
    return dict(id=id,sourceReused=row['actualBlend'],sourceReusedSHA256=hashlib.sha256((ROOT/row['actualBlend']).read_bytes()).hexdigest(),
        blend=source.relative_to(ROOT).as_posix(),fbx=fbx.relative_to(ROOT).as_posix(),fbxSHA256=hashlib.sha256(fbx.read_bytes()).hexdigest(),
        vertices=len(mesh.vertices),triangles=len(mesh.polygons),bones=list(q.bones),weightedVertices=len(mesh.vertices),
        weightedCounts=dict(used),semanticComponents=dict(semanticCounts),channels=q.channels,targetSize=[target.x,target.z,target.y],realImportRecorded=False,playReviewed=False)

def luau(value):
    if isinstance(value,str):return json.dumps(value)
    if isinstance(value,(float,int)):return str(value)
    if isinstance(value,list):return '{'+','.join(luau(x)for x in value)+'}'
    if isinstance(value,dict):return '{'+','.join('['+luau(k)+']='+luau(v)for k,v in value.items())+'}'
    raise TypeError(value)
def main():
    requested=set(sys.argv[sys.argv.index('--')+1:])if '--'in sys.argv else None
    skip={'cursed_doll','watching_eye','soul_chains','plague_monarch','the_void'}
    path=HERE/'remaining-rigs.json';rows=json.loads(path.read_text(encoding='utf8'))if path.exists()else [];merged={r['id']:r for r in rows}
    for row in sources():
        if row['id']in skip or (requested is not None and row['id']not in requested):continue
        r=rig(row);merged[r['id']]=r
        path.write_text(json.dumps(list(merged.values()),indent=2),encoding='utf8')
        print('RIG_EXPORTED',r['id'],len(r['bones']),r['weightedCounts'],flush=True)
    (ROOT/'src/shared/CurseAnimationProfiles.luau').write_text('-- Authored acting channels for actual skinned volumes.\nreturn '+luau({id:r['channels']for id,r in merged.items()})+'\n',encoding='utf8')
if __name__=='__main__':main()
