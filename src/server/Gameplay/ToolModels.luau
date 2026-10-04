-- Reproducible local geometry: no uploaded asset dependency. Each object has its
-- own silhouette; stable hooks can be used by the future VFX branch.
local Models={}
local iron=Color3.fromRGB(42,48,53);local bone=Color3.fromRGB(217,204,165)
local wood=Color3.fromRGB(71,43,31);local brass=Color3.fromRGB(170,124,57)
function Models.create(id)
 local tool=Instance.new('Tool');tool.Name=id;tool.CanBeDropped=false;tool.RequiresHandle=true
 tool:SetAttribute('ToolId',id);tool.Grip=CFrame.new(0,-.3,0)
 local handle=Instance.new('Part');handle.Name='Handle';handle.Size=Vector3.new(.25,1.25,.25);handle.Color=wood;handle.Material=Enum.Material.Wood
 handle.CanCollide=false;handle.CanTouch=false;handle.CanQuery=false;handle.Massless=true;handle.Parent=tool
 local function p(name,size,frame,color,material,shape)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=handle.CFrame*frame;v.Color=color;v.Material=material or Enum.Material.Metal
  v.Shape=shape or Enum.PartType.Block;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Massless=true;v.Parent=tool
  local w=Instance.new('WeldConstraint');w.Part0=handle;w.Part1=v;w.Parent=v;return v
 end
 local function beam(name,a,b,width,color)
  return p(name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)*.5,b),color)
 end
 local function ring(name,y,r,color)
  for i=1,8 do local a=i*math.pi/4;local b=a+math.pi/4
   beam(name..i,Vector3.new(math.cos(a)*r,y,math.sin(a)*r),Vector3.new(math.cos(b)*r,y,math.sin(b)*r),.12,color)
  end
 end
 if id=='shovel'then
  p('Shaft',Vector3.new(.17,3,.17),CFrame.new(0,0,0),wood,Enum.Material.Wood)
  p('Socket',Vector3.new(.3,.48,.3),CFrame.new(0,-1.25,0),iron)
  p('Blade',Vector3.new(.95,1.05,.12),CFrame.new(0,-1.98,0)*CFrame.Angles(.12,0,0),Color3.fromRGB(127,136,142))
  p('BladeEdge',Vector3.new(.7,.16,.16),CFrame.new(0,-2.5,.07),bone)
  beam('GripLeft',Vector3.new(-.35,1.4,0),Vector3.new(-.35,1.9,0),.13,iron)
  beam('GripRight',Vector3.new(.35,1.4,0),Vector3.new(.35,1.9,0),.13,iron)
  p('CrossGrip',Vector3.new(.8,.15,.22),CFrame.new(0,1.9,0),wood,Enum.Material.Wood)
 elseif id=='ash_boots'then
  for side=-1,1,2 do
   p('BootFoot'..side,Vector3.new(.55,.4,1),CFrame.new(side*.4,-.25,-.2),iron,Enum.Material.Fabric)
   p('BootCuff'..side,Vector3.new(.5,.7,.5),CFrame.new(side*.4,.18,0),wood,Enum.Material.Wood)
   p('AshSeal'..side,Vector3.new(.3,.25,.04),CFrame.new(side*.4,.25,-.27),bone)
   p('Sole'..side,Vector3.new(.6,.12,1.04),CFrame.new(side*.4,-.51,-.2),Color3.fromRGB(92,91,87))
  end
 elseif id=='impact_urn' or id=='mist_censer'then
  local urn=id=='impact_urn';local color=if urn then Color3.fromRGB(125,68,45)else brass
  p('Vessel',Vector3.new(1.2,1.4,1.2),CFrame.new(0,.3,0),color,if urn then Enum.Material.Slate else Enum.Material.Metal,Enum.PartType.Ball)
  ring('Collar',.9,.45,bone);p('Lid',Vector3.new(.75,.15,.75),CFrame.new(0,1.05,0),iron)
  p('Knob',Vector3.new(.22,.22,.22),CFrame.new(0,1.2,0),brass,Enum.Material.Metal,Enum.PartType.Ball)
  p('Foot',Vector3.new(.65,.18,.65),CFrame.new(0,-.4,0),iron)
  if urn then
   for side=-1,1,2 do beam('Handle'..side,Vector3.new(side*.75,.8,0),Vector3.new(side*.75,.3,0),.16,brass)end
   p('FuneralMark',Vector3.new(.32,.5,.06),CFrame.new(0,.3,-.58),bone)
  else
   for side=-1,1,2 do for i=1,5 do
    p('Chain'..side..'_'..i,Vector3.new(.14,.23,.1),CFrame.new(side*.45,.9+i*.22,0)*CFrame.Angles(0,i%2*math.pi/2,0),iron)
   end end
   p('Ember',Vector3.new(.5,.15,.5),CFrame.new(0,.99,0),Color3.fromRGB(223,125,51),Enum.Material.Neon)
  end
 elseif id=='exorcist_lantern'then
  p('Glass',Vector3.new(.7,1.05,.7),CFrame.new(0,.3,0),Color3.fromRGB(116,188,173),Enum.Material.Glass).Transparency=.32
  for x=-1,1,2 do for z=-1,1,2 do p('Post'..x..z,Vector3.new(.12,1.3,.12),CFrame.new(x*.44,.3,z*.44),iron)end end
  p('Foot',Vector3.new(1,.16,1),CFrame.new(0,-.4,0),iron)
  p('Roof',Vector3.new(1,.22,1),CFrame.new(0,1,0),brass)
  p('Flame',Vector3.new(.22,.55,.22),CFrame.new(0,.3,0),bone,Enum.Material.Neon)
  ring('Loop',1.17,.25,iron)
 elseif id=='consecrated_salt'then
  p('Bag',Vector3.new(.9,1.1,.65),CFrame.new(0,.2,0),Color3.fromRGB(179,165,130),Enum.Material.Fabric)
  p('Fold',Vector3.new(.7,.22,.55),CFrame.new(0,.85,0)*CFrame.Angles(0,0,.1),wood,Enum.Material.Fabric)
  p('Ribbon',Vector3.new(.94,.13,.69),CFrame.new(0,.68,0),iron)
  p('RitualCross',Vector3.new(.13,.44,.05),CFrame.new(0,.25,-.35),bone)
  p('CrossArm',Vector3.new(.38,.12,.05),CFrame.new(0,.33,-.36),bone)
 elseif id=='root_trap'then
  ring('TrapRim',0,.65,wood)
  for i=1,6 do local a=i*math.pi/3;local foot=Vector3.new(math.cos(a)*.7,0,math.sin(a)*.7)
   beam('RootBase'..i,foot,foot*.55+Vector3.new(0,.5,0),.15,wood)
   beam('Tooth'..i,foot*.55+Vector3.new(0,.5,0),Vector3.new(0,.75,0),.1,bone)
  end
  p('SealPlate',Vector3.new(.45,.08,.45),CFrame.new(0,.08,0),brass)
 elseif id=='break_talisman'then
  ring('MedallionRim',.2,.5,brass)
  p('Seal',Vector3.new(.65,.13,.65),CFrame.new(0,.2,0)*CFrame.Angles(0,math.pi/4,0),bone)
  p('InkMark',Vector3.new(.12,.025,.45),CFrame.new(0,.285,0),iron)
  beam('Cord',Vector3.new(-.35,.2,0),Vector3.new(0,1.25,0),.06,wood)
 elseif id=='jailer_chain'then
  for i=1,9 do
   local center=Vector3.new(math.sin(i*.45)*.08,i*.26,0)
   for j=1,8 do
    local function vertex(k)local a=k*math.pi/4;local side=math.cos(a)*.17
     return center+Vector3.new(if i%2==0 then side else 0,math.sin(a)*.24,if i%2==0 then 0 else side)
    end
    beam('Link'..i..'_'..j,vertex(j),vertex(j+1),.065,iron)
   end
  end
  beam('ShackleLeft',Vector3.new(-.3,2.5,0),Vector3.new(-.3,2.95,0),.13,brass)
  beam('ShackleRight',Vector3.new(.3,2.5,0),Vector3.new(.3,2.95,0),.13,brass)
  beam('ShackleCrown',Vector3.new(-.3,2.95,0),Vector3.new(.3,2.95,0),.13,brass)
  p('Lock',Vector3.new(.72,.26,.3),CFrame.new(0,2.5,0),iron)
 elseif id=='double_mirror'then
  p('MirrorFace',Vector3.new(1.05,1.65,.07),CFrame.new(0,.7,-.04),Color3.fromRGB(132,181,191),Enum.Material.Glass).Reflectance=.35
  for side=-1,1,2 do p('Frame'..side,Vector3.new(.18,1.95,.15),CFrame.new(side*.61,.7,0),brass)end
  p('Crown',Vector3.new(1.4,.18,.15),CFrame.new(0,1.65,0),iron)
  p('Sill',Vector3.new(1.4,.18,.15),CFrame.new(0,-.25,0),iron)
  p('Crest',Vector3.new(.35,.38,.2),CFrame.new(0,1.9,0)*CFrame.Angles(0,0,math.pi/4),bone)
 end
 for _,name in {'UseHook','ImpactHook','VFXHook'}do local a=Instance.new('Attachment');a.Name=name;a.Parent=handle end
 return tool
end
function Models.footwear(character)
 local folder=Instance.new('Folder');folder.Name='AshFootTalismans';folder.Parent=character
 for _,side in {'Left','Right'}do
  local foot=character:FindFirstChild(side..'Foot')or character:FindFirstChild(side..' Leg')
  if foot then
   for _,item in {{'Cuff',Vector3.new(foot.Size.X+.08,.24,foot.Size.Z+.08),CFrame.new(0,-foot.Size.Y*.2,0),wood},{'Seal',Vector3.new(.36,.42,.08),CFrame.new(0,-foot.Size.Y*.2,-foot.Size.Z*.5-.07),bone}}do
    local part=Instance.new('Part');part.Name=side..item[1];part.Size=item[2];part.CFrame=foot.CFrame*item[3];part.Color=item[4];part.Material=Enum.Material.Fabric;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true;part.Parent=folder
    local weld=Instance.new('WeldConstraint');weld.Part0=foot;weld.Part1=part;weld.Parent=part
   end
  end
 end
 return folder
end
return Models
