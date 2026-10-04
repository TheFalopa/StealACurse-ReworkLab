-- Stable gameplay IDs. Server services validate every value; `role` and
-- `blurb` are presentation text for the tool bar and the Gravekeeper's Bench.
local C={MaxEquipped=3,MaxCharges=999,RequestInterval=.12,OnlineTheftEnabled=false,RealPurchasesEnabled=false}
C.Items={
 shovel={name='Gravekeeper Shovel',role='MELEE',blurb='Wind up and knock a thief flat for a second.',price=0,level=0,cooldown=2.2,windup=.32,range=7,ragdoll=1,kind='permanent'},
 ash_boots={name='Ash Boots',role='ESCAPE',blurb='A burst of speed. Weaker while carrying.',price=450,level=0,cooldown=12,windup=.12,duration=3,kind='permanent'},
 impact_urn={name='Impact Urn',role='THROW',blurb='Lob a funeral urn that blasts players back.',price=120,level=0,cooldown=3,windup=.3,range=38,radius=9,kind='consumable',pack=3},
 mist_censer={name='Mist Censer',role='TRICK',blurb='A grave mist: chains cannot find you inside.',price=850,level=1,cooldown=18,windup=.25,duration=6,radius=12,kind='permanent'},
 exorcist_lantern={name='Exorcist Lantern',role='UTILITY',blurb='Reveal traps, mist and decoys around you.',price=650,level=1,cooldown=8,windup=.2,range=30,kind='permanent'},
 consecrated_salt={name='Consecrated Salt',role='DEFENSE',blurb='Pour a line that slows anyone crossing it.',price=100,level=0,cooldown=3,windup=.2,duration=8,kind='consumable',pack=3},
 root_trap={name='Root Trap',role='DEFENSE',blurb='Hidden roots grab the next intruder.',price=1100,level=2,cooldown=10,windup=.3,duration=18,kind='permanent'},
 break_talisman={name='Break Talisman',role='WARD',blurb='Shake off slows and roots, then resist briefly.',price=150,level=0,cooldown=5,windup=.1,kind='consumable',pack=3},
 jailer_chain={name='Jailer Chain',role='PULL',blurb='Hook a fleeing thief and yank them back.',price=4200,level=3,cooldown=10,windup=.42,range=28,kind='permanent'},
 double_mirror={name='Double Mirror',role='TRICK',blurb='Leave a ghostly double to fool pursuers.',price=3800,level=3,cooldown=16,windup=.25,duration=8,kind='permanent'},
}
C.Order={'shovel','ash_boots','impact_urn','mist_censer','exorcist_lantern','consecrated_salt','root_trap','break_talisman','jailer_chain','double_mirror'}
C.Offers={
 chain_pass={kind='pass',item='jailer_chain',id=0,enabled=false},
 mirror_pass={kind='pass',item='double_mirror',id=0,enabled=false},
 urn_bundle={kind='product',item='impact_urn',amount=10,id=0,enabled=false},
 salt_bundle={kind='product',item='consecrated_salt',amount=10,id=0,enabled=false},
 talisman_bundle={kind='product',item='break_talisman',amount=10,id=0,enabled=false},
}
return C
