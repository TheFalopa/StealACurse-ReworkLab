-- Architecture has no ownership/economy authority. Stable markers survive every
-- decorative rebuild; gameplay alone places, moves or sells a Curse.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)
local SanctuaryConfig = require(ReplicatedStorage.Shared.SanctuaryConfig)
local P = require(script.Parent.Primitives)
local AssetKit = require(script.Parent.AssetKit)
local Architecture = {}
local FLOOR_TOP, COURT_TOP, PLINTH_TOP, FLOOR_RISE = 0.8, 1.15, 3.4, 22
local ROWS = { -15, 3, 21, 39, 57 }
local WIDTH, DEPTH, CENTER_Z = 104, 104, 16
local PALETTES = {
	CRYPT = { stone=Color3.fromRGB(179,174,158), trim=Color3.fromRGB(221,207,176), floor=Color3.fromRGB(124,124,133),
		dark=Color3.fromRGB(54,57,66), window=Color3.fromRGB(186,181,156), glow=Color3.fromRGB(255,200,119), material=Enum.Material.Slate },
	FOREST = { stone=Color3.fromRGB(102,75,49), trim=Color3.fromRGB(156,123,77), floor=Color3.fromRGB(85,77,62),
		dark=Color3.fromRGB(48,60,46), window=Color3.fromRGB(108,153,106), glow=Color3.fromRGB(172,223,127), material=Enum.Material.Wood },
	OBSERVATORY = { stone=Color3.fromRGB(53,64,90), trim=Color3.fromRGB(138,158,193), floor=Color3.fromRGB(71,82,109),
		dark=Color3.fromRGB(27,33,51), window=Color3.fromRGB(88,153,192), glow=Color3.fromRGB(116,210,244), material=Enum.Material.Slate },
}
Architecture.Footprint = table.freeze({ width=WIDTH, depth=DEPTH, centerZ=CENTER_Z, minX=-52, maxX=52,
	minZ=-36, maxZ=68, floorRise=FLOOR_RISE, entranceZ=-34, entranceWidth=24, rampWidth=18 })

local function part(parent, frame, name, size, position, color, material, options)
	local item = P.part(parent,name,size,frame*CFrame.new(position),color,material or Enum.Material.Slate,options)
	item:SetAttribute("RestorationArchitecture",true)
	return item
end
local function soft(parent,frame,name,size,position,color,material)
	return part(parent,frame,name,size,position,color,material,{canCollide=false,canQuery=false,castShadow=false})
end
local function softBeam(parent,frame,name,from,to,width,color,material)
	local item=P.beam(parent,name,frame:PointToWorldSpace(from),frame:PointToWorldSpace(to),width,color,material,
		{canCollide=false,canQuery=false,castShadow=false})
	item:SetAttribute("RestorationArchitecture",true)
	return item
end
local function reliefDisk(parent,frame,name,position,diameter,depth,color,material)
	local item=part(parent,frame,name,Vector3.new(depth,diameter,diameter),position,color,material,
		{shape=Enum.PartType.Cylinder,canCollide=false,canQuery=false,castShadow=false})
	item.CFrame*=CFrame.Angles(0,math.pi/2,0)
	return item
end
local function reliefOval(parent,frame,name,position,size,color,angle)
	local item=part(parent,frame,name,size,position,color,Enum.Material.SmoothPlastic,
		{shape=Enum.PartType.Ball,canCollide=false,canQuery=false,castShadow=false})
	if angle then item.CFrame*=CFrame.Angles(0,0,angle) end
	return item
end
local function frameFor(base)
	-- Build translates the map after initial construction. A real marker is the
	-- frame authority, rather than an attribute cached before that translation.
	local spawn=base:FindFirstChild("PlayerSpawn")
	assert(spawn and spawn:IsA("SpawnLocation"),"Sanctuary has no stable spawn")
	return spawn.CFrame*CFrame.new(0,-1.4,18)
end
function Architecture.getFrame(base) return frameFor(base) end
local function capacity(level) return SanctuaryConfig.Levels[level].capacity end
local function floorCapacity(level,floor)
	local total=capacity(level)
	if floor==1 then return math.min(total,10) end
	if floor==2 then return if level==10 then 10 else math.clamp(total-10,0,8) end
	return if level==10 then 10 else math.max(total-18,0)
end
local function pedestalPosition(floor,slot)
	return Vector3.new(slot%2==1 and -23 or 23,
		PLINTH_TOP+(floor-1)*FLOOR_RISE-(PLINTH_TOP-COURT_TOP)/2,ROWS[math.ceil(slot/2)])
end

local function persistentMarkers(base,frame)
	local spawn=part(base,frame,"PlayerSpawn",Vector3.new(6,1,6),Vector3.new(0,1.4,-18),PALETTES.CRYPT.glow,Enum.Material.SmoothPlastic,
		{className="SpawnLocation",transparency=1,canCollide=false,canQuery=false,castShadow=false})
	spawn.Neutral,spawn.Enabled,spawn.Duration=true,true,0
	spawn:SetAttribute("Purpose","UnclaimedBaseSpawn")
	local foundation=part(base,frame,"SanctuaryFloor",Vector3.new(WIDTH,FLOOR_TOP,DEPTH),Vector3.new(0,FLOOR_TOP/2,CENTER_Z),PALETTES.CRYPT.dark,Enum.Material.Slate)
	foundation:SetAttribute("SupportSurface",true)
	local area=part(base,frame,"FutureCurseDisplayArea",Vector3.new(66,0.2,98),Vector3.new(0,COURT_TOP+0.1,17),PALETTES.CRYPT.glow,Enum.Material.SmoothPlastic,
		{transparency=1,canCollide=false,canQuery=false,castShadow=false})
	area:SetAttribute("Purpose","FutureDisplaySlots")
	for floor=1,3 do
		for slot=1,10 do
			local name=if floor==1 and slot<=5 then "DisplayPlinth_"..slot else string.format("DisplayPlinth_floor%d_slot%d",floor,slot)
			local marker=part(base,frame,name,Vector3.new(5.6,PLINTH_TOP-COURT_TOP,5.6),pedestalPosition(floor,slot),PALETTES.CRYPT.stone,Enum.Material.Slate,
				{transparency=1,canCollide=false,castShadow=false})
			marker:SetAttribute("LogicalPedestalId",string.format("floor%d-slot%d",floor,slot))
			marker:SetAttribute("PedestalBaseId",base.Name)
			marker:SetAttribute("FloorIndex",floor)
			marker:SetAttribute("SlotIndex",slot)
			marker:SetAttribute("PedestalActive",false)
			if floor==1 and slot<=5 then marker:SetAttribute("LegacySlotIndex",slot) end
		end
	end
	local altar=part(base,frame,"RestorationAltar",Vector3.new(1,1,1),Vector3.new(-10,3,-27),PALETTES.CRYPT.glow,Enum.Material.SmoothPlastic,
		{transparency=1,canCollide=false,canQuery=false,castShadow=false})
	altar:SetAttribute("Purpose","RestorationInteraction")
	local gate=part(base,frame,"SealBarrier",Vector3.new(24,21,0.8),Vector3.new(0,COURT_TOP+10.5,-34),PALETTES.CRYPT.glow,Enum.Material.ForceField,
		{transparency=1,canCollide=false,castShadow=false})
	gate:SetAttribute("RestorationSealBarrier",true)
	gate:SetAttribute("Purpose","ServerControlledSanctuarySeal")
	local rituals=P.folder(base,"RitualMarkers")
	for index,position in ipairs({Vector3.new(-7.5,COURT_TOP+0.1,-8),Vector3.new(7.5,COURT_TOP+0.1,-8),Vector3.new(0,COURT_TOP+0.1,13)}) do
		local marker=part(rituals,frame,"RitualMark_"..index,Vector3.new(3.8,0.2,3.8),position,PALETTES.CRYPT.glow,Enum.Material.SmoothPlastic,
			{transparency=1,canCollide=false,canQuery=false,castShadow=false})
		marker:SetAttribute("RitualIndex",index)
	end
	local recovery=P.folder(base,"RecoveryBays")
	for index=1,6 do
		local position=Vector3.new(index%2==1 and -8 or 8,COURT_TOP,-15+math.floor((index-1)/2)*20)
		local marker=part(recovery,frame,"RecoveryBay_"..index,Vector3.new(1,0.1,1),position,PALETTES.CRYPT.glow,Enum.Material.SmoothPlastic,
			{transparency=1,canCollide=false,canQuery=false,castShadow=false})
		marker:SetAttribute("RecoveryBayIndex",index)
	end
end

local function floorArt(decor,frame,floor,count,palette,level)
	if count==0 then return end
	local top=COURT_TOP+(floor-1)*FLOOR_RISE
	-- The first gallery extends past its stair landing: a carrier can turn from
	-- the 18-wide landing into the hall without squeezing against the rear rail.
	local rear=if count<=6 then 36 else (if count<=8 then 50 else 66)
	local thickness=if floor==1 then COURT_TOP-FLOOR_TOP else 0.9
	local slab=part(decor,frame,floor==1 and "TerraceCollision" or "GalleryFloor_"..floor,Vector3.new(66,thickness,rear+32),
		Vector3.new(0,top-thickness/2,(rear-32)/2),level==0 and palette.dark or palette.floor,palette.material)
	slab:SetAttribute("SanctuaryFloorIndex",floor)
	for _,side in ipairs({-1,1}) do
		soft(decor,frame,"GalleryEdge_"..floor.."_"..side,Vector3.new(0.45,0.14,rear+32),Vector3.new(side*32.7,top+0.07,(rear-32)/2),palette.trim,Enum.Material.SmoothPlastic)
	end
	-- The collection slab expands with progression, while circulation reaches
	-- the shell from the beginning. Only the incoming stair keeps an opening.
	local function fill(name,x,z,w,d)
		if d<=0 then return end
		local p=part(decor,frame,name,Vector3.new(w,thickness,d),Vector3.new(x,top-thickness/2,z),palette.floor,palette.material)
		p:SetAttribute("SanctuaryFloorIndex",floor)
	end
	fill("FloorFrontClosure_"..floor,0,-32.75,66,1.5)
	fill("FloorRearClosure_"..floor,0,(rear+67)/2,66,67-rear)
	for _,side in {-1,1} do
		local incoming= floor>1 and side==(if floor==2 then -1 else 1)
		if incoming then
			fill("FloorStairApron_"..floor,side*42,-26.75,18,13.5)
			fill("FloorLandingClosure_"..floor,side*42,53.5,18,27)
			-- The existing landing occupies z=24..40, exactly meeting this floor.
			local glass=part(decor,frame,"StairOpeningGlass_"..floor,Vector3.new(.18,3.1,44),Vector3.new(side*32.7,top+1.8,2),palette.window,Enum.Material.Glass,
				{transparency=.35,castShadow=false})
			for _,y in {.3,3.5} do soft(decor,frame,"StairOpeningFrame_"..floor.."_"..y,Vector3.new(.5,.35,44),Vector3.new(side*32.7,top+y,2),palette.trim,Enum.Material.Metal) end
			soft(decor,frame,"GalleryFascia_"..floor,Vector3.new(.55,1.1,44),Vector3.new(side*32.7,top-.45,2),palette.stone,palette.material)
			part(decor,frame,"StairApronGuard_"..floor,Vector3.new(18,3.5,.3),Vector3.new(side*42,top+1.75,-20.15),palette.trim,palette.material)
		else
			fill("FloorSideClosure_"..floor.."_"..side,side*42,16.75,18,100.5)
		end
		if level>=3 then
			soft(decor,frame,"InteriorSkirting_"..floor.."_"..side,Vector3.new(.35,1.1,100),Vector3.new(side*50.7,top+.55,16),palette.trim,palette.material)
		end
	end
	if level>=3 then soft(decor,frame,"RearSkirting_"..floor,Vector3.new(101,1.1,.35),Vector3.new(0,top+.55,66.7),palette.trim,palette.material) end
end

local function stair(decor,frame,floor,side,palette)
	local lower=COURT_TOP+(floor-1)*FLOOR_RISE
	local run,width,thickness,zStart=44,18,0.6,-20
	local angle=math.atan(FLOOR_RISE/run)
	-- x=42 puts the inner edge at the 33-stud hall edge and the outer edge
	-- exactly at the perimeter wall's inner face (51): 18 usable studs.
	local x=side*42
	local ramp=P.part(decor,"WideStairCollision_"..floor,Vector3.new(width,thickness,math.sqrt(run*run+FLOOR_RISE*FLOOR_RISE)),
		frame*CFrame.new(x,lower+FLOOR_RISE/2-math.cos(angle)*thickness/2,zStart+run/2+math.sin(angle)*thickness/2)
			*CFrame.Angles(-angle,0,0),palette.dark,palette.material)
	ramp:SetAttribute("RestorationArchitecture",true)
	ramp:SetAttribute("StairFloorFrom",floor)
	ramp:SetAttribute("StairFloorTo",floor+1)
	ramp:SetAttribute("StairClearWidth",width)
	-- Gameplay support only. Rendering this slope through the visible treads
	-- produced alternating dark triangles as the camera crossed their planes.
	ramp.Transparency=1
	for tread=1,24 do
		local z=zStart+(tread-0.5)*run/24
		local top=lower+tread*FLOOR_RISE/24
		soft(decor,frame,"StairTread_"..floor.."_"..tread,Vector3.new(width,FLOOR_RISE/24,run/24-.012),
			Vector3.new(x,top-FLOOR_RISE/48,z),tread%4==0 and palette.trim or palette.stone,palette.material)
	end
	part(decor,frame,"StairUpperLanding_"..floor,Vector3.new(width,0.9,16),Vector3.new(x,lower+FLOOR_RISE-0.45,32),palette.floor,palette.material)
	for _,edge in ipairs({-1,1}) do
		local rail=P.beam(decor,"StairHandrail_"..floor.."_"..edge,
			frame:PointToWorldSpace(Vector3.new(x+edge*8.95,lower+3.8,zStart)),
			frame:PointToWorldSpace(Vector3.new(x+edge*8.95,lower+FLOOR_RISE+3.8,zStart+run)),
			0.42,palette.trim,Enum.Material.Metal,{canCollide=false,canQuery=false,castShadow=false})
		rail:SetAttribute("RestorationArchitecture",true)
		softBeam(decor,frame,"StairStringer_"..floor.."_"..edge,
            Vector3.new(x+edge*9.35,lower-.3,zStart),Vector3.new(x+edge*9.35,lower+FLOOR_RISE-.3,zStart+run),.65,palette.stone,palette.material)
		for i=0,3 do
			local z=zStart+run*i/3
			soft(decor,frame,"StairBaluster_"..floor.."_"..edge.."_"..i,Vector3.new(.45,3.8,.45),
				Vector3.new(x+edge*8.95,lower+FLOOR_RISE*i/3+1.9,z),palette.trim,Enum.Material.Metal)
		end
	end
end

-- The shell is opaque. Presentation never changes globally with camera position.
local function enclosure(decor,frame,level,floors,palette)
 local height=if level>=3 then floors*FLOOR_RISE+0.35 else 2.6
 for _,side in {-1,1} do
  part(decor,frame,"SanctuarySideWall_"..side,Vector3.new(1,height,103),Vector3.new(side*51.5,FLOOR_TOP+height/2,CENTER_Z),palette.stone,palette.material)
  part(decor,frame,"SanctuaryFrontWall_"..side,Vector3.new(39.5,height,1),Vector3.new(side*31.75,FLOOR_TOP+height/2,-34),palette.stone,palette.material)
 end
 part(decor,frame,"SanctuaryRearWall",Vector3.new(103,height,1),Vector3.new(0,FLOOR_TOP+height/2,67.5),palette.stone,palette.material)
 for _,side in {-1,1} do
  for _,z in {-33.5,15,67} do
   soft(decor,frame,"PerimeterPilaster_"..side.."_"..z,Vector3.new(1.5,height+0.8,1.5),Vector3.new(side*50.75,FLOOR_TOP+(height+0.8)/2,z),palette.trim,palette.material)
  end
 end
 local doorway=AssetKit.placeGrounded(decor,"SanctuaryGateway","final_gothic_doorway",Vector3.new(34,23,3),frame*CFrame.new(0,FLOOR_TOP,-34),palette.trim,palette.material,{collision="none",groundInset=0})
 if doorway then doorway:SetAttribute("RestorationArchitecture",true) end
 for _,side in {-1,1} do
  part(decor,frame,"EntrancePier_"..side,Vector3.new(3,21,3),Vector3.new(side*13.5,COURT_TOP+10.5,-34),palette.stone,palette.material)
 end
 if not doorway then soft(decor,frame,"EntranceLintel",Vector3.new(30,2,3),Vector3.new(0,COURT_TOP+21,-34),palette.trim,palette.material) end
 if level>=3 then
  local top=FLOOR_TOP+height
  local lintelBottom=COURT_TOP+21
  part(decor,frame,"CentralFacadeWall",Vector3.new(24,top-lintelBottom,1),Vector3.new(0,(top+lintelBottom)/2,-34),palette.stone,palette.material)
  -- Solid ceiling and two closed triangular prisms: no open gable ends or
  -- uncovered strips, even when the gallery depth has not yet expanded.
  part(decor,frame,"CompleteRoofCeiling",Vector3.new(104,1,104),Vector3.new(0,top+0.5,16),palette.dark,palette.material)
  for _,side in {-1,1} do
   local wedge=part(decor,frame,"CompleteRoofSlope_"..side,Vector3.new(104,14,52),Vector3.new(side*26,top+8,16),palette.dark,palette.material,{className="WedgePart"})
   wedge.CFrame*=CFrame.Angles(0,-side*math.pi/2,0)
   soft(decor,frame,"RoofEave_"..side,Vector3.new(1.4,1.2,103),Vector3.new(side*51,top+0.4,16),palette.trim,palette.material)
  end
  soft(decor,frame,"RoofRidge",Vector3.new(1.3,1.1,103),Vector3.new(0,top+15,16),palette.trim,palette.material)
  for _,z in {-35.1,67.1} do
   for _,side in {-1,1} do
    softBeam(decor,frame,"GableRakingTrim_"..z.."_"..side,Vector3.new(side*51,top+1,z),Vector3.new(0,top+15,z),0.8,palette.trim,palette.material)
   end
  end
 end
end

-- All facade work is ornament on the exterior of the unchanged structural
-- walls. These modules never add collision, query surfaces, lights or openings.
local function facadeWindow(decor,frame,name,x,y,width,palette,style)
	local window=P.model(decor,name)
	window:SetAttribute("RestorationArchitecture",true)
	local height=14.2
	local at=frame*CFrame.new(x,y,-35.05)
	local material=if style=="FOREST" then Enum.Material.Wood else palette.material
	local outline=if style=="FOREST" then palette.trim else palette.trim:Lerp(palette.stone,0.2)
	local mesh=AssetKit.place(window,"LancetFrame","final_gothic_window",Vector3.new(width,height,0.9),at,outline,material,
		{collision="none",castShadow=false})
	if mesh then mesh:SetAttribute("RestorationArchitecture",true)
	else
		for _,side in ipairs({-1,1}) do
			soft(window,frame,"Jamb_"..side,Vector3.new(0.6,10.2,0.6),Vector3.new(x+side*width*0.42,y-1.5,-35.05),outline,material)
			softBeam(window,frame,"Arch_"..side,Vector3.new(x+side*width*0.42,y+3.6,-35.05),Vector3.new(x,y+6.8,-35.05),0.6,outline,material)
		end
		soft(window,frame,"Sill",Vector3.new(width,0.6,0.8),Vector3.new(x,y-6.8,-35.05),outline,material)
	end
	local glass=if style=="CRYPT" then Color3.fromRGB(120,115,95)
		else (if style=="FOREST" then Color3.fromRGB(68,111,83) else Color3.fromRGB(76,119,158))
	-- The curved cap fills the actual pointed opening. It is behind the native
	-- moulding and slightly proud of the lower pane, avoiding coincident faces.
	soft(window,frame,"LowerPane",Vector3.new(width*0.71,height*0.65,0.12),Vector3.new(x,y-1.7,-34.78),glass,Enum.Material.SmoothPlastic)
	reliefOval(window,frame,"LancetPane",Vector3.new(x,y+2.05,-34.88),Vector3.new(width*0.71,height*0.49,0.13),glass)
	soft(window,frame,"CentralMullion",Vector3.new(0.23,10.6,0.18),Vector3.new(x,y-0.7,-35.59),palette.dark,
		if style=="FOREST" then Enum.Material.Wood else Enum.Material.Metal)
end

local function ancestorRelief(decor,frame,name,center,diameter,palette)
	local group=P.model(decor,name)
	local s=diameter/5.2
	reliefDisk(group,frame,"IronSeal",center,diameter,0.18,palette.dark,Enum.Material.Metal)
	reliefOval(group,frame,"CarvedSkull",center+Vector3.new(0,0.3*s,-0.23),Vector3.new(2.9*s,2.8*s,0.25),palette.trim)
	soft(group,frame,"Jaw",Vector3.new(1.75*s,0.7*s,0.22),center+Vector3.new(0,-1.35*s,-0.24),palette.trim,Enum.Material.Slate)
	for _,side in ipairs({-1,1}) do
		reliefOval(group,frame,"EyeSocket_"..side,center+Vector3.new(side*0.63*s,0.38*s,-0.39),Vector3.new(0.7*s,0.83*s,0.10),palette.dark,side*0.18)
	end
	reliefOval(group,frame,"Nose",center+Vector3.new(0,-0.48*s,-0.4),Vector3.new(0.38*s,0.56*s,0.1),palette.dark)
end

local function astralRelief(decor,frame,name,center,diameter,palette)
	local group=P.model(decor,name)
	reliefDisk(group,frame,"BrassOrbit",center,diameter,0.16,Color3.fromRGB(144,132,96),Enum.Material.Metal)
	reliefDisk(group,frame,"NightDisk",center+Vector3.new(0,0,-0.16),diameter*0.82,0.10,palette.dark,Enum.Material.SmoothPlastic)
	for _,side in ipairs({-1,1}) do
		softBeam(group,frame,"StarRay_"..side,center+Vector3.new(-diameter*0.27,side*diameter*0.27,-0.3),
			center+Vector3.new(diameter*0.27,-side*diameter*0.27,-0.3),diameter*0.045,palette.glow,Enum.Material.SmoothPlastic)
	end
end

local function treeRelief(decor,frame,name,center,diameter,palette)
	local group=P.model(decor,name)
	local s=diameter/5.5
	reliefDisk(group,frame,"CarvedWoodSeal",center,diameter,0.18,palette.dark,Enum.Material.Wood)
	softBeam(group,frame,"LivingTrunk",center+Vector3.new(0,-2.1*s,-0.25),center+Vector3.new(0,1.2*s,-0.25),0.45*s,palette.trim,Enum.Material.Wood)
	for _,side in ipairs({-1,1}) do
		softBeam(group,frame,"Branch_"..side,center+Vector3.new(0,-0.1*s,-0.25),center+Vector3.new(side*1.8*s,1.2*s,-0.25),0.33*s,palette.trim,Enum.Material.Wood)
		reliefOval(group,frame,"Leaf_"..side,center+Vector3.new(side*1.65*s,1.45*s,-0.32),Vector3.new(1.35*s,0.75*s,0.18),palette.glow,side*0.55)
	end
	reliefOval(group,frame,"CrownLeaf",center+Vector3.new(0,1.9*s,-0.32),Vector3.new(0.9*s,1.3*s,0.18),palette.glow)
end

-- Shallow sphere parts do not produce readable carvings in the native game.
-- These interior emblems use planar blocks and beams with visible depth.
local function interiorCrest(decor,frame,name,center,diameter,palette,style)
 if style=="OBSERVATORY" then astralRelief(decor,frame,name,center,diameter,palette);return end
 local group=P.model(decor,name);local s=diameter/8
 reliefDisk(group,frame,"CrestBacking",center,diameter,.2,palette.dark,palette.material)
 local function block(n,size,p,c)
  soft(group,frame,n,size*s,center+Vector3.new(p.X*s,p.Y*s,p.Z),c,palette.material)
 end
 if style=="CRYPT" then
  block("CarvedHead",Vector3.new(3.8,4,.4),Vector3.new(0,.6,-.35),palette.trim)
  block("CarvedJaw",Vector3.new(2.8,1,.35),Vector3.new(0,-1.8,-.4),palette.trim)
  for _,side in {-1,1} do
   block("Eye_"..side,Vector3.new(.85,1.15,.15),Vector3.new(side*.95,.6,-.7),palette.dark)
  end
  block("Nose",Vector3.new(.55,.75,.15),Vector3.new(0,-.6,-.7),palette.dark)
  for i=-1,1 do block("Tooth_"..i,Vector3.new(.18,.5,.15),Vector3.new(i*.7,-1.9,-.7),palette.dark) end
 else
  softBeam(group,frame,"LivingTrunk",center+Vector3.new(0,-2.8*s,-.4),center+Vector3.new(0,2*s,-.4),.55*s,palette.trim,Enum.Material.Wood)
  for _,side in {-1,1} do
   softBeam(group,frame,"Branch_"..side,center+Vector3.new(0,-.2*s,-.4),center+Vector3.new(side*2.2*s,1.6*s,-.4),.4*s,palette.trim,Enum.Material.Wood)
   local leaf=center+Vector3.new(side*2*s,1.8*s,-.55)
   for i,p in {Vector3.new(0,1,0),Vector3.new(.7,0,0),Vector3.new(0,-1,0),Vector3.new(-.7,0,0)} do
    local nextPoint=({Vector3.new(.7,0,0),Vector3.new(0,-1,0),Vector3.new(-.7,0,0),Vector3.new(0,1,0)})[i]
    softBeam(group,frame,"LeafEdge_"..side.."_"..i,leaf+p*s,leaf+nextPoint*s,.3*s,palette.glow,Enum.Material.Wood)
   end
  end
 end
end

local function facadeDetails(decor,frame,level,floors,palette,style)
	if level<1 then return end
	for _,side in ipairs({-1,1}) do
		soft(decor,frame,"FacadePlinth_"..side,Vector3.new(38.3,0.85,0.85),Vector3.new(side*31.75,1.45,-35.03),palette.dark,palette.material)
	end
	local height=if level>=3 then floors*FLOOR_RISE-1.6 else 4.2
	for _,side in ipairs({-1,1}) do
		for index,x in ipairs({15.7,48.9}) do
			local ornament=AssetKit.placeGrounded(decor,"FacadeButtress_"..side.."_"..index,"final_buttress",Vector3.new(3.1,height,1.05),
				frame*CFrame.new(side*x,FLOOR_TOP,-35.05),palette.trim,palette.material,{collision="none",groundInset=0,castShadow=false})
			if ornament then ornament:SetAttribute("RestorationArchitecture",true)
			else soft(decor,frame,"FacadePier_"..side.."_"..index,Vector3.new(1.3,height,0.8),
				Vector3.new(side*x,FLOOR_TOP+height/2,-35.05),palette.trim,palette.material) end
		end
	end
	if level<3 then return end
	for floor=1,floors do
		local bottom=COURT_TOP+(floor-1)*FLOOR_RISE
		for _,side in ipairs({-1,1}) do
			for index,x in ipairs({22.2,41.4}) do
				facadeWindow(decor,frame,"FacadeWindow_"..floor.."_"..side.."_"..index,side*x,bottom+12.4,6.7,palette,style)
			end
			soft(decor,frame,"FloorCornice_"..floor.."_"..side,Vector3.new(38.2,0.75,0.75),
				Vector3.new(side*31.75,bottom+20.8,-35.12),palette.trim,palette.material)
			if style=="FOREST" then
				-- Branches grow in the clear wall bay between the two lancets.
				local rootAt=Vector3.new(side*31.75,bottom+2.2,-35.5)
				softBeam(decor,frame,"FacadeLivingTrunk_"..floor.."_"..side,rootAt,rootAt+Vector3.new(side*0.8,16,0),0.68,palette.dark,Enum.Material.Wood)
				for _,branch in ipairs({-1,1}) do
					softBeam(decor,frame,"FacadeLivingBranch_"..floor.."_"..side.."_"..branch,
						rootAt+Vector3.new(side*0.4,9,0),rootAt+Vector3.new(branch*3.3,14,0),0.45,palette.trim,Enum.Material.Wood)
				end
				reliefOval(decor,frame,"FacadeLeaf_"..floor.."_"..side,rootAt+Vector3.new(side*2.8,15.2,-0.06),
					Vector3.new(2.5,1.25,0.16),palette.window,side*0.6)
			elseif style=="OBSERVATORY" then
				astralRelief(decor,frame,"FacadeAstralClock_"..floor.."_"..side,Vector3.new(side*31.75,bottom+12.4,-35.13),5.2,palette)
			end
		end
		if floor>1 then
			-- A wider central lancet joins the wings above the actual ground-level
			-- entrance. Its thin ornament remains entirely outside the hall.
			facadeWindow(decor,frame,"EntranceGalleryWindow_"..floor,0,bottom+12.4,11.2,palette,style)
		end
	end

end

local function styleDetails(decor,frame,level,floors,palette,style)
	soft(decor,frame,"AltarFoot",Vector3.new(6.4,0.5,4.6),Vector3.new(-10,COURT_TOP+0.25,-27),palette.dark,palette.material)
	part(decor,frame,"AltarBody",Vector3.new(4.8,2,3.6),Vector3.new(-10,COURT_TOP+1.5,-27),palette.stone,palette.material)
	soft(decor,frame,"AltarSeal",Vector3.new(3.8,0.1,2.8),Vector3.new(-10,COURT_TOP+2.55,-27),palette.trim,Enum.Material.SmoothPlastic)
	for _,side in ipairs({-1,1}) do
		local fixture=soft(decor,frame,"EntryLantern_"..side,Vector3.new(1,1.5,1),Vector3.new(side*15.5,8,-32),palette.glow,Enum.Material.Neon)
		P.light(fixture,palette.glow,20,0.55)
		local housing=AssetKit.place(decor,"EntryLanternHousing_"..side,"final_lantern",Vector3.new(1.8,2.5,1.8),
			frame*CFrame.new(side*15.5,8,-32),palette.dark,if style=="FOREST" then Enum.Material.Wood else Enum.Material.Metal,
			{collision="none",castShadow=false})
		if housing then housing:SetAttribute("RestorationArchitecture",true) end
	end
	if level>=1 then
		for index,point in ipairs({Vector3.new(-7.5,COURT_TOP+0.11,-8),Vector3.new(7.5,COURT_TOP+0.11,-8),Vector3.new(0,COURT_TOP+0.11,13)}) do
			local ring=P.part(decor,"RitualSealArtwork_"..index,Vector3.new(0.055,3.8,3.8),frame*CFrame.new(point)*CFrame.Angles(0,0,math.pi/2),
				palette.glow,Enum.Material.SmoothPlastic,{shape=Enum.PartType.Cylinder,canCollide=false,canQuery=false,castShadow=false})
			ring:SetAttribute("RestorationArchitecture",true)
		end
	end
	if style=="CRYPT" then
		for _,side in ipairs({-1,1}) do
			ancestorRelief(decor,frame,"AncestorPlaque_"..side,
				Vector3.new(side*(if level>=3 then 31.75 else 15.5),if level>=3 then COURT_TOP+12.4 else 13,-35.15),
				if level>=3 then 5.2 else 3.2,palette)
			soft(decor,frame,"CandleCluster_"..side,Vector3.new(0.45,2.2,0.45),Vector3.new(side*16,COURT_TOP+1.1,-27),palette.trim,Enum.Material.SmoothPlastic)
			reliefOval(decor,frame,"CandleFlame_"..side,Vector3.new(side*16,COURT_TOP+2.5,-27),Vector3.new(0.3,0.7,0.3),palette.glow)
		end
	elseif style=="FOREST" then
		for _,side in ipairs({-1,1}) do
			local root=AssetKit.placeGrounded(decor,"GuardianRoots_"..side,"root_serpent",Vector3.new(11,3.4,6),
				frame*CFrame.new(side*30,FLOOR_TOP,-28)*CFrame.Angles(0,side*0.65,0),palette.dark,Enum.Material.Wood,{collision="none"})
			if root then root:SetAttribute("RestorationArchitecture",true) end
			softBeam(decor,frame,"TimberCrown_"..side,Vector3.new(side*14,20,-34.8),Vector3.new(0,24,-34.8),0.7,palette.trim,Enum.Material.Wood)
		end
	else
		for _,side in ipairs({-1,1}) do
			softBeam(decor,frame,"AstralEmblem_"..side,Vector3.new(side*2.6,20.4,-35.7),Vector3.new(-side*2.6,23.6,-35.7),0.2,palette.glow,Enum.Material.Neon)
		end
	end
	if level>=6 then
		local seal=Vector3.new(0,22.2,-35.16)
		reliefDisk(decor,frame,"ProtectiveSealEmblem",seal,2.7,0.12,palette.dark,Enum.Material.Metal)
		for _,side in ipairs({-1,1}) do
			softBeam(decor,frame,"ProtectiveSealWard_"..side,seal+Vector3.new(side*0.7,-0.4,-0.15),
				seal+Vector3.new(0,0.85,-0.15),0.21,palette.glow,Enum.Material.SmoothPlastic)
		end
	end
	if level>=9 then soft(decor,frame,"ConsecratedCornice",Vector3.new(101,0.7,1.4),Vector3.new(0,FLOOR_TOP+floors*FLOOR_RISE,-34.5),palette.trim,palette.material) end
	if level>=10 then
		local crest=Vector3.new(0,FLOOR_TOP+floors*FLOOR_RISE+2.2,-35.15)
		if style=="CRYPT" then ancestorRelief(decor,frame,"DomainCrest",crest,5.5,palette)
		elseif style=="FOREST" then treeRelief(decor,frame,"DomainCrest",crest,5.5,palette)
		else astralRelief(decor,frame,"DomainCrest",crest,5.5,palette) end
	end
end

-- Large, legible milestones. These additions remain outside circulation,
-- recovery bays, collection bounds and the existing stair collision planes.
local function completedPresentation(decor,frame,level,floors,palette,style)
 local top=COURT_TOP+floors*22
 for _,side in {-1,1} do
  soft(decor,frame,"CourtyardCoping_"..side,Vector3.new(1.8,0.4,101),Vector3.new(side*50.9,3.6,16),palette.trim,palette.material)
 end
 if level>=1 then
  for _,side in {-1,1} do
   soft(decor,frame,"ProcessionalInlay_"..side,Vector3.new(.25,.035,59),Vector3.new(side*12,COURT_TOP+.018,2),palette.trim,Enum.Material.SmoothPlastic)
   soft(decor,frame,"EntryObelisk_"..side,Vector3.new(3,11,3),Vector3.new(side*45,6.3,-32),palette.dark,palette.material)
   local crown=soft(decor,frame,"EntryObeliskCrown_"..side,Vector3.new(3.8,2,3.8),Vector3.new(side*45,12.5,-32),palette.trim,palette.material)
  end
 end
 if level==2 then
  for _,side in {-1,1} do
   -- Roofed side colonnades make the collection courtyard deliberately open.
   soft(decor,frame,"CourtyardArcadeRoof_"..side,Vector3.new(16,1.1,47),Vector3.new(side*42,18,39),palette.dark,palette.material)
   for _,z in {17,39,61} do
    soft(decor,frame,"CourtyardArcadeColumn_"..side.."_"..z,Vector3.new(1.2,16,1.2),Vector3.new(side*35,9,z),palette.trim,palette.material)
   end
  end
 end
 if level<3 then return end
 for floor=1,floors do
  local bottom=COURT_TOP+(floor-1)*22
  for _,side in {-1,1} do
   -- Reuse the actual framed lancet on both exterior sides. The recessed
   -- tinted panels are intentionally opaque; the wall remains solid behind.
   local wallFrame=frame*CFrame.new(side*17.3,0,16)*CFrame.Angles(0,-side*math.pi/2,0)
   for i,x in {-29,10,39} do
    facadeWindow(decor,wallFrame,"SideLancet_"..floor.."_"..side.."_"..i,x,bottom+12.4,6.7,palette,style)
   end
   soft(decor,frame,"SideStringCourse_"..floor.."_"..side,Vector3.new(1.1,.6,100),Vector3.new(side*50.9,bottom+20.8,16),palette.trim,palette.material)
   local light=soft(decor,frame,"GallerySconce_"..floor.."_"..side,Vector3.new(.5,2,1.8),Vector3.new(side*50.4,bottom+12,16),palette.glow,Enum.Material.Neon)
   P.light(light,palette.glow,60,.65)
   soft(decor,frame,"SconceBackplate_"..floor.."_"..side,Vector3.new(.35,3.2,2.6),Vector3.new(side*50.8,bottom+12,16),palette.dark,Enum.Material.Metal)
   soft(decor,frame,"InteriorFrieze_"..floor.."_"..side,Vector3.new(.2,.5,99),Vector3.new(side*50.9,bottom+17.7,16),palette.trim,palette.material)
  end
  local rearFrame=frame*CFrame.new(0,0,33.3)*CFrame.Angles(0,math.pi,0)
  for _,x in {-31,0,31} do facadeWindow(decor,rearFrame,"RearLancet_"..floor.."_"..x,x,bottom+12.4,7.5,palette,style) end
  -- Interior niches flank the rear aisle and remain behind the last plinths.
  for _,x in {-23,23} do
   soft(decor,frame,"RearInteriorPanel_"..floor.."_"..x,Vector3.new(9,12,.15),Vector3.new(x,bottom+10,66.91),palette.dark,palette.material)
   soft(decor,frame,"RearInteriorCrown_"..floor.."_"..x,Vector3.new(10,.6,.3),Vector3.new(x,bottom+16.1,66.75),palette.trim,palette.material)
   soft(decor,frame,"RearInteriorSill_"..floor.."_"..x,Vector3.new(10,.6,.4),Vector3.new(x,bottom+3.9,66.7),palette.trim,palette.material)
   for _,side in {-1,1} do
    soft(decor,frame,"RearInteriorJamb_"..floor.."_"..x.."_"..side,Vector3.new(.55,12,.4),Vector3.new(x+side*4.8,bottom+10,66.7),palette.trim,palette.material)
   end
  end
  -- Large, light structural members frame the galleries without crossing
  -- collection or stair lanes. Lighting stays on the existing eight fixtures.
  for _,z in {-31,65.7} do
   soft(decor,frame,"InteriorCeilingRib_"..floor.."_"..z,Vector3.new(101,.7,1.2),Vector3.new(0,bottom+21.5,z),palette.trim,palette.material)
   if floor<floors then
    for _,side in {-1,1} do
     soft(decor,frame,"GallerySupport_"..floor.."_"..side.."_"..z,Vector3.new(1.1,21,1.1),Vector3.new(side*31.5,bottom+10.5,z),palette.trim,palette.material)
    end
   end
  end
 end
 if level>=5 then
  local center=Vector3.new(0,COURT_TOP+22+11,66.65)
  interiorCrest(decor,frame,"CollectionGalleryCrest",center,8,palette,style)
 end
 if level>=8 then
  local center=Vector3.new(0,COURT_TOP+44+11,66.65)
  interiorCrest(decor,frame,"RelicGalleryCrest",center,10,palette,style)
 end
 if level>=5 then
  for _,side in {-1,1} do
   for _,z in {-32,64} do
    soft(decor,frame,"RoofPinnacle_"..side.."_"..z,Vector3.new(3,8,3),Vector3.new(side*48,top+4,z),palette.stone,palette.material)
    local crown=part(decor,frame,"PinnacleCap_"..side.."_"..z,Vector3.new(3.8,5,3.8),Vector3.new(side*48,top+10.5,z),palette.dark,palette.material,{className="WedgePart",canCollide=false,canQuery=false})
   end
  end
 end
 if level>=6 then
  -- A broad stone portal surrounds, but does not reduce, the 24 x 21 entry.
  for _,side in {-1,1} do
   soft(decor,frame,"WardPortalPier_"..side,Vector3.new(4,24,1),Vector3.new(side*17,12.8,-35.4),palette.dark,palette.material)
   soft(decor,frame,"WardPortalRune_"..side,Vector3.new(.4,17,.15),Vector3.new(side*17,12,-35.86),palette.glow,Enum.Material.SmoothPlastic)
  end
  soft(decor,frame,"WardPortalLintel",Vector3.new(38,2,1),Vector3.new(0,25.2,-35.4),palette.trim,palette.material)
 end
 if level>=8 then
  -- A closed raised lantern changes the roof silhouette without opening it.
  soft(decor,frame,"RoofLanternBody",Vector3.new(14,8,38),Vector3.new(0,top+15,27),palette.stone,palette.material)
  soft(decor,frame,"RoofLanternCap",Vector3.new(17,1.5,41),Vector3.new(0,top+19.7,27),palette.dark,palette.material)
  for _,side in {-1,1} do
   for _,z in {14,27,40} do
    soft(decor,frame,"LanternPane_"..side.."_"..z,Vector3.new(.15,4,6),Vector3.new(side*7.1,top+15.5,z),palette.window,Enum.Material.SmoothPlastic)
   end
  end
 end
 if level>=9 then
  for _,side in {-1,1} do
   soft(decor,frame,"ConsecratedTower_"..side,Vector3.new(8,15,8),Vector3.new(side*44,top+7.5,-29),palette.stone,palette.material)
   for i=1,4 do soft(decor,frame,"TowerSpire_"..side.."_"..i,Vector3.new(10-i*2,2.4,10-i*2),Vector3.new(side*44,top+14+i*2.4,-29),palette.dark,palette.material) end
  end
 end
 if level>=10 then
  soft(decor,frame,"DominionBelfry",Vector3.new(18,20,18),Vector3.new(0,top+22,-23),palette.stone,palette.material)
  soft(decor,frame,"DominionBelfryInset",Vector3.new(10,12,.2),Vector3.new(0,top+23,-32.1),palette.dark,palette.material)
  for _,side in {-1,1} do soft(decor,frame,"BelfryMullion_"..side,Vector3.new(.6,12,.35),Vector3.new(side*3,top+23,-32.3),palette.trim,palette.material) end
  for i=1,5 do soft(decor,frame,"DominionSpire_"..i,Vector3.new(22-i*3.5,2.8,22-i*3.5),Vector3.new(0,top+31+i*2.8,-23),palette.dark,palette.material) end
  soft(decor,frame,"DominionFinial",Vector3.new(.65,6,.65),Vector3.new(0,top+48,-23),palette.trim,Enum.Material.Metal)
 end
end

local function pedestalArtwork(decor,frame,floor,slot,palette,featuredId)
	local position=pedestalPosition(floor,slot)
	local bottom=Vector3.new(position.X,COURT_TOP+(floor-1)*FLOOR_RISE,position.Z)
	local mesh=AssetKit.placeGrounded(decor,"PedestalArtwork_floor"..floor.."_slot"..slot,"final_collection_pedestal",
		Vector3.new(6.3,PLINTH_TOP-COURT_TOP,6.3),frame*CFrame.new(bottom),palette.stone,palette.material,{collision="none",groundInset=0})
	if mesh then mesh:SetAttribute("RestorationArchitecture",true)
	else soft(decor,frame,"PedestalCrown_floor"..floor.."_slot"..slot,Vector3.new(6.3,0.5,6.3),
		Vector3.new(position.X,PLINTH_TOP+(floor-1)*FLOOR_RISE-0.25,position.Z),palette.trim,palette.material) end
	if string.format("floor%d-slot%d",floor,slot)==featuredId then
		for _,side in ipairs({-1,1}) do
			soft(decor,frame,"FeaturedInlay_"..side,Vector3.new(0.3,0.08,6.6),
				Vector3.new(position.X+side*3.3,PLINTH_TOP+(floor-1)*FLOOR_RISE+0.08,position.Z),palette.glow,Enum.Material.Neon)
		end
	end
end

function Architecture.apply(base: Model,level: number,style: string,featuredPedestalId: string?)
	assert(SanctuaryConfig.Levels[level],"Invalid sanctuary restoration level")
	local palette=PALETTES[style]
	assert(palette,"Invalid sanctuary style")
	local frame=frameFor(base)
	local markers,active,count={},{},0
	for _,marker in ipairs(base:GetChildren()) do
		local id=marker:GetAttribute("LogicalPedestalId")
		if marker:IsA("BasePart") and typeof(id)=="string" then
			local enabled=marker:GetAttribute("SlotIndex")<=floorCapacity(level,marker:GetAttribute("FloorIndex"))
			assert(enabled or not marker:GetAttribute("OccupiedCurseUid"),"Cannot deactivate an occupied pedestal")
			markers[marker]=enabled
			if enabled then active[id]=marker; count+=1 end
		end
	end
	assert(count==capacity(level),"Sanctuary stable pedestal inventory is incomplete")
	-- No yields: both construction and the final swap are synchronous. A failed
	-- preparation destroys only the new off-tree model and preserves the old base.
	local decor=Instance.new("Model")
	decor.Name="RestorationDecor"
	local floors=if level>=7 then 3 else (if level>=4 then 2 else 1)
	local ok,err=pcall(function()
		for floor=1,floors do
			local slots=floorCapacity(level,floor)
			floorArt(decor,frame,floor,slots,palette,level)
			for slot=1,slots do pedestalArtwork(decor,frame,floor,slot,palette,featuredPedestalId) end
		end
		for floor=1,floors-1 do stair(decor,frame,floor,floor==1 and -1 or 1,palette) end
		enclosure(decor,frame,level,floors,palette)
		facadeDetails(decor,frame,level,floors,palette,style)
		styleDetails(decor,frame,level,floors,palette,style)
		completedPresentation(decor,frame,level,floors,palette,style)
	end)
	if not ok then decor:Destroy(); error(err) end
	local previous=base:FindFirstChild("RestorationDecor")
	decor.Parent=base
	for marker,enabled in pairs(markers) do
		marker:SetAttribute("PedestalId",if enabled then marker:GetAttribute("LogicalPedestalId") else nil)
		marker:SetAttribute("PedestalActive",enabled)
		marker:SetAttribute("FeaturedPedestal",enabled and marker:GetAttribute("LogicalPedestalId")==featuredPedestalId)
		marker.CanCollide=enabled
		marker.CanQuery=enabled
	end
	base.SanctuaryFloor.Color,base.SanctuaryFloor.Material=palette.dark,palette.material
	base.SealBarrier.Color=palette.glow
	base:SetAttribute("RestorationLevel",level)
	base:SetAttribute("SanctuaryStyle",style)
	base:SetAttribute("SanctuaryCapacity",capacity(level))
	base:SetAttribute("SanctuaryFloors",floors)
	base:SetAttribute("FeaturedPedestalId",if featuredPedestalId and active[featuredPedestalId] then featuredPedestalId else nil)
	base:SetAttribute("ArchitectureRevision",(base:GetAttribute("ArchitectureRevision") or 0)+1)
	base:SetAttribute("TerritoryWidth",WIDTH)
	base:SetAttribute("TerritoryDepth",DEPTH)
	base:SetAttribute("TerritoryCenterZ",CENTER_Z)
	base:SetAttribute("TerritoryMinZ",-36)
	base:SetAttribute("TerritoryMaxZ",68)
	base:SetAttribute("SanctuaryFrame",frame)
	base:SetAttribute("RestoreBoundaryExtents",Vector3.new(52,70,52))
	base:SetAttribute("RestoreBoundaryCenter",Vector3.new(0,35,16))
 base:SetAttribute("ArchitecturePartBudget",600)
	if previous then previous:Destroy() end
	local physicalParts=0
	for _,item in ipairs(base:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("RestorationArchitecture") then physicalParts+=1 end
	end
	base:SetAttribute("ArchitecturePartCount",physicalParts)
	return {pedestals=active,altar=base.RestorationAltar,gate=base.SealBarrier,ritualMarkers=base.RitualMarkers,
		recoveryBays=base.RecoveryBays,frame=frame,footprint=Architecture.Footprint,capacity=capacity(level)}
end

function Architecture.buildInitial(map: Model)
	local sanctuaries=P.model(map,"PlayerSanctuaries")
	for index=1,Config.BaseCount do
		local base=P.model(sanctuaries,string.format("Base%02d",index))
		base:SetAttribute("BaseIndex",index)
		base:SetAttribute("BaseId",base.Name)
		base:SetAttribute("TerritoryName",Config.BaseSites[index].territory)
		persistentMarkers(base,Config.baseFrame(index))
		Architecture.apply(base,0,"CRYPT",nil)
	end
	return sanctuaries
end
return Architecture
